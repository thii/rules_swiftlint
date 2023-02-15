load("@build_bazel_rules_swift//swift:swift.bzl", "SwiftInfo")

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
        validation_output = ctx.actions.declare_file(src.basename + ".validation")
        direct_validation_outputs.append(validation_output)

        args = ctx.actions.args()
        args.add(swiftlint_executable)
        args.add(validation_output)
        args.add("lint")

        args.add_all("--config", ctx.files._config)

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

    transitive_validation_outputs = [
        d[OutputGroupInfo]._validation
        for d in ctx.rule.attr.deps
    ]

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
