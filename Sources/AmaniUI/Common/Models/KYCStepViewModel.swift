//
//  KYCStepViewModel.swift
//  AmaniUIv1
//
//  Created by Deniz Can on 8.09.2022.
//

import UIKit
import AmaniSDK
import Foundation

class KYCStepViewModel {
  var id: String
  var title: String
  var mandatoryStepIDs: [String] = []
  var status: DocumentStatus = DocumentStatus.NOT_UPLOADED
  private var isphysicalContractEnabled: Bool!
  var textColor: UIColor = ThemeColor.blackColor
  var buttonColor: UIColor = ThemeColor.whiteColor
  var sortOrder: Int
  var identifier: String? = ""
  var isHidden: Bool = false
  private var documentSelectionTitle: String = ""
  private var documentSelectionDescription: String = ""
  private var maxAttempt: Int
  
  var documents: [DocumentModel] = []
  
  private var documentHandler: DocumentHandlerHelper!
  private var rule: KYCRuleModel!
  var topViewController: UIViewController!
  var stepConfig:StepConfig
  
  init(from stepConfig: StepConfig, initialRule: KYCRuleModel, topController onVC: UIViewController?) {
    self.stepConfig = stepConfig
    id = initialRule.id!
    title = stepConfig.buttonText?.notUploaded ?? stepConfig.title!
      
    if stepConfig.documents?.count ?? 0 > 1 {
          title = stepConfig.buttonText?.notUploaded ?? stepConfig.title!
    }
      
    mandatoryStepIDs = stepConfig.mandatoryStepIDs ?? []
    isphysicalContractEnabled = stepConfig.phase != nil && stepConfig.phase! as Int == 0 ? true : false
    maxAttempt = stepConfig.maxAttempt ?? 3
    status = DocumentStatus(rawValue: initialRule.status ?? self.status.rawValue)!
    sortOrder = initialRule.sortOrder ?? 0
    rule = initialRule
    self.identifier = stepConfig.identifier
    
    let (buttonColor, textColor) = getColorsForStatus(status: DocumentStatus(rawValue: initialRule.status!)!, stepConfig: stepConfig)
    self.buttonColor = buttonColor
    self.textColor = textColor
    
    self.documentSelectionTitle = stepConfig.documentSelectionTitle ?? ""
    self.documentSelectionDescription = stepConfig.documentSelectionDescription ?? ""
    
    topViewController = onVC
    documents = stepConfig.documents!
    
    // ??
    if (documents.count == 1) {
      if let docVersion = documents.first?.versions?.first {
        self.isHidden = docVersion.isHidden ?? false
      }
    }

  }
  
  func setDocumentHandler(_ documentHandler:DocumentHandlerHelper) {
    self.documentHandler = documentHandler
  }
  /// Updates the status of current rule
  func updateStatus(status: DocumentStatus) {
    self.status = status
    rule.status = status.rawValue
    let (buttonColor, textColor) = getColorsForStatus(status: status, stepConfig: stepConfig)
    self.buttonColor = buttonColor
    self.textColor = textColor
  }
  
  func isPassedMaxAttempt() -> Bool {
    let customer = Amani.sharedInstance.customerInfo().getCustomer()
    if let customerRuleStatus = customer.rules?.first(where: { $0.id == id }) {
      if(customerRuleStatus.attempt != nil && maxAttempt != 0 && customerRuleStatus.attempt! >= maxAttempt) {
        return true
      } else {
        return false
      }
    } else {
      print("Unkown Error")
    }
    return false
  }
  
