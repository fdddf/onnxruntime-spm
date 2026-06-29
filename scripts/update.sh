#!/usr/bin/env bash
#
# Update this self-hosted ONNX Runtime SPM package to a new version.
#
# It syncs the Objective-C bindings from the matching upstream tag, downloads the
# ONNX Runtime C pod archive, recomputes the SHA256, and rewrites Package.swift.
# It does NOT commit / tag / publish — see the printed "Next steps" (the GitHub
# Action does those automatically).
#
# Usage:
#   scripts/update.sh <ort-version> [upstream-tag]
#
#   <ort-version>   ONNX Runtime version, e.g. 1.25.0
#                   (used for the pod archive filename and this repo's release tag)
#   [upstream-tag]  microsoft/onnxruntime-swift-package-manager tag to sync the
#                   objectivec/ bindings from. Defaults to <ort-version>.
#
set -euo pipefail

VERSION="${1:-}"
if [[ -z "$VERSION" ]]; then
  echo "usage: scripts/update.sh <ort-version> [upstream-tag]" >&2
  exit 2
fi
UPSTREAM_TAG="${2:-$VERSION}"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# Derive owner/repo from the origin remote so the binaryTarget URL stays correct
# even on a fork with a different owner.
ORIGIN_URL="$(git remote get-url origin)"
SLUG="$(printf '%s' "$ORIGIN_URL" | sed -E 's#^(git@github\.com:|https://github\.com/)##; s#\.git$##')"

PODZIP="pod-archive-onnxruntime-c-${VERSION}.zip"
CDN_URL="https://download.onnxruntime.ai/${PODZIP}"
ASSET_URL="https://github.com/${SLUG}/releases/download/${VERSION}/${PODZIP}"

echo "Repo:         ${SLUG}"
echo "ORT version:  ${VERSION}"
echo "Upstream tag: ${UPSTREAM_TAG}"
echo

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "==> Syncing objectivec/ bindings + LICENSE from microsoft @ ${UPSTREAM_TAG}"
git clone --quiet --depth 1 --branch "$UPSTREAM_TAG" \
  https://github.com/microsoft/onnxruntime-swift-package-manager "$TMP/upstream"
rm -rf objectivec
cp -R "$TMP/upstream/objectivec" objectivec
cp "$TMP/upstream/LICENSE" LICENSE

echo "==> Downloading ${CDN_URL}"
curl -fSL --retry 3 -o "$PODZIP" "$CDN_URL"

if command -v shasum >/dev/null 2>&1; then
  CHECKSUM="$(shasum -a 256 "$PODZIP" | awk '{print $1}')"
else
  CHECKSUM="$(sha256sum "$PODZIP" | awk '{print $1}')"
fi
echo "    sha256 = ${CHECKSUM}"

echo "==> Rewriting Package.swift (url + checksum)"
perl -0pi -e "s#url: \"https://github\.com/[^\"]*/releases/download/[^\"]*\"#url: \"${ASSET_URL}\"#" Package.swift
perl -0pi -e "s#checksum: \"[0-9a-f]{64}\"#checksum: \"${CHECKSUM}\"#" Package.swift

echo
echo "Prepared ONNX Runtime ${VERSION}. Binary staged at ./${PODZIP} (gitignored)."
echo
echo "Next steps:"
echo "  git add -A && git commit -m \"ONNX Runtime ${VERSION}\""
echo "  git tag ${VERSION} && git push origin HEAD ${VERSION}"
echo "  gh release create ${VERSION} ${PODZIP} --title ${VERSION} \\"
echo "      --notes \"ONNX Runtime C pod archive ${VERSION}, re-hosted from download.onnxruntime.ai\""
