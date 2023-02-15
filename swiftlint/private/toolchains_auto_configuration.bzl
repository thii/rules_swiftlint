def swiftlint_register_toolchains():
    # TODO: Conditionally register a toolchain based on the host platform
    native.register_toolchains("//swiftlint:swiftlint_toolchain")
