load("@bazel_skylib//lib:paths.bzl", "paths")

# From https://github.com/bazelbuild/rules_swift/blob/d44c3c5c1e162ea7b43b89924c1c4b639789cecc/swift/internal/utils.bzl#L290
def owner_relative_path(file):
    """Returns the part of the given file's path relative to its owning package.

    This function has extra logic to properly handle references to files in
    external repositoriies.

    Args:
        file: The file whose owner-relative path should be returned.

    Returns:
        The owner-relative path to the file.
    """
    root = file.owner.workspace_root
    package = file.owner.package

    if file.is_source:
        # Even though the docs say a File's `short_path` doesn't include the
        # root, Bazel special cases anything from an external repository and
        # includes a relative path (`../`) to the file. On the File's `owner` we
        # can get the `workspace_root` to try and line things up, but it is in
        # the form of "external/[name]". However the File's `path` does include
        # the root and leaves it in the "external/" form, so we just relativize
        # based on that instead.
        return paths.relativize(file.path, paths.join(root, package))
    elif root:
        # As above, but for generated files. The same mangling happens in
        # `short_path`, but since it is generated, the `path` includes the extra
        # output directories used by Bazel. So, we pick off the parent directory
        # segment that Bazel adds to the `short_path` and turn it into
        # "external/" so a relative path from the owner can be computed.
        short_path = file.short_path

        # Sanity check.
        if (
            not root.startswith("external/") or
            not short_path.startswith("../")
        ):
            fail(("Generated file in a different workspace with unexpected " +
                  "short_path ({short_path}) and owner.workspace_root " +
                  "({root}).").format(
                root = root,
                short_path = short_path,
            ))

        return paths.relativize(
            paths.join("external", short_path[3:]),
            paths.join(root, package),
        )
    else:
        return paths.relativize(file.short_path, package)
