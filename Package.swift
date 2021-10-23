// swift-tools-version:5.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SnapPickerView",
    platforms: [
            .macOS(.v11), .iOS(.v14)
        ],
    products: [
        .library(
            name: "SnapPickerView",
            targets: ["SnapPickerView"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "SnapPickerView",
            dependencies: []),
    ]
)
