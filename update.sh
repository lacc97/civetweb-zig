#!/usr/bin/env bash

# Based on some of Mach's updates scripts.

set -euo pipefail

CIVETWEB_REV=d7ba35bbb649209c66e582d5a0244ba988a15159

git_clone_rev() {
    repo=$1
    rev=$2
    dir=$3

    rm -rf "$dir"
    mkdir "$dir"
    pushd "$dir"
    git init -q
    git fetch "$repo" "$rev" --depth 1
    git checkout -q FETCH_HEAD
    popd
}

git_clone_rev https://github.com/civetweb/civetweb.git "$CIVETWEB_REV" ./_upstream

mv ./_upstream/{include,src} .
rm -rf ./_upstream