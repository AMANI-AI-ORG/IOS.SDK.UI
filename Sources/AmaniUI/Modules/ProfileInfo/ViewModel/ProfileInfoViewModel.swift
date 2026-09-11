//
//  ProfileInfoViewModel.swift
//  AmaniUI
//
//  Created by Deniz Can on 22.01.2024.
//

import AmaniSDK
import Combine
import Foundation

class ProfileInfoViewModel {
  private let customerInfo = Amani.sharedInstance.customerInfo()
  private var ruleID: String?

  enum ViewState {
    case loading
    case success
    case failed
    case none
  }

  @Published var name = ""
  @Published var surname = ""
  @Published var birthDay = ""
  @Published var state: ViewState = .none
//  @Published var currentErrorToShow: AmaniError?
  @Published var currentErrorToShow: String?

  var isNameValidPublisher: AnyPublisher<Bool, Never> {
    $name.debounce(for: 0.5, scheduler: RunLoop.main)
      // Arbitary number. Check with backend
      .map { newName in newName.count <= 100 }
      .eraseToAnyPublisher()
  }

  var isSurnameValidPublisher: AnyPublisher<Bool, Never> {
    $name.debounce(for: 0.5, scheduler: RunLoop.main)
      // Arbitary number. Check with backend
      .map { newName in newName.count <= 100 }
      .eraseToAnyPublisher()
  }

  var isBdayValidPublisher: AnyPublisher<Bool, Never> {
    $birthDay.debounce(for: 0.5, scheduler: RunLoop.main)
      .map { newBday in
        self.isBdayValid(input: newBday)
      }.eraseToAnyPublisher()
  }

  init() {
    setupRuleHook()
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  func submitForm() {
    guard !name.isEmpty && !surname.isEmpty else {
      state = .failed
      return
    }

    guard isBirthDayValid() else {
      state = .failed
      return
    }

    let replacedBday = birthDay.replacingOccurrences(of: "/", with: "-")
    state = .loading
    customerInfo.setName(name: name + " " + surname)
    customerInfo.setBirthDate(date: replacedBday.convertDateFormat()!)
    customerInfo.upload(location: AmaniUI.sharedInstance.location) { [weak self] uploadSuccess in
      if uploadSuccess == false {
        self?.state = .failed
        return
      }
    }
  }

  private func isBdayValid(input: String) -> Bool {
    if input == "" { return true }
    let replacedBday = input.replacingOccurrences(of: "/", with: "-")
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "dd-MM-yyyy"

    if let _ = dateFormatter.date(from: replacedBday) {
      return true
    } else {
      return false
    }
  }

  /// The default/unedited state of the birthdate field reports as an empty string, which
  /// `isBdayValid` treats as valid on its own (so the inline field error stays quiet). Submit
  /// needs to reject that case too, so it's checked here rather than relying on `isBdayValid` alone.
  func isBirthDayValid() -> Bool {
    return !birthDay.isEmpty && isBdayValid(input: birthDay)
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
        print(rule)
        if rule.status == DocumentStatus.APPROVED.rawValue {
          state = .success
        } else if rule.status == DocumentStatus.NOT_UPLOADED.rawValue {
          state = .none
        } else if rule.status == DocumentStatus.REJECTED.rawValue || rule.status == DocumentStatus.AUTOMATICALLY_REJECTED.rawValue {
          if state == .loading {
            state = .failed
            // FIXME: Consult with backend about this dumbnut being empty.
//            currentErrorToShow = rule.errors?.first
            // Btw change the type to AmaniError when the backend stuff is resolved
            currentErrorToShow = "Unable to update profile info"
          }
        }
      } else {
        state = .failed
      }
    }
  }
  
  func setupErrorHook() {
    NotificationCenter
      .default
      .addObserver(
        self,
        selector: #selector(didReceiveError),
        name: NSNotification.Name(
          AppConstants.AmaniDelegateNotifications.onError.rawValue
        ),
        object: nil)
  }
  
  @objc
  func didReceiveError(_ notification: Notification) {
    if let errorObjc = notification.object as? [String: Any] {
      let type = errorObjc["type"] as! String
      let errors = errorObjc["errors"] as! [[String: String]]
      if (type == "OTP_error") {
        if let errorMessageJson = errors.first?["errorMessage"] {
          if let detail = try? JSONDecoder()
            .decode(
              [String: String].self,
              from: errorMessageJson.data(using: .utf8)!
            ) {
            let message = detail["detail"]
            self.currentErrorToShow = message
          }
        } else {
          self.currentErrorToShow = "Unable to update the profile info"
        }
      }
    }
  }

  func setRuleID(_ ruleID: String) {
    self.ruleID = ruleID
  }
}
