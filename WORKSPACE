load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "build_bazel_rules_apple",
    sha256 = "f94e6dddf74739ef5cb30f000e13a2a613f6ebfa5e63588305a71fce8a8a9911",
    url = "https://github.com/bazelbuild/rules_apple/releases/download/1.1.3/rules_apple.1.1.3.tar.gz",
)

load(
    "@build_bazel_rules_apple//apple:repositories.bzl",
    "apple_rules_dependencies",
)

apple_rules_dependencies()

load(
    "@build_bazel_rules_swift//swift:repositories.bzl",
    "swift_rules_dependencies",
)

swift_rules_dependencies()

load(
    "@build_bazel_rules_swift//swift:extras.bzl",
    "swift_rules_extra_dependencies",
)

swift_rules_extra_dependencies()

load(
    "@build_bazel_apple_support//lib:repositories.bzl",
    "apple_support_dependencies",
)

apple_support_dependencies()

load(
    "//swiftlint:repositories.bzl",
    "swiftlint_rules_dependencies",
)

swiftlint_rules_dependencies()

http_archive(
    name = "SwiftLint",
    build_file_content = """exports_files(["swiftlint"])""",
    sha256 = "47078845857fa7cf8497f5861967c7ce67f91915e073fb3d3114b8b2486a9270",
    url = "https://github.com/realm/SwiftLint/releases/download/0.50.3/portable_swiftlint.zip",
)

load(
    "//swiftlint:defs.bzl",
    "swiftlint_register_toolchains",
)

swiftlint_register_toolchains()

# For running our own unit tests
load("@bazel_skylib//:workspace.bzl", "bazel_skylib_workspace")

bazel_skylib_workspace()
