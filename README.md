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

1. Download the new `pod-archive-onnxruntime-c-<version>.zip` from `download.onnxruntime.ai`.
2. Sync the `objectivec/` bindings from the matching upstream tag.
3. Upload the zip as a Release asset under a tag matching the version.
4. Update the `url` and `checksum` in `Package.swift` (`shasum -a 256 <zip>`).
