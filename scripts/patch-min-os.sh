#!/usr/bin/env bash
#
# Raise the iOS MinimumOSVersion of the ONNX Runtime xcframework.
#
# The upstream pod archive ships the iOS frameworks with MinimumOSVersion 15.1.
# App Store validation rejects an app (ITMS-90208) when an embedded framework
# declares a LOWER MinimumOSVersion than the app itself. PhotoRepair's deployment
# target is 17.0, so we bump every iOS slice to match.
#
# The framework's "binary" is a static library archive (the SPM product is
# `type: .static`, so ONNX is linked into the app), not a Mach-O dylib — there is
# no LC_BUILD_VERSION to rewrite, and Apple's ITMS-90208 check reads the framework
# Info.plist anyway. So we only edit Info.plist, then re-sign the bundle ad-hoc so
# the sealed resources stay consistent (Xcode re-signs again when embedding).
#
# Usage: scripts/patch-min-os.sh <path/to/onnxruntime.xcframework> [min-os]
#
set -euo pipefail

XCF="${1:?usage: scripts/patch-min-os.sh <onnxruntime.xcframework> [min-os]}"
MIN="${2:-17.0}"

shopt -s nullglob
for slice in "$XCF"/ios-*; do
  [ -d "$slice" ] || continue
  fw="$slice/onnxruntime.framework"
  plist="$fw/Info.plist"
  [ -f "$plist" ] || continue

  echo "  $(basename "$slice"): MinimumOSVersion -> ${MIN}"
  plutil -replace MinimumOSVersion -string "$MIN" "$plist"
  codesign --remove-signature "$fw" 2>/dev/null || true
  codesign --force --sign - "$fw"
done
echo "Patched iOS MinimumOSVersion to ${MIN}."
