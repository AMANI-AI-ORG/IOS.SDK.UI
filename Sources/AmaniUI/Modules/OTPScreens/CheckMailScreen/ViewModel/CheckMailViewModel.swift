//
//  CheckMailViewModel.swift
//  AmaniStudio
//
//  Created by Deniz Can on 11.12.2023.
//

import AmaniSDK
import Combine
import Foundation

class CheckMailViewModel {
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

  var isOTPValidPublisher: AnyPublisher<Bool, Never> {
    $otp.debounce(for: 0.5, scheduler: RunLoop.main)
      .map { _ in self.isValidOTPCode() }
      .eraseToAnyPublisher()
  }

  init() {
    setupRuleHook()
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  func submitOTP() {
    guard isValidOTPCode() else { return }

    state = .loading
    customerInfo.submitEmailOTP(code: otp) { [weak self] success in
      guard let self = self else { return }
      self.state = success == true ? .success : .failed
    }
  }

  func resendOTP() {
    customerInfo.requestEmailOTPCode { _ in
      // NO-OP?
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

  private func setupRuleHook() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(didReceiveRules),
      name: NSNotification.Name(
        AppConstants.AmaniDelegateNotifications.onStepModel.rawValue
      ),
      object: nil)
  }

  @objc
  private func didReceiveRules(_ notification: Notification) {
    guard let ruleID = ruleID else { return }
    guard state != .success else { return }
    if let rules = (notification.object as? [Any?])?[1] as? [KYCRuleModel] {
      if let rule = rules.first(where: { $0.id == ruleID }),
         rule.status == DocumentStatus.APPROVED.rawValue {
        state = .success
      } else {
        state = .failed
      }
    }
  }

  func setRuleID(_ ruleID: String) {
    self.ruleID = ruleID
  }
}
