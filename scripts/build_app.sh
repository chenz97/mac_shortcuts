#!/bin/bash

set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
build_dir="$project_dir/.build"
app_bundle="$project_dir/dist/FixedScroll.app"
contents_dir="$app_bundle/Contents"
binary_dir="$contents_dir/MacOS"

export SWIFTPM_MODULECACHE_OVERRIDE="$build_dir/module-cache"
export CLANG_MODULE_CACHE_PATH="$build_dir/module-cache"

/usr/bin/swift build \
    --package-path "$project_dir" \
    --scratch-path "$build_dir" \
    --configuration release

binary_path="$(
    /usr/bin/swift build \
        --package-path "$project_dir" \
        --scratch-path "$build_dir" \
        --configuration release \
        --show-bin-path
)"

/bin/rm -rf "$app_bundle"
/bin/mkdir -p "$binary_dir"
/bin/cp "$binary_path/FixedScroll" "$binary_dir/FixedScroll"
/bin/cp "$project_dir/Resources/Info.plist" "$contents_dir/Info.plist"
/usr/bin/codesign --force --sign - "$app_bundle"

/usr/bin/plutil -lint "$contents_dir/Info.plist"
/usr/bin/codesign --verify --deep --strict "$app_bundle"

echo "Built $app_bundle"
