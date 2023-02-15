load(
    "@build_bazel_rules_swift//swift:swift.bzl",
    "swift_binary",
    "swift_library",
    "swift_test",
)

exports_files([
    "example.swiftlint.yml",
])

swift_library(
    name = "lib",
    srcs = ["lib.swift"],
    module_name = "Lib",
)

swift_binary(
    name = "main",
    srcs = ["main.swift"],
    deps = [":lib"],
)

swift_test(
    name = "test",
    srcs = ["tests.swift"],
    env = {
        "XCTEST_ENV_VAR": "TRUE",
        "XCTEST_BINDIR_ENV_VAR": "$(BINDIR)",
    },
)
