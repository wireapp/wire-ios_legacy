// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "CoreCrypto",
    platforms: [.iOS(.v12)],
    products: [
        .library(
            name: "CoreCrypto",
            targets: ["CoreCrypto", "CoreCryptoSwift"]
        ),
        .library(
            name: "LibCoreCrypto",
            targets: ["LibCoreCrypto"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "CoreCrypto",
            dependencies: ["CoreCryptoSwift"]
        ),
        .systemLibrary(
            name: "LibCoreCrypto",
            path: "./lib"
        ),
        .target(
            name: "CoreCryptoSwift",
            dependencies: ["LibCoreCrypto"]
        )
    ]
)
