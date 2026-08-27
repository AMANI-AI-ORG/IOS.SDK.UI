//
//  CheckSMSViewModel.swift
//  AmaniUI
//
//  Created by Deniz Can on 26.12.2023.
//

import Foundation
import Combine
import AmaniSDK

class CheckSMSViewModel {
  private let customerInfo = Amani.sharedInstance.customerInfo()
  private var ruleID: String?
  
  enum ViewState {
    case loading
    case success
    case failed
    case none
  }
  
  @Published var otp = ""
  @Published var state: ViewState = .none
  
  init() {
    setupRuleHook()
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self)
  }
  
  var isOTPValidPublisher: AnyPublisher<Bool, Never> {
    $otp.debounce(for: 0.5, scheduler: RunLoop.main)
      .map { _ in self.isValidOTPCode() }
      .eraseToAnyPublisher()
  }
  
  func submitOTP() {
    guard self.isValidOTPCode() else { return }
    
    self.state = .loading
    customerInfo.submitPhoneOTP(code: otp) {[weak self] success in
      self?.state = success == true ? .success : .failed
    }
  }
  
  func resendOTP() {
    customerInfo.requestPhoneOTPCode() {_ in
      // NO-OP?
      // error handling maybe?
    }
  }
  
  private func isValidOTPCode() -> Bool {
    // initial state
    if otp == "" { return true }
    let numericCharacterSet = CharacterSet.decimalDigits
    guard otp.rangeOfCharacter(from: numericCharacterSet.inverted) == nil else {
      return false
    }
    
    return true
  }
  
  func setupRuleHook() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(didReceiveRules),
      name: NSNotification.Name(
        AppConstants.AmaniDelegateNotifications.onStepModel.rawValue
      ),
      object: nil)
  }
  
  @objc
  func didReceiveRules(_ notification: Notification) {
    guard let ruleID = ruleID else { return }
    guard state != .success else { return }
    if let rules = (notification.object as? [Any?])?[1] as? [KYCRuleModel] {
      if let rule = rules.first(where: { $0.id == ruleID }) {
        if rule.status == DocumentStatus.APPROVED.rawValue {
          state = .success
        } else if rule.status == DocumentStatus.NOT_UPLOADED.rawValue {
          state = .none
        } else {
          state = .failed
        }
      }
    }
  }
  
  func setRuleID(_ ruleID: String) {
    self.ruleID = ruleID
  }
  
}
