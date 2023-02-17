load("@bazel_skylib//lib:paths.bzl", "paths")
load("@build_bazel_rules_swift//swift:swift.bzl", "SwiftInfo")
load(":utils.bzl", "owner_relative_path")

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

def _find_formattable_srcs(target, aspect_ctx):
    """Parse a target for SwiftLint formattable sources.

    Args:
        target (Target): The target the aspect is running on.
        aspect_ctx (ctx, optional): The aspect's context object.

    Returns:
        list: A list of formattable sources (`File`).
    """
    if SwiftInfo not in target:
        return []

    # Ignore external targets
    # TODO: Support --experimental_sibling_repository_layout
    if target.label.workspace_root.startswith("external"):
        return []

    # Targets tagged to indicate "don't validate" will not be validated
    if aspect_ctx:
        for tag in ["no-validation", "no-lint", "no-swiftlint"]:
            if tag in aspect_ctx.rule.attr.tags:
                return []

    # Filter out any duplicate or generated files
    srcs = [
        src
        for src in aspect_ctx.rule.files.srcs
        if src.is_source and src.extension == "swift"
    ]

    return sorted(srcs)

def _swiftlint_aspect_impl(target, ctx):
    srcs = _find_formattable_srcs(target, ctx)

    # If there are no formattable sources, do nothing.
    if not srcs:
        return []

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
    for d in ctx.rule.attr.deps:
        if OutputGroupInfo not in d:
            continue
        if not hasattr(d[OutputGroupInfo], "_validation"):
            continue
        transitive_validation_outputs.append(d[OutputGroupInfo]._validation)

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
    attr_aspects = ["deps"],
    fragments = ["swift"],
    host_fragments = ["swift"],
    implementation = _swiftlint_aspect_impl,
    incompatible_use_toolchain_transition = True,
    toolchains = [
        str(Label("//swiftlint:toolchain_type")),
    ],
)
