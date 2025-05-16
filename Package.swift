// swift-tools-version:5.3
import PackageDescription

let UIVersion = "1.2.7"

let package = Package(
    name: "AmaniUI",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "AmaniUI",
            type: .dynamic,
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
        )
    ],
    targets: [
        .target(
            name: "AmaniUI",
            dependencies: [
                    .product(name:"AmaniSDK", package:"AmaniRepo"),
                    "Lottie"
                ],
            resources: [
              .process("Assets"),
              .process("PrivacyInfo.xcprivacy")
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

