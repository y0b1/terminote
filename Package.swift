// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Terminote",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "Terminote", targets: ["Terminote"])
    ],
    targets: [
        .executableTarget(
            name: "Terminote",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("Carbon"),
                .linkedFramework("ServiceManagement")
            ]
        )
    ]
)
