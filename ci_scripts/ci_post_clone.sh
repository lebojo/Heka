#!/bin/sh
set -eu

# Only change Xcode Cloud's temporary checkout and preferences.
[ "${CI_XCODE_CLOUD:-}" = "TRUE" ] || exit 0

if [ "${CI_PRODUCT_PLATFORM:-}" != "iOS" ]; then
    echo "Heka's Xcode Cloud workflow supports iOS actions only." >&2
    exit 1
fi

if [ -n "${CI_TAG:-}" ]; then
    tag_version="$(printf '%s' "${CI_TAG#v}" | sed -E 's/-.*//')"
    project_version="$(sed -nE 's/.*MARKETING_VERSION = ([^;]+);/\1/p' "${CI_PRIMARY_REPOSITORY_PATH:?}/Heka.xcodeproj/project.pbxproj" | sort -u)"
    if [ "$tag_version" != "$project_version" ]; then
        echo "Tag $CI_TAG needs MARKETING_VERSION = $tag_version in the project, found: $project_version." >&2
        exit 1
    fi
fi

# SwiftTerm's pinned build-info plugin must run without an interactive prompt.
defaults write com.apple.dt.Xcode IDESkipPackagePluginFingerprintValidatation -bool YES
