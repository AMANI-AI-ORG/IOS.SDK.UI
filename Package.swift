// swift-tools-version:5.3

import PackageDescription

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
    ),
    .library(
      name: "AmaniUISpeechVerifier",
      targets: ["AmaniUISpeechVerifier"]
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
      from: "3.7.8"
    ),
    .package(
      name: "AmaniRepo",
      url: "https://github.com/AmaniTechnologiesLtd/Mobile_SDK_Repo.git",
      from: "1.0.3"
    )
  ],
  targets: [
    .target(
      name: "AmaniUI",
      dependencies: [
        .product(
          name: "AmaniSDK",
          package: "AmaniSDK"
        ),
        "Lottie"
      ],
      path: "Sources/AmaniUI",
      exclude: [
        "SpeechVerifierIntegration"
      ],
      resources: [
        .process("Assets"),
        .process("PrivacyInfo.xcprivacy")
      ],
      linkerSettings: [
        .linkedFramework("CryptoKit"),
        .linkedFramework("CoreNFC"),
        .linkedFramework("CryptoTokenKit")
      ]
    ),
    .target(
      name: "AmaniUISpeechVerifier",
      dependencies: [
        "AmaniUI",
        .product(
          name: "AmaniSpeechVerifier",
          package: "AmaniSpeechVerifier"
        )
      ],
      path: "Sources/AmaniUISpeechVerifier"
    )
  ]
)
