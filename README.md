# onnxruntime-spm (self-hosted)

A self-hosted Swift Package Manager distribution of **ONNX Runtime 1.24.2** Objective-C
bindings, used by the PhotoRepair app.

This is a trimmed mirror of
[microsoft/onnxruntime-swift-package-manager](https://github.com/microsoft/onnxruntime-swift-package-manager)
at tag `1.24.2`, with two changes:

1. The underlying C pod archive (`pod-archive-onnxruntime-c-1.24.2.zip`) is hosted as a
   **GitHub Release asset on this repository** instead of `download.onnxruntime.ai`.
   This is required because some CI environments (notably **Xcode Cloud**) cannot resolve
   the `download.onnxruntime.ai` hostname, which breaks `xcodebuild -resolvePackageDependencies`.
2. The unused `onnxruntime_extensions` target has been removed.
3. The iOS frameworks' `MinimumOSVersion` is raised from upstream's `15.1` to `17.0`
   (the app's deployment target). App Store validation rejects an app with
   **ITMS-90208** when an embedded framework declares a lower `MinimumOSVersion`
   than the app. See `scripts/patch-min-os.sh`. (Bump this if the app's deployment
   target ever goes above 17.0.)

The Objective-C bindings source and the C binary are unmodified Microsoft artifacts,
distributed under the MIT License (see `LICENSE`).

## Usage

```swift
.package(url: "https://github.com/fdddf/onnxruntime-spm", from: "1.24.2")
```

Product: `onnxruntime` → import the module as:

```swift
import OnnxRuntimeBindings
```

## Updating the ONNX Runtime version

**Easiest:** run the **Update ONNX Runtime version** workflow (Actions tab →
Run workflow → enter the version). It does everything below automatically and
publishes the release.

**Locally** (needs macOS — the repackaging uses `plutil`/`codesign`):

```bash
scripts/update.sh <version>          # e.g. scripts/update.sh 1.25.0
```

It syncs the upstream `objectivec/` bindings, downloads the pod archive,
**repackages it with the iOS `MinimumOSVersion` raised to 17.0**, recomputes the
checksum, and rewrites `Package.swift`. Then commit, tag, and publish the release
with the repackaged zip attached (the script prints the exact commands).
