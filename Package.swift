// swift-tools-version: 5.9

// Self-hosted Swift Package for ONNX Runtime (Objective-C bindings + C binary).
//
// This mirrors microsoft/onnxruntime-swift-package-manager @ 1.24.2, but hosts the
// underlying C pod archive as a GitHub Release asset on this repository instead of
// download.onnxruntime.ai. This avoids CI environments (e.g. Xcode Cloud) that cannot
// resolve the onnxruntime.ai CDN hostname.
//
// The `onnxruntime_extensions` target is intentionally dropped — it is not used by the
// consuming app and would add a second external download.
//
// Bindings source and the binary are unmodified Microsoft artifacts (MIT License, see LICENSE).

import PackageDescription
import class Foundation.ProcessInfo

let package = Package(
    name: "onnxruntime",
    platforms: [.iOS(.v15),
                .macOS(.v14)],
    products: [
        .library(name: "onnxruntime",
                 type: .static,
                 targets: ["OnnxRuntimeBindings"]),
    ],
    dependencies: [],
    targets: [
        .target(name: "OnnxRuntimeBindings",
                dependencies: ["onnxruntime"],
                path: "objectivec",
                exclude: ["ReadMe.md", "format_objc.sh", "test", "docs",
                            "ort_checkpoint.mm",
                            "ort_checkpoint_internal.h",
                            "ort_training_session_internal.h",
                            "ort_training_session.mm",
                            "include/ort_checkpoint.h",
                            "include/ort_training_session.h",
                            "include/onnxruntime_training.h"],
                cxxSettings: [
                    .define("SPM_BUILD"),
                ]),
    ],
    cxxLanguageStandard: .cxx17
)

// Add the ORT C/C++ pod archive as a binary target.
//
// ORT_POD_LOCAL_PATH (relative to Package.swift) can override the released archive for
// local testing against a self-built pod. Otherwise the GitHub Release asset is used.
if let pod_archive_path = ProcessInfo.processInfo.environment["ORT_POD_LOCAL_PATH"] {
    package.targets.append(Target.binaryTarget(name: "onnxruntime", path: pod_archive_path))
} else {
    package.targets.append(
       Target.binaryTarget(name: "onnxruntime",
                           url: "https://github.com/fdddf/onnxruntime-spm/releases/download/1.24.2/pod-archive-onnxruntime-c-1.24.2.zip",
                           // SHA256 checksum (identical to the upstream microsoft 1.24.2 archive)
                           checksum: "f7100a992d2a8135168c8afd831e6a58b465349101982aa58b3e11d36e600b54")
    )
}
