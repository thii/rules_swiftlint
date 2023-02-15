#!/bin/bash

set -eu

if [[ $# -lt 3 ]] ; then
  echo "ERROR: Need at least three arguments." 1>&2
  exit 1
fi

swiftlint_executable="$1"
output="$2"
shift 2

# SwiftLint's output prints /var, but not the dereferenced /private/var, we
# remove that first.
working_dir="${PWD#"/private"}"

# Strip the working directory prefix to convert outputs to relative paths.
exec "$swiftlint_executable" "$@" \
  | /usr/bin/sed -E "s|$working_dir/||" \
  | tee "$output"
