load("@bazel_skylib//lib:paths.bzl", "paths")
load(":utils.bzl", "owner_relative_path")

_ATTR_ASPECTS = [
    "_implicit_tests",
    "additional_contents",
    "app_clips",
    "bundles",
    "deps",
    "extension",
    "extensions",
    "frameworks",
    "settings_bundle",
    "srcs",
    "test_host",
    "tests",
    "watch_application",
]

def _collect_dependencies(rule_attr, attr_name):
    """Collects Bazel targets for a dependency attr.

    Args:
      rule_attr: The Bazel rule.attr whose dependencies should be collected.
      attr_name: attribute name to inspect for dependencies.

    Returns:
      A list of the Bazel target dependencies of the given rule.
    """
    return [
        dep
        for dep in _getattr_as_list(rule_attr, attr_name)
        if type(dep) == "Target" and
           (OutputGroupInfo in dep and hasattr(
               dep[OutputGroupInfo],
               "_validation",
           ))
    ]

def _declare_validation_output_file(actions, target_name, src):
    """Declares a file for a per-source SwiftLint validation output.

    Args:
        actions: The context's actions object.
        target_name: The name of the target being built.
        src: A `File` representing the source file being compiled.

    Returns:
        The declared `File`.
    """
    validation_output_dir = "{}_swiftlint".format(target_name)
    owner_rel_path = owner_relative_path(src)
    basename = paths.basename(owner_rel_path)
    dirname = paths.join(validation_output_dir, paths.dirname(owner_rel_path))

    return actions.declare_file(
        paths.join(dirname, "{}.validation".format(basename)),
    )

def _getattr_as_list(obj, attr_path):
    """Returns the value at attr_path as a list.

    This handles normalization of attributes containing a single value for use in
    methods expecting a list of values.

    Args:
      obj: The struct whose attributes should be parsed.
      attr_path: Dotted path of attributes whose value should be returned in
          list form.

    Returns:
      A list of values for obj at attr_path or [] if the struct has
      no such attribute.
    """
    val = _get_opt_attr(obj, attr_path)
    if not val:
        return []

    if type(val) == "list":
        return val
    elif type(val) == "dict":
        return val.keys()
    return [val]

def _get_opt_attr(obj, attr_path):
    """Returns the value at attr_path on the given object if it is set."""
    attr_path = attr_path.split(".")
    for a in attr_path:
        if not obj or not hasattr(obj, a):
            return None
        obj = getattr(obj, a)
    return obj

def _find_formattable_srcs(target, aspect_ctx):
    """Parse a target for SwiftLint formattable sources.

    Args:
        target (Target): The target the aspect is running on.
        aspect_ctx (ctx, optional): The aspect's context object.

    Returns:
        list: A list of formattable sources (`File`).
    """

    # Ignore external targets
    # TODO: Support --experimental_sibling_repository_layout
    if target.label.workspace_root.startswith("external"):
        return []

    # Targets tagged to indicate "don't validate" will not be validated
    if aspect_ctx:
        for tag in ["no-validation", "no-lint", "no-swiftlint"]:
            if tag in aspect_ctx.rule.attr.tags:
                return []

    # Filter out generated files and non-Swift files
    srcs = []
    if hasattr(aspect_ctx.rule.files, "srcs"):
        srcs.extend([
            src
            for src in aspect_ctx.rule.files.srcs
            if src.is_source and src.extension == "swift"
        ])

    return srcs

def _swiftlint_aspect_impl(target, ctx):
    srcs = _find_formattable_srcs(target, ctx)

    toolchain = ctx.toolchains[Label("//swiftlint:toolchain_type")]
    swiftlint_executable = toolchain.swiftlint_executable
    tools = [swiftlint_executable]

    direct_validation_outputs = []
    for src in srcs:
        validation_output = _declare_validation_output_file(
            actions = ctx.actions,
            target_name = target.label.name,
            src = src,
        )
        direct_validation_outputs.append(validation_output)

        args = ctx.actions.args()
        args.add(swiftlint_executable)
        args.add(validation_output)
        args.add("lint")

        args.add_all(ctx.files._config, before_each = "--config")

        # Avoid using SwiftLint's own caching mechanism to make the validation
        # action hermetic. The action is already cached by Bazel.
        args.add("--no-cache")

        # Don't print status logs like 'Linting <file>' & 'Done linting'.
        args.add("--quiet")
        args.add(src)

        ctx.actions.run(
            arguments = [args],
            executable = ctx.executable._swiftlint_wrapper,
            inputs = [src],
            mnemonic = "SwiftLint",
            outputs = [validation_output],
            progress_message = "Linting '{}'".format(src.path),
            tools = tools + ctx.files._config,
            use_default_shell_env = True,
        )

    transitive_validation_outputs = []
    for attr_name in _ATTR_ASPECTS:
        deps = _collect_dependencies(ctx.rule.attr, attr_name)
        for dep in deps:
            transitive_validation_outputs.append(dep[OutputGroupInfo]._validation)

    return [
        OutputGroupInfo(
            _validation = depset(
                direct = direct_validation_outputs,
                transitive = transitive_validation_outputs,
            ),
        ),
    ]

swiftlint_aspect = aspect(
    attrs = {
        "_swiftlint_wrapper": attr.label(
            default = Label("//tools:swiftlint_wrapper"),
            executable = True,
            cfg = "exec",
        ),
        "_config": attr.label(
            allow_files = True,
            default = Label("//swiftlint:config"),
            doc = """\
The filegroup represented one or more SwiftLint configuration files.""",
        ),
    },
    attr_aspects = _ATTR_ASPECTS,
    fragments = ["swift"],
    host_fragments = ["swift"],
    implementation = _swiftlint_aspect_impl,
    incompatible_use_toolchain_transition = True,
    toolchains = [
        str(Label("//swiftlint:toolchain_type")),
    ],
)