  func onStepPressed(completion: @escaping (Result<KYCStepViewModel, KYCStepError>) -> Void) {
    // Return early if document status is Processing
    if status == .PROCESSING {
      print("Cannot start the process while document is processing.")
      return
    }
    
    // Bind the callback to the runner.
    let fullList = documents.filter({$0.versions!.count != 0})
    let isSingleVersion = ((fullList.first?.versions!.count == 1 && fullList.count == 1))

    if (isSingleVersion) {
      documentHandler.bind(topVC: topViewController, callback: completion)
      documentHandler.start(for: (documents.first?.id)!)
    } else {
      // Navigate to version select screen
        let versionSelectScreen = VersionViewController()
//      let versionSelectScreen = VersionViewController(nibName: String(describing: VersionViewController.self), bundle: AmaniUI.sharedInstance.getBundle())
      versionSelectScreen.bind(runnerHelper: self.documentHandler,
                               docTitle: self.documentSelectionTitle,
                               docDescription: self.documentSelectionDescription,
                               step: self)
      documentHandler.bind(topVC: versionSelectScreen, callback: completion)
      self.topViewController.navigationController?.pushViewController(versionSelectScreen, animated: true)
    }
  }
  
  func isEnabled() -> Bool {
//    let status = DocumentStatus(rawValue: rule.status!)
    if (mandatoryStepIDs.isEmpty) {
//      if (status != DocumentStatus.APPROVED || !isPassedMaxAttempt()) {
      if (status != DocumentStatus.APPROVED) {

        return true
      }
    } else {
      
      let allSteps = Amani.sharedInstance.customerInfo().getCustomer().rules
      // Filter rules by mandatory that approved and check the count
      return allSteps!.filter {  stepElement in
        if let elementid = stepElement.id, mandatoryStepIDs.contains(elementid){
            return stepElement.status == DocumentStatus.APPROVED.rawValue || stepElement.status == DocumentStatus.PENDING_REVIEW.rawValue
        }
        return false
      }.count == mandatoryStepIDs.count
    }
    return false
  }
  
  func getRuleModel() -> KYCRuleModel {
    return rule
  }
  
  /// Get the status of current configuration
  func getStatus() -> String? {
    return status.rawValue
  }
  
  func upload(completion: @escaping ((Bool?, [String : Any]?) -> Void)) {
    documentHandler?.upload(completion: completion)
  }
  
  func getColorsForStatus(status: DocumentStatus, stepConfig: StepConfig) -> (UIColor, UIColor) {
    let defaultWhiteHex = ThemeColor.whiteColor.toHexString()
    let defaultBlackHex = ThemeColor.blackColor.toHexString()
    switch status {
    case .NOT_UPLOADED:
      return (hextoUIColor(hexString: stepConfig.buttonColor?.notUploaded ?? defaultWhiteHex), hextoUIColor(hexString: stepConfig.buttonTextColor?.notUploaded ?? defaultBlackHex))
    case .PENDING_REVIEW:
      return (hextoUIColor(hexString: stepConfig.buttonColor?.pendingReview ?? defaultWhiteHex), hextoUIColor(hexString: stepConfig.buttonTextColor?.pendingReview ?? defaultBlackHex))
    case .PROCESSING:
      return (hextoUIColor(hexString: stepConfig.buttonColor?.processing ?? defaultWhiteHex), hextoUIColor(hexString: stepConfig.buttonTextColor?.processing ?? defaultBlackHex))
    case .REJECTED:
      return (hextoUIColor(hexString: stepConfig.buttonColor?.rejected ?? defaultWhiteHex), hextoUIColor(hexString: stepConfig.buttonTextColor?.rejected ?? defaultBlackHex))
    case .AUTOMATICALLY_REJECTED:
      return (hextoUIColor(hexString: stepConfig.buttonColor?.autoRejected ?? defaultWhiteHex), hextoUIColor(hexString: stepConfig.buttonTextColor?.autoRejected ?? defaultBlackHex))
    case .APPROVED:
      return (hextoUIColor(hexString: stepConfig.buttonColor?.approved ?? defaultWhiteHex), hextoUIColor(hexString: stepConfig.buttonTextColor?.approved ?? defaultBlackHex))
    @unknown default:
      return (ThemeColor.whiteColor, ThemeColor.blackColor)
    }
  }
  
}

enum KYCStepError: Error {
  case configError
  case moduleError
}
