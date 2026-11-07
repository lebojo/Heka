#!/bin/sh
set -eu

# Only change Xcode Cloud's temporary checkout and preferences.
[ "${CI_XCODE_CLOUD:-}" = "TRUE" ] || exit 0

if [ "${CI_PRODUCT_PLATFORM:-}" != "iOS" ]; then
    echo "Heka's Xcode Cloud workflow supports iOS actions only." >&2
    exit 1
fi

case "${CI_BUILD_NUMBER:-}" in
    ''|*[!0-9]*) echo "CI_BUILD_NUMBER must be a positive integer." >&2; exit 1 ;;
esac
[ "$CI_BUILD_NUMBER" -gt 0 ] || exit 1

# Build 1 of 0.5.0 already exists in TestFlight. Cloud build 1 becomes build 2.
# Keep this offset stable; never reset Xcode Cloud's build counter.
build_number=$((CI_BUILD_NUMBER + 1))
project_file="${CI_PRIMARY_REPOSITORY_PATH:?}/Heka.xcodeproj/project.pbxproj"
sed -i '' -E "s/CURRENT_PROJECT_VERSION = [0-9.]+;/CURRENT_PROJECT_VERSION = $build_number;/g" "$project_file"
echo "iOS CURRENT_PROJECT_VERSION -> $build_number"

# SwiftTerm's pinned build-info plugin must run without an interactive prompt.
defaults write com.apple.dt.Xcode IDESkipPackagePluginFingerprintValidatation -bool YES
