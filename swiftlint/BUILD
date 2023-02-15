load("//swiftlint:defs.bzl", "swiftlint_toolchain")

exports_files([
    "default.swiftlint.yml",
    "defs.bzl",
])

# This is the target rule authors should put in their "toolchains"
# attribute in order to get a runtime for the correct platform.
# See https://docs.bazel.build/versions/main/toolchains.html#writing-rules-that-use-toolchains
toolchain_type(
    name = "toolchain_type",
    visibility = ["//visibility:public"],
)

swiftlint_toolchain(
    name = "default_swiftlint_toolchain",
    # Replace with `@SwiftLint//:universal_swiftlint` if you build it from
    # source and want to use a universal binary.
    swiftlint_executable = "@SwiftLint//:swiftlint",
)

toolchain(
    name = "swiftlint_toolchain",
    toolchain = "default_swiftlint_toolchain",
    toolchain_type = ":toolchain_type",
)

label_flag(
    name = "config",
    build_setting_default = "//swiftlint:default.swiftlint.yml",
    visibility = ["//visibility:public"],
)
