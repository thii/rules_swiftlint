# rules_swiftlint

Run SwiftLint in your Bazel build efficiently.

## Features

- Runs SwiftLint as part of the build/test. There is no need for a pre-build
  phase in your Xcode project anymore.
- Operates on a single Swift file at a time. This takes advantage of Bazel's
  powerful caching and paralleling mechanism and allows for incremental
  validation. You can even lint your Swift code with remote execution.
- Knows your dependency graph. The action won't run on your Swift file until
  you add it to your dependency tree.
- Simple integration. You just need to add a flag to your `.bazelrc` file and
  forget about it.

`rules_swiftlint` leverages Bazel's [Validation
Actions](https://bazel.build/extending/rules#validation_actions) to run
SwiftLint. This is special in that its outputs are always requested, regardless
of the value of the `--output_groups` flag; and the validation is skipped when
the target is depended upon as an implicit dependency, or as a tool, or is
build in the `exec` (or the legacy `host`) configuration---it only runs on code
that goes into your app. It is, however, possible to validate your Swift tools
by building or testing your tools directly.

Note that `rules_swiftlint` only validates, but does _not_ format your Swift
code, because source files are immutable to Bazel during a build or a test. If
your workflow requires you to auto-format your Swift code, you need to run
SwiftLint with `bazel run`:

```
bazel run @SwiftLint//:swiftlint -- [<SwiftLint flags>]
```

## Installation

1. WORKSPACE snippet

a. If you want to use a prebuilt binary of SwiftLint:

```starlark
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "SwiftLint",
    build_file_content = """exports_files(["swiftlint"])""",
    # Update these two lines whenever you want to update SwiftLint.
    sha256 = "47078845857fa7cf8497f5861967c7ce67f91915e073fb3d3114b8b2486a9270",
    url = "https://github.com/realm/SwiftLint/releases/download/0.50.3/portable_swiftlint.zip",
)

http_archive(
    name = "com_github_thii_rules_swiftlint",
    sha256 = "<update this>",
    url = "https://github.com/thii/rules_swiftlint/releases/download/0.0.1/rules_swiftlint.zip",
)

load(
    "@com_github_thii_rules_swiftlint//swiftlint:repositories.bzl",
    "swiftlint_rules_dependencies",
)

swiftlint_rules_dependencies()

load(
    "@com_github_thii_rules_swiftlint//swiftlint:defs.bzl",
    "swiftlint_register_toolchains",
)

swiftlint_register_toolchains()
```

b. If you want to build SwiftLint from source:

- Follow instructions from https://github.com/bazelbuild/rules_apple/releases
  to declare `rules_apple`'s dependencies.
- Follow instructions from https://github.com/realm/SwiftLint/releases to
  declare `SwiftLint`'s dependencies.
- Add the following to your WORKSPACE file:

```starlark
http_archive(
    name = "com_github_thii_rules_swiftlint",
    sha256 = "<update this>",
    url = "https://github.com/thii/rules_swiftlint/releases/download/0.0.1/rules_swiftlint.zip",
)

load(
    "@com_github_thii_rules_swiftlint//swiftlint:repositories.bzl",
    "swiftlint_rules_dependencies",
)

swiftlint_rules_dependencies()

load(
    "@com_github_thii_rules_swiftlint//swiftlint:defs.bzl",
    "swiftlint_register_toolchains",
)

swiftlint_register_toolchains()
```

2. Declare a target for your SwiftLint configuration files

This is optional if you don't have your own SwiftLint configuration file.

Declare this in your BUILD file (e.g., in the top-level BUILD file). If you
have multiple configuration files, add them all to this `filegroup` target.

```starlark
filegroup(
    name = "swiftlint_config",
    srcs = [".swiftlint.yml"],
)
```

3. Add the following to your `.bazelrc` file

```
build --aspects=@com_github_thii_rules_swiftlint//swiftlint:defs.bzl%swiftlint_aspect
build --@com_github_thii_rules_swiftlint//swiftlint:config=//:swiftlint_config
```

Then build your target as usual. SwiftLint validation will run as part of the
build and report violations as build warnings and errors.

```
bazel build //your:target
```

If you only want to run SwiftLint validation alone, add a new Bazel config for
that, and explicitly request only the `_validation` output group:

```
build:swiftlint --aspects=@com_github_thii_rules_swiftlint//swiftlint:defs.bzl%swiftlint_aspect
build:swiftlint --@com_github_thii_rules_swiftlint//swiftlint:config=//:swiftlint_config
build:swiftlint --output_groups=_validation
```

Then you can run SwiftLint validation without building your target with:

```
bazel build --config=swiftlint //your:target
```

If you only want to build your target but skip the SwiftLint validation, you
can do so by setting the `--norun_validations` (or
`--run_validations={0,false,no}`) flag in your build.

```
bazel build --norun_validations //your:target
```

## Examples

```
bazel build //examples:main
```

## Acknowledgments

This repository uses the Bazel ruleset template from
https://github.com/bazel-contrib/rules-template.
