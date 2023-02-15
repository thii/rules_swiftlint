def _swiftlint_toolchain_impl(ctx):
    swiftlint_executable = ctx.executable.swiftlint_executable

    tools = [swiftlint_executable]
    default_info = DefaultInfo(
        files = depset(tools),
        runfiles = ctx.runfiles(files = tools),
    )

    template_variables_info = platform_common.TemplateVariableInfo({
        "SWIFTLINT": swiftlint_executable.path,
    })

    toolchain_info = platform_common.ToolchainInfo(
        swiftlint_executable = swiftlint_executable,
    )

    return [
        default_info,
        template_variables_info,
        toolchain_info,
    ]

swiftlint_toolchain = rule(
    attrs = {
        "swiftlint_executable": attr.label(
            allow_single_file = True,
            cfg = "exec",
            doc = "A `swiftlint` binary",
            executable = True,
        ),
    },
    doc = "A toolchain providing binaries required for `swiftlint` rules.",
    implementation = _swiftlint_toolchain_impl,
    incompatible_use_toolchain_transition = True,
)
