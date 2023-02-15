"""Public API re-exports"""

load(
    "//swiftlint/private:aspects.bzl",
    _swiftlint_aspect = "swiftlint_aspect",
)
load(
    "//swiftlint/private:toolchain.bzl",
    _swiftlint_toolchain = "swiftlint_toolchain",
)
load(
    "//swiftlint/private:toolchains_auto_configuration.bzl",
    _swiftlint_register_toolchains = "swiftlint_register_toolchains",
)

swiftlint_aspect = _swiftlint_aspect
swiftlint_register_toolchains = _swiftlint_register_toolchains
swiftlint_toolchain = _swiftlint_toolchain
