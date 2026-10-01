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
  
  private var completionHandler: (() -> Void)?
  
  private let customer: CustomerResponseModel
  
  private var steps: [KYCStepViewModel] = []
  private var currentStep: KYCStepViewModel?
  
  private var currentStepViewController: UIViewController?
  private var flowBaseViewControllers: [UIViewController] = []
  
    // MARK: - Flow protection
  

  private var activeStepToken: UUID?
  private var isFlowRunning = false
  private var isFinishingFlow = false
  private var locallyCompletedStepIDs = Set<String>()
  
  init(
    for steps: [AmaniSDK.StepConfig],
    customer: CustomerResponseModel,
    navigationController: UINavigationController?,
    vc: UIViewController
  ) {
    self.customer = customer
    self.navigationController = navigationController
    self.customerVC = vc
    
    generate(
      for: steps,
      rules: customer.rules ?? []
    )
  }
  
    // MARK: - Start
  
    /// If completion callback is called, current Non-KYC section is finished.
    ///
    /// IMPORTANT:
    /// Final step can be ANY step type.
    /// We never assume EmailOTP is the final step.
  func startFlow(
    forPreSteps: Bool = true,
    completionCallback: @escaping () -> Void
  ) {
    DispatchQueue.main.async { [weak self] in
      guard let self else { return }
      
      guard !self.isFlowRunning else {
        print(
          "[NonKYC] Duplicate startFlow ignored",
          "manager:",
          ObjectIdentifier(self)
        )
        return
      }
      
      guard !self.isFinishingFlow else {
        print("[NonKYC] startFlow ignored - flow is finishing")
        return
      }
      
      self.completionHandler = completionCallback
      self.isFlowRunning = true
      
      self.flowBaseViewControllers =
      self.navigationController?.viewControllers ?? []
      
      let sourceSteps = forPreSteps
      ? self.preSteps
      : self.postSteps
      
      self.steps = sourceSteps.filter {
        !self.isStepCompleted($0)
      }
      
      self.currentStep = nil
      self.currentStepViewController = nil
      self.activeStepToken = nil
      
      print(
        "[NonKYC] Flow started",
        "preFlow:",
        forPreSteps,
        "pending:",
        self.steps.map { $0.identifier ?? "nil" }
      )
      
      guard !self.steps.isEmpty else {
        self.finishFlow()
        return
      }
      
      self.executeStep()
    }
  }
  
    // MARK: - Execute
  
  private func executeStep() {
    
    guard isFlowRunning else {
      return
    }
    
    guard !isFinishingFlow else {
      return
    }

    while let first = steps.first,
          isStepCompleted(first) {
      
      print(
        "[NonKYC] Skipping completed step:",
        first.identifier ?? "nil"
      )
      
      steps.removeFirst()
    }
    
    guard !steps.isEmpty else {
      finishFlow()
      return
    }
    
    let step = steps.removeFirst()
    
    currentStep = step
    
    let token = UUID()
    activeStepToken = token
    
    guard let identifier = step.identifier else {
      print("[NonKYC] Step identifier is nil")
      skipStep(token: token)
      return
    }
    
    guard let nonKYCStep =
            AppConstants.StepsBeforeKYC(rawValue: identifier)
    else {
      print(
        "[NonKYC] Unsupported step:",
        identifier
      )
      
      skipStep(token: token)
      return
    }
    
    print(
      "[NonKYC] Executing:",
      identifier,
      "token:",
      token
    )
    
    switch nonKYCStep {
      
    case .phoneOTP:
      startPhoneOTP(
        step: step,
        token: token
      )
      
    case .emailOTP:
      startEmailOTP(
        step: step,
        token: token
      )
      
    case .profileInfo:
      startProfileInfo(
        step: step,
        token: token
      )
      
    case .questionnaire:
      startQuestionnaire(
        step: step,
        token: token
      )
      
    case .termsAndConditions:
      startTermsAndConditions(
        step: step,
        token: token
      )
    }
  }
  
    // MARK: - Email OTP
  
  private func startEmailOTP(
    step: KYCStepViewModel,
    token: UUID
  ) {
    
    let emailOTPVC = EmailOTPScreenViewController()
    
    emailOTPVC.bind(
      stepVM: step
    )
    
    emailOTPVC.setCompletionHandler { [weak self] in
      
      print(
        "[NonKYC] Email OTP callback",
        "token:",
        token
      )
      
      self?.completeStep(
        token: token
      )
    }
    
    navigate(
      to: emailOTPVC,
      token: token
    )
  }
  
    // MARK: - Phone OTP
  
  private func startPhoneOTP(
    step: KYCStepViewModel,
    token: UUID
  ) {
    
    let phoneOTPVC = PhoneOTPScreenViewController()
    
    phoneOTPVC.bind(
      stepVM: step
    )
    
    phoneOTPVC.setCompletionHandler { [weak self] in
      
      print(
        "[NonKYC] Phone OTP callback",
        "token:",
        token
      )
      
      self?.completeStep(
        token: token
      )
    }
    
    navigate(
      to: phoneOTPVC,
      token: token
    )
  }
  
    // MARK: - Profile Info
  
  private func startProfileInfo(
    step: KYCStepViewModel,
    token: UUID
  ) {
    
    let profileInfoVC = ProfileInfoViewController()
    
    profileInfoVC.bind(
      with: step
    )
    
    profileInfoVC.setCompletionHandler { [weak self] in
      
      print(
        "[NonKYC] Profile callback",
        "token:",
        token
      )
      
      self?.completeStep(
        token: token
      )
    }
    
    navigate(
      to: profileInfoVC,
      token: token
    )
  }
  
    // MARK: - Questionnaire
  
  private func startQuestionnaire(
    step: KYCStepViewModel,
    token: UUID
  ) {
    
    let questionnaireVC = QuestionnaireViewController()
    
    questionnaireVC.bind(
      with: step
    )
    
    questionnaireVC.setCompletionHandler { [weak self] in
      
      print(
        "[NonKYC] Questionnaire callback",
        "token:",
        token
      )
      
      self?.completeStep(
        token: token
      )
    }
    
    navigate(
      to: questionnaireVC,
      token: token
    )
  }
  
    // MARK: - Terms
  
  private func startTermsAndConditions(
    step: KYCStepViewModel,
    token: UUID
  ) {
    
    let tcVC = TermsAndConditionsViewController()
    
    tcVC.bind(
      stepVM: step
    )
    
    tcVC.setCompletionHandler { [weak self] in
      
      print(
        "[NonKYC] Terms callback",
        "token:",
        token
      )
      
      self?.completeStep(
        token: token
      )
    }
    
    navigate(
      to: tcVC,
      token: token
    )
  }
  
    // MARK: - Step completion
  
  private func completeStep(
    token: UUID
  ) {
    DispatchQueue.main.async { [weak self] in
      guard let self else { return }
      
      guard self.activeStepToken == token else {
        
        print(
          "[NonKYC] STALE / DUPLICATE callback ignored",
          "callback token:",
          token,
          "active token:",
          String(describing: self.activeStepToken)
        )
        
        return
      }
      
      guard let completedStep = self.currentStep else {
        print("[NonKYC] currentStep nil")
        return
      }

      self.activeStepToken = nil
      
      self.locallyCompletedStepIDs.insert(
        completedStep.id
      )
      
      print(
        "[NonKYC] Step completed:",
        completedStep.identifier ?? "nil",
        "remaining:",
        self.steps.map {
          $0.identifier ?? "nil"
        }
      )
      
      self.currentStep = nil
      self.currentStepViewController = nil

      self.steps.removeAll {
        self.isStepCompleted($0)
      }
      

      if self.steps.isEmpty {
        self.finishFlow()
      } else {
        self.executeStep()
      }
    }
  }
  
    // MARK: - Skip invalid config
  
  private func skipStep(
    token: UUID
  ) {
    DispatchQueue.main.async { [weak self] in
      guard let self else { return }
      
      guard self.activeStepToken == token else {
        return
      }
      
      self.activeStepToken = nil
      self.currentStep = nil
      self.currentStepViewController = nil
      
      if self.steps.isEmpty {
        self.finishFlow()
      } else {
        self.executeStep()
      }
    }
  }
  
    // MARK: - Navigation
  
  private func navigate(
    to viewController: UIViewController,
    token: UUID
  ) {
    DispatchQueue.main.async { [weak self] in
      guard let self else { return }
      
      guard self.activeStepToken == token else {
        print("[NonKYC] Navigation ignored - stale token")
        return
      }
      
      guard let navigationController =
              self.navigationController
      else {
        print("[NonKYC] navigationController nil")
        return
      }
      
      self.currentStepViewController = viewController
      
      let isNavigationVisible =
      navigationController.presentingViewController != nil
      || navigationController.viewIfLoaded?.window != nil
      || self.customerVC?.presentedViewController
      === navigationController
      
      if isNavigationVisible {
 
        var controllers = self.flowBaseViewControllers
   
        if controllers.isEmpty {
          controllers =
          navigationController.viewControllers
        }
        
        controllers.append(viewController)
        
        print(
          "[NonKYC] Showing step in existing SDK navigation:",
          String(describing: type(of: viewController))
        )
        
        navigationController.setViewControllers(
          controllers,
          animated: true
        )
        
        return
      }
      
      print(
        "[NonKYC] Presenting SDK navigation with first pre-step:",
        String(describing: type(of: viewController))
      )
      
      navigationController.setViewControllers(
        [viewController],
        animated: false
      )
      
      guard let customerVC = self.customerVC else {
        print("[NonKYC] customerVC nil")
        return
      }
      
      guard customerVC.presentedViewController == nil else {
        
        print(
          "[NonKYC] customerVC already presenting:",
          String(
            describing:
              customerVC.presentedViewController
          )
        )
        
        return
      }
      
      customerVC.present(
        navigationController,
        animated: true
      )
    }
  }
  
    // MARK: - Finish
  
  private func finishFlow() {
    
    guard isFlowRunning else {
      return
    }
    
    guard !isFinishingFlow else {
      print("[NonKYC] Duplicate finishFlow ignored")
      return
    }
    
    isFinishingFlow = true
    activeStepToken = nil
    
    print("[NonKYC] Current Non-KYC flow completed")
    
    let completion = completionHandler
    completionHandler = nil

    currentStep = nil
    currentStepViewController = nil
    
    isFlowRunning = false
    isFinishingFlow = false
    
    DispatchQueue.main.async {
      print("[NonKYC] Calling flow completion")
      completion?()
    }
  }
  
    // MARK: - Helpers
  
  private func isStepCompleted(
    _ step: KYCStepViewModel
  ) -> Bool {
    
    if locallyCompletedStepIDs.contains(step.id) {
      return true
    }
    
    switch step.status {
      
    case .APPROVED,
        .PENDING_REVIEW:
      return true
      
    default:
      return false
    }
  }
  
    // MARK: - Generate
  
  private func generate(
    for steps: [AmaniSDK.StepConfig],
    rules: [AmaniSDK.KYCRuleModel]
  ) {
    
    let allStepModels: [KYCStepViewModel] =
    rules.compactMap { ruleModel in
      
      guard let stepModel = steps.first(
        where: {
          $0.id == ruleModel.id
        }
      ) else {
        return nil
      }
      
      return KYCStepViewModel(
        from: stepModel,
        initialRule: ruleModel,
        topController: customerVC
      )
    }
    
    if allStepModels.isEmpty {
      preSteps = []
      postSteps = []
      return
    }
    
    var sorted = allStepModels.sorted {
      $0.sortOrder < $1.sortOrder
    }
    
      // MARK: T&C injection
    
    let appConfig = try? Amani.sharedInstance
      .appConfig()
      .getApplicationConfig()
    
    let hasValidTermsURL =
    appConfig?
      .generalconfigs?
      .termsConditionsURL
      .flatMap {
        URL(string: $0)
      } != nil
    
    if appConfig?
      .generalconfigs?
      .showTermsAndConditions == true,
       customer.termsAcceptedAt == nil,
       hasValidTermsURL {
      
      if !sorted.contains(
        where: {
          $0.identifier ==
          AppConstants
            .StepsBeforeKYC
            .termsAndConditions
            .rawValue
        }
      ) {
        
        var tcStepConfig = StepConfig(
          id: "TC",
          sortOrder: -1,
          identifier:
            AppConstants
            .StepsBeforeKYC
            .termsAndConditions
            .rawValue
        )
        
        tcStepConfig.title =
        "Terms and Conditions"
        
        tcStepConfig.documents = []
        
        let tcRule = KYCRuleModel(
          id: "TC",
          sortOrder: -1,
          status:
            DocumentStatus
            .NOT_UPLOADED
            .rawValue
        )
        
        let tcStepVM = KYCStepViewModel(
          from: tcStepConfig,
          initialRule: tcRule,
          topController: customerVC
        )
        
        sorted.insert(
          tcStepVM,
          at: 0
        )
      }
    }
    
    let firstKYCIndex =
    sorted.firstIndex {
      $0.identifier == "kyc"
    }
    
    let lastKYCIndex =
    sorted.lastIndex {
      $0.identifier == "kyc"
    }
    
    guard let firstKYCIndex,
          let lastKYCIndex
    else {
      preSteps = sorted
      postSteps = []
      return
    }
    
    if firstKYCIndex == 0 {
      preSteps = []
    } else {
      preSteps = Array(
        sorted[..<firstKYCIndex]
      )
    }
    
    let postStart =
    sorted.index(
      after: lastKYCIndex
    )
    
    if postStart < sorted.endIndex {
      postSteps = Array(
        sorted[postStart...]
      )
    } else {
      postSteps = []
    }
  }
  
    // MARK: - Public helpers
  
  func stepNotExpected() {
    
    guard let token = activeStepToken else {
      
      if steps.isEmpty {
        finishFlow()
      } else {
        executeStep()
      }
      
      return
    }
    
    skipStep(
      token: token
    )
  }
  
  public func hasPostSteps() -> Bool {
    
    return postSteps.contains {
      !isStepCompleted($0)
    }
  }
}
