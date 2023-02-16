"""Provides a simple way to test your rules as an external workspace.
Add a basic smoke-test target below.
"""

load("@bazel_skylib//rules:build_test.bzl", "build_test")
load(
    "@build_bazel_rules_swift//swift:swift.bzl",
    "swift_binary",
    "swift_library",
)

filegroup(
    name = "swiftlint_config",
    srcs = [
        ".swiftlint.yml",
        ".swiftlint_child.yml",
    ],
)

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

build_test(
    name = "smoke_test",
    targets = [
        ":main",
    ],
)
