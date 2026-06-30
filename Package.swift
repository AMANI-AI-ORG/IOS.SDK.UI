// swift-tools-version:5.3
import PackageDescription

let UIVersion = "1.3.15"

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
            name: "AmaniSDK",
            url: "https://github.com/AMANI-AI-ORG/AmaniSDK-iOS",
            from: "3.6.9"
        ),
        .package(
            name: "AmaniVoiceAssistantSDK",
            url: "https://github.com/AMANI-AI-ORG/AmaniVoiceAssistantSDK",
            from: "1.1.1"
          )
    ],
    targets: [
        .target(
            name: "AmaniUI",
            dependencies: [
                    .product(name:"AmaniSDK", package:"AmaniSDK"),
                    .product(name:"AmaniVoiceAssistantSDK", package:"AmaniVoiceAssistantSDK"),
                    "Lottie"
                ],
            resources: [
              .process("Assets"),
              .process("PrivacyInfo.xcprivacy")
            ],
            linkerSettings:[
              .linkedFramework("CryptoKit"),
              .linkedFramework("CoreNFC"),
              .linkedFramework("CryptoTokenKit"),
            ]
        )  
    ]
)

