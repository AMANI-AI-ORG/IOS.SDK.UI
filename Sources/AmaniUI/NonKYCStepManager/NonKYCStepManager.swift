  //
  //  PreKYCStepManager.swift
  //  AmaniUI
  //
  //  Created by Deniz Can on 12.01.2024.
  //

import AmaniSDK
import Foundation
import UIKit

class NonKYCStepManager {
  var preSteps: [KYCStepViewModel] = []
  var postSteps: [KYCStepViewModel] = []
  weak var customerVC: UIViewController?
  weak var navigationController: UINavigationController?
  private var completionHandler: (() -> Void)!
  private let customer: CustomerResponseModel
  private var steps: [KYCStepViewModel] = []
  private var currentStep: KYCStepViewModel!
  private var currentStepViewController: UIViewController?
  
  init(for steps: [AmaniSDK.StepConfig], customer: CustomerResponseModel,navigationController: UINavigationController?, vc: UIViewController) {
    self.customer = customer
    self.navigationController = navigationController
    customerVC = vc
    generate(for: steps, rules: customer.rules!)
  }
  
    /// If nil is returned from the completion callback it means there are no
    /// steps to start
  func startFlow(forPreSteps: Bool = true, completionCallback: @escaping () -> Void) {
    if forPreSteps {
      steps = preSteps
    } else {
      steps = postSteps
    }
    
    guard !steps.isEmpty else {
      completionCallback()
      return
    }
    
    completionHandler = completionCallback
    executeStep()
  }
  
  func stepNotExpected() {
    if steps.isEmpty {
      completionHandler?()
      return
    }
    executeStep()
  }
  
  private func executeStep() {
    currentStep = steps.removeFirst()
    guard let identifier = currentStep.identifier else {
      stepNotExpected()
      return
    }
    guard let nonKYCStep = AppConstants.StepsBeforeKYC(rawValue: identifier) else {
      stepNotExpected()
      return
    }
    
    switch nonKYCStep {
    case .phoneOTP:
      startPhoneOTP()
    case .emailOTP:
      startEmailOTP()
    case .profileInfo:
      startProfileInfo()
    case .questionnaire:
      startQuestionnaire()
    }

  }
  
  private func startEmailOTP() {
    if currentStep.status == DocumentStatus.APPROVED {
      stepCompleted()
      return
    }
    
    DispatchQueue.main.async {
      
      let emailOTPVC = EmailOTPScreenViewController()
      emailOTPVC.bind(stepVM: self.currentStep)
      emailOTPVC.setCompletionHandler { [weak self] in
        self?.stepCompleted()
      }
      
      self.currentStepViewController = emailOTPVC
      self.navigate(to: self.currentStepViewController!)
    }
  }
  
  private func startPhoneOTP() {
    if currentStep.status == DocumentStatus.APPROVED {
      stepCompleted()
      return
    }
    
    DispatchQueue.main.async {
      let phoneOTPVC = PhoneOTPScreenViewController()
      
      phoneOTPVC.bind(stepVM: self.currentStep)
      phoneOTPVC.setCompletionHandler {[weak self] in
        self?.stepCompleted()
      }
      self.currentStepViewController = phoneOTPVC
      self.navigate(to: self.currentStepViewController!)
    }
  }
  
  private func  startProfileInfo() {
    if currentStep.status == DocumentStatus.APPROVED {
      stepCompleted()
      return
    }
    
    DispatchQueue.main.async {
      
      let profileInfoVC = ProfileInfoViewController()
      profileInfoVC.bind(with: self.currentStep)
      profileInfoVC.setCompletionHandler {[weak self] in
        self?.stepCompleted()
      }
      self.currentStepViewController = profileInfoVC
      self.navigate(to: self.currentStepViewController!)
    }
  }
  
  private func startQuestionnaire() {
    if currentStep.status == DocumentStatus.APPROVED {
      stepCompleted()
      return
    }
    
    DispatchQueue.main.async {
      let questionnaireVC = QuestionnaireViewController()
      questionnaireVC.bind(with: self.currentStep)
      questionnaireVC.setCompletionHandler {[weak self] in
        self?.stepCompleted()
      }
      self.currentStepViewController = questionnaireVC
      self.navigate(to: self.currentStepViewController!)
    }
  }
  
  private func stepCompleted() {
    if steps.isEmpty {
      completionHandler()
    } else {
      executeStep()
    }
  }
  
  private func navigate(to viewController: UIViewController) {
    guard let navigationController = self.navigationController else { return }
    navigationController.setViewControllers([viewController], animated: true)
    customerVC?.present(navigationController, animated: true)
  }
  
  private func generate(for steps: [AmaniSDK.StepConfig], rules: [AmaniSDK.KYCRuleModel]) {
    let allStepModels: [KYCStepViewModel] = rules.compactMap { ruleModel in
      if let stepModel = steps.first(where: { $0.id == ruleModel.id }) {
        return KYCStepViewModel(from: stepModel, initialRule: ruleModel, topController: customerVC)
      }
      return nil
    }
    
    
    if allStepModels.isEmpty {
      self.preSteps = []
      self.postSteps = []
      return
    }
    
    let sorted = allStepModels.sorted { $0.sortOrder < $1.sortOrder }
    
    let firstKYCIndex = sorted.firstIndex(where: { return $0.identifier == "kyc"  })
    let lastKYCIndex = sorted.lastIndex(where: { $0.identifier == "kyc" })
    
    if firstKYCIndex == 0 {
      preSteps = []
    } else {
      preSteps = Array(sorted[0 ... (firstKYCIndex!.advanced(by: -1))])
    }
    postSteps = Array(sorted[lastKYCIndex!.advanced(by: 1)...])
  }
  
  public func hasPostSteps() -> Bool {
    let approvedPostStepCount = postSteps.filter { $0.status != DocumentStatus.APPROVED }.filter({$0.status != DocumentStatus.PENDING_REVIEW})
    return approvedPostStepCount.count > 0
  }
}
