#!/bin/sh
set -eu

# Only change Xcode Cloud's temporary checkout and preferences.
[ "${CI_XCODE_CLOUD:-}" = "TRUE" ] || exit 0

if [ "${CI_PRODUCT_PLATFORM:-}" != "iOS" ]; then
    echo "Heka's Xcode Cloud workflow supports iOS actions only." >&2
    exit 1
fi

# SwiftTerm's pinned build-info plugin must run without an interactive prompt.
defaults write com.apple.dt.Xcode IDESkipPackagePluginFingerprintValidatation -bool YES
