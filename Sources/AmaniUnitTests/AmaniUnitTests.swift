//
//  AmaniUnitTests.swift
//  AmaniUnitTests
//
//  Created by Bedri Doğan on 22.04.2026.
//


import XCTest
import UIKit
import AmaniSDK

@testable import AmaniUI

final class AmaniUnitTests: XCTestCase {
  
  private var sut: AmaniUI!
  
  override func setUp() {
    super.setUp()
    sut = AmaniUI()
  }
  
  override func tearDown() {
    sut = nil
    super.tearDown()
  }
  
    // MARK: - DocumentID
  
  func testDocumentIDResolvesAllSupportedTypes() {
    
    let supportedTypes: [String] = [
      "ID", "NF", "SE", "DL",
      "PA", "CO", "UB", "IB",
      "SG", "VA", "ST"
    ]
    
    for identifier in supportedTypes {
      
      guard let documentID = DocumentID(
        rawValue: identifier
      ) else {
        XCTFail("Failed to resolve \(identifier)")
        continue
      }
      
      XCTAssertEqual(
        documentID.getDocumentType(),
        identifier
      )
      
      if case .OD = documentID {
        XCTFail(
          "\(identifier) incorrectly resolved as custom document"
        )
      }
    }
  }
  
  func testUnknownDocumentTypeUsesOtherDocumentFallback() {
    
    let identifier = "CUSTOM_DOCUMENT"
    
    let documentID = DocumentID(
      rawValue: identifier
    )
    
    XCTAssertEqual(
      documentID,
      .OD(identifier)
    )
    
    XCTAssertEqual(
      documentID?.getDocumentType(),
      identifier
    )
  }
  
  func testEmptyDocumentIdentifierUsesFallback() {
    
    let documentID = DocumentID(
      rawValue: ""
    )
    
    XCTAssertEqual(
      documentID,
      .OD("")
    )
  }
  
  func testDocumentIDRoundTrip() {
    
    let original = DocumentID.ST
    
    let stringValue = original.getDocumentType()
    
    let reconstructed = DocumentID(
      rawValue: stringValue
    )
    
    XCTAssertEqual(
      original,
      reconstructed
    )
  }
  
    // MARK: - SDK Initialization
  
  func testSDKInitializesWithDefaultConfiguration() {
    
    XCTAssertNotNil(sut.sdkNavigationController)
    
    if case .v1 = sut.uiVersion {
        // Expected
    } else {
      XCTFail("Default UI version must be v1")
    }
    
    XCTAssertFalse(sut.isEnabledClientSideMrz)
    
    XCTAssertNil(sut.idVideoRecord)
    XCTAssertNil(sut.idHologramDetection)
    XCTAssertNil(sut.poseEstimationRecord)
    
    XCTAssertNil(sut.preparationVideoURL)
    XCTAssertNil(sut.getNvi())
  }
  
    // MARK: - UI Version Switching
  
  func testUIVersionCanSwitchBetweenV1AndV2() {
    
    sut.uiVersion = .v2
    
    if case .v2 = sut.uiVersion {
        // Expected
    } else {
      XCTFail("UI version should be v2")
    }
    
    sut.uiVersion = .v1
    
    if case .v1 = sut.uiVersion {
        // Expected
    } else {
      XCTFail("UI version should be v1")
    }
  }
  
    // MARK: - UI Style
  
  func testUIStyleVersion1Dimensions() {
    
    let style = UIStyle.v1
    
    XCTAssertEqual(style.badgeSize, 36)
    XCTAssertEqual(style.badgeCornerRadius, 8)
    XCTAssertEqual(style.ctaButtonHeight, 50)
    XCTAssertEqual(style.ctaButtonCornerRadius, 24)
    XCTAssertEqual(style.cardBorderWidth, 2)
    XCTAssertEqual(style.navButtonSize, 36)
    XCTAssertEqual(style.navButtonCornerRadius, 8)
  }
  
  func testUIStyleVersion2Dimensions() {
    
    let style = UIStyle.v2
    
    XCTAssertEqual(style.badgeSize, 40)
    XCTAssertEqual(style.ctaButtonHeight, 56)
    XCTAssertEqual(style.cardBorderWidth, 1.5)
    XCTAssertEqual(style.navButtonSize, 36)
  }
  
  func testSDKStyleChangesWithUIVersion() {
    
    sut.uiVersion = .v1
    
    XCTAssertEqual(
      sut.style.ctaButtonHeight,
      50
    )
    
    sut.uiVersion = .v2
    
    XCTAssertEqual(
      sut.style.ctaButtonHeight,
      56
    )
  }
  
    // MARK: - Feature Flags
  
  func testVideoRecordingConfiguration() {
    
    sut.setIdVideoRecord(enable: true)
    
    XCTAssertEqual(
      sut.idVideoRecord,
      true
    )
    
    sut.setIdVideoRecord(enable: false)
    
    XCTAssertEqual(
      sut.idVideoRecord,
      false
    )
  }
  
  func testHologramDetectionConfiguration() {
    
    sut.setIdHologramDetection(enable: true)
    
    XCTAssertEqual(
      sut.idHologramDetection,
      true
    )
    
    sut.setIdHologramDetection(enable: false)
    
    XCTAssertEqual(
      sut.idHologramDetection,
      false
    )
  }
  
  func testPoseEstimationRecordingConfiguration() {
    
    sut.setPoseEstimationRecord(enable: true)
    
    XCTAssertEqual(
      sut.poseEstimationRecord,
      true
    )
    
    sut.setPoseEstimationRecord(enable: false)
    
    XCTAssertEqual(
      sut.poseEstimationRecord,
      false
    )
  }
  
  func testClientSideMRZConfiguration() {
    
    XCTAssertFalse(
      sut.isEnabledClientSideMrz
    )
    
    sut.setClientSideMrz(enabled: true)
    
    XCTAssertTrue(
      sut.isEnabledClientSideMrz
    )
    
    sut.setClientSideMrz(enabled: false)
    
    XCTAssertFalse(
      sut.isEnabledClientSideMrz
    )
  }
  
    // MARK: - Preparation Video
  
  func testPreparationVideoURLConfiguration() {
    
    let expectedURL = URL(
      string: "https://example.com/preparation.mp4"
    )!
    
    sut.setSelfiePreparationVideoURL(
      expectedURL
    )
    
    XCTAssertEqual(
      sut.preparationVideoURL,
      expectedURL
    )
    
    sut.setSelfiePreparationVideoURL(nil)
    
    XCTAssertNil(
      sut.preparationVideoURL
    )
  }
  
    // MARK: - SDK Configuration
  
  func testSDKSetConfigurationUsesRequestedUIVersion() {
    
    sut.set(
      server: "https://example.com",
      token: "unit-test-token",
      apiVersion: .v2,
      uiVersion: .v2
    )
    
    if case .v2 = sut.uiVersion {
        // Expected
    } else {
      XCTFail("Configured UI version must be v2")
    }
    
    XCTAssertEqual(
      sut.style.ctaButtonHeight,
      56
    )
  }
  
  func testSDKSetConfigurationStoresCountry() {
    
    sut.set(
      server: "https://example.com",
      token: "unit-test-token",
      country: "TR"
    )
    
    XCTAssertEqual(
      sut.country,
      "TR"
    )
  }
}
