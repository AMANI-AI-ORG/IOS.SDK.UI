// swift-tools-version:5.3
import PackageDescription

let UIVersion = "1.2.0"

let package = Package(
    name: "AmaniUI",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "AmaniUI",
            targets: ["AmaniUI"]
        )
    ],
    dependencies: [
        .package(
            name: "Lottie",
            url: "https://github.com/airbnb/lottie-spm.git",
            from: "4.5.0"
        ),
        .package(
            name: "AmaniRepo",
            url: "https://github.com/AmaniTechnologiesLtd/Mobile_SDK_Repo.git",
            .branch("main")
        ),
        .package(name: "AmaniLocalization",
                 path: "../AmaniLocalization")
    ],
    targets: [
        .target(
            name: "AmaniUI",
            dependencies: [
                    .product(name:"AmaniSDK", package:"AmaniRepo"),
                    "Lottie",
                    "AmaniLocalization"
                ],
            resources: [
              .process("Assets"),
              .process("PrivacyInfo.xcprivacy")
            ],
            swiftSettings: [
              .define("SPM=1"),
            ],
            linkerSettings:[
              .linkedFramework("AmaniSDK"),
              .linkedFramework("CryptoKit"),
              .linkedFramework("CoreNFC"),
              .linkedFramework("CryptoTokenKit"),
            ]
        )
    ]
)

