import UIKit
import AmaniSDK
import CoreNFC

/**
 The HomeViewController class is used to provide a user interface for home/main screen.
 */
class HomeViewController: BaseViewController {
    let appConfig = try? Amani.sharedInstance.appConfig().getApplicationConfig()
    var viewAppeared:Bool = false
    
    var stepModels: [KYCStepViewModel]? = nil
    var customerData: CustomerResponseModel? = nil
    var nonKYCStepManager: NonKYCStepManager? = nil
    var isSuccess: Bool = false
    
    // MARK: - Properties
    private var descriptionLabel = UILabel()
  private var kycStepTblView: KYCStepTblView! = KYCStepTblView()
    private var amaniLogo = UIImageView()
    private var continueButton = UIButton(type: .custom)
    private var tableBottomToLogoConstraint: NSLayoutConstraint!
    private var tableBottomToButtonConstraint: NSLayoutConstraint!
    
 // MARK: - HomeViewController LifeCycle
  override func viewDidLoad() {
    super.viewDidLoad()
//      setConstraints()
    setupUI()
  }
  
  override func viewWillAppear(
    _ animated: Bool
  ) {
    super.viewWillAppear(animated)
    
    viewAppeared = false
    
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(didReceiveStepModel),
      name: Notification.Name(
        AppConstants
          .AmaniDelegateNotifications
          .onStepModel
          .rawValue
      ),
      object: nil
    )
    
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(didReceiveProfileStatus),
      name: NSNotification.Name(
        AppConstants
          .AmaniDelegateNotifications
          .onProfileStatus
          .rawValue
      ),
      object: nil
    )
    
    refreshCurrentKYCState()
  }
  
  override func viewDidAppear(
    _ animated: Bool
  ) {
    super.viewDidAppear(animated)
    
    viewAppeared = true
    
    refreshCurrentKYCState()
  }
  
  override func viewWillDisappear(
    _ animated: Bool
  ) {
    super.viewWillDisappear(animated)
    
    viewAppeared = false
    
    NotificationCenter.default.removeObserver(
      self,
      name: Notification.Name(
        AppConstants
          .AmaniDelegateNotifications
          .onStepModel
          .rawValue
      ),
      object: nil
    )
    
    NotificationCenter.default.removeObserver(
      self,
      name: Notification.Name(
        AppConstants
          .AmaniDelegateNotifications
          .onProfileStatus
          .rawValue
      ),
      object: nil
    )
  }
  
  override func viewDidDisappear(
    _ animated: Bool
  ) {
    super.viewDidDisappear(animated)
  }
  
  // MARK: - Initial setup methods
  func setupUI() {
    descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
    kycStepTblView.translatesAutoresizingMaskIntoConstraints = false
    amaniLogo = UIImageView(image: UIImage(named: "ic_poweredBy", in: AmaniUI.sharedInstance.getBundle(), with: nil)?.withRenderingMode(.alwaysTemplate))
    amaniLogo.translatesAutoresizingMaskIntoConstraints = false
    amaniLogo.contentMode = .scaleAspectFit
    amaniLogo.clipsToBounds = true
    amaniLogo.tintAdjustmentMode = .normal
    amaniLogo.tintColor = hextoUIColor(hexString: "#909090")
    guard let appConfig = appConfig else {return}
    self.view.backgroundColor = hextoUIColor(hexString: appConfig.generalconfigs?.appBackground ?? "253C59")
    
    self.setNavigationLeftButton(TintColor: appConfig.generalconfigs?.topBarFontColor ?? "000000")
    
    self.setNavigationBarWith(title: (appConfig.generalconfigs?.mainTitleText!)!, textColor: hextoUIColor(hexString: appConfig.generalconfigs?.topBarFontColor ?? "000000"))
      //      onVC.headView.layer.cornerRadius = 25
      //      onVC.headView.backgroundColor = hextoUIColor(hexString: model.appBackground ?? "0F2435")
    self.setBackgroundColorOfTableView(color: hextoUIColor(hexString: appConfig.generalconfigs?.appBackground ?? "253C59"))
    setupContinueButton()
    setConstraints()
    
//    var customerInfo = Amani.sharedInstance.customerInfo().getCustomer()
//    if (customerInfo.rules != nil && customerInfo.rules!.isEmpty) {
//      if let customerResp = self.customerData {
//        customerInfo = customerResp
//      }
//    }
//    self.isSuccess = false
//    self.setCustomerInfo(model: customerInfo)
//      goToSuccess()

  }
  
  private func refreshUI() {
    var customerInfo =
    Amani.sharedInstance.customerInfo().getCustomer()

    if let rules = customerInfo.rules,
       rules.isEmpty,
       let customerData {
      customerInfo = customerData
    }

    isSuccess = false

    setCustomerInfo(model: customerInfo)
    goToSuccess()
    updateContinueButtonVisibility()
  }

  /// Sets up the bottom "Continue" button shown once all mandatory steps are complete,
  /// letting the user proceed without finishing steps marked optional in the backend config.
  private func setupContinueButton() {
    guard let appConfig = appConfig else { return }
    let gc = appConfig.generalconfigs
    continueButton.translatesAutoresizingMaskIntoConstraints = false
    continueButton.setTitle(optionalStepsContinueButtonTitle(), for: .normal)
    continueButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
    continueButton.setTitleColor(hextoUIColor(hexString: gc?.primaryButtonTextColor ?? "FFFFFF"), for: .normal)
    continueButton.backgroundColor = hextoUIColor(hexString: gc?.primaryButtonBackgroundColor ?? "#C0395A")
    continueButton.layer.cornerRadius = AmaniUI.sharedInstance.style.ctaButtonCornerRadius
    if let borderColorHex = gc?.primaryButtonBorderColor {
      continueButton.layer.borderWidth = 1.5
      continueButton.layer.borderColor = hextoUIColor(hexString: borderColorHex).cgColor
    }
    continueButton.addTarget(self, action: #selector(continueButtonTapped), for: .touchUpInside)
    continueButton.isHidden = true
  }

  private func setContinueButtonVisible(_ visible: Bool) {
    continueButton.isHidden = !visible
    tableBottomToButtonConstraint?.isActive = visible
    tableBottomToLogoConstraint?.isActive = !visible
  }

  /// Shows the Continue button once every mandatory (non-optional) step is approved/pending
  /// review, as long as at least one optional step is still incomplete — if everything
  /// (including optional steps) is already done, `goToSuccess()` takes over automatically.
  private func updateContinueButtonVisibility() {
    setContinueButtonVisible(shouldShowOptionalStepsContinueButton())
  }

  /// Shared with `HomeV2ViewController`, which builds its own V2-styled button but reuses this
  /// condition and `performSuccessNavigation()` rather than duplicating the step-filtering logic.
  func shouldShowOptionalStepsContinueButton() -> Bool {
    guard let stepModels = self.stepModels, !isSuccess else {
      return false
    }
    let kycSteps = stepModels.filter { $0.identifier == "kyc" || $0.identifier == nil }
    let optionalSteps = kycSteps.filter { $0.isOptional }
    let mandatorySteps = kycSteps.filter { !$0.isOptional }

    let mandatoryComplete = mandatorySteps.allSatisfy { $0.status == .APPROVED || $0.status == .PENDING_REVIEW }
    let allComplete = kycSteps.allSatisfy { $0.status == .APPROVED || $0.status == .PENDING_REVIEW }

    return mandatoryComplete && !optionalSteps.isEmpty && !allComplete
  }

  /// True once an optional step has been skipped to reach success — i.e. the mandatory steps
  /// are done but not every KYC step is. Used to let the success screen's back button return to
  /// Home (so the user can still finish the optional step) instead of closing the SDK, which is
  /// the right behavior only when every step, optional included, is actually complete.
  private func hasPendingOptionalSteps() -> Bool {
    guard let stepModels = self.stepModels else {
      return false
    }
    let kycSteps = stepModels.filter { $0.identifier == "kyc" || $0.identifier == nil }
    guard !kycSteps.isEmpty else {
      return false
    }
    return !kycSteps.allSatisfy { $0.status == .APPROVED || $0.status == .PENDING_REVIEW }
  }

  /// Fallback chain shared with `HomeV2ViewController` for the optional-steps Continue button title.
  func optionalStepsContinueButtonTitle() -> String {
    let gc = appConfig?.generalconfigs
    return gc?.buttonTextOptionalSteps ?? gc?.continueText ?? "Continue"
  }

  @objc private func continueButtonTapped() {
    guard !isSuccess else { return }
    performSuccessNavigation()
  }
  
  // MARK: - Actions
  /**
   This method used to pop put the controller. For example back button pressed to exit the SDK screen.
   */
//  override func popViewController() {
//    AmaniUI.sharedInstance.popViewController()
//  }
  
  func checkStatus(model: CustomerResponseModel) -> Bool{
    let rules = model.rules ?? []
    for kycRule in rules{
      if kycRule.status! != DocumentStatus.APPROVED.rawValue && kycRule.status! != DocumentStatus.PENDING_REVIEW.rawValue {
        return false
      }
    }
    return true
  }
  
  func generateKYCStepViewModels(from rules: [KYCRuleModel]) throws ->[KYCStepViewModel]? {
    guard let stepConfig = try? Amani.sharedInstance.appConfig().getApplicationConfig().stepConfig else {
      throw AppConstants.AmaniError.ConfigError
    }
    
    if stepModels == nil {
      let viewModels: [KYCStepViewModel?] = rules.map { ruleModel in
        if var stepModel = stepConfig.first(where: { $0.id == ruleModel.id }) {
          // Remove the OT as this SDK doesn't have to do anything with it
          stepModel.documents?.removeAll(where: { $0.id == "OT" })
          
          if stepModel.documents?.contains(where: { $0.id == "NF" }) == true && !NFCNDEFReaderSession.readingAvailable {
            return nil
          }
          
          // Add only if the identifer equals to kyc
          if (stepModel.identifier == "kyc"||stepModel.identifier == nil ) {
            var kycStepViewModel = KYCStepViewModel(from: stepModel, initialRule: ruleModel, topController: self)
            var documentHandler = DocumentHandlerHelper(for: stepModel.documents!, of: kycStepViewModel)
            kycStepViewModel.setDocumentHandler(documentHandler)
            return kycStepViewModel
          }
          
          return nil
        } else {
          return nil
        }
      }
      
      
      let filteredViewModels = viewModels.filter { $0 != nil && !($0?.isHidden ?? false)} as! [KYCStepViewModel]
      stepModels = filteredViewModels.sorted { $0.sortOrder < $1.sortOrder }
    } else {
      rules.forEach { ruleModel in
        if let stepModel = stepConfig.first(where: { $0.id == ruleModel.id }) {
          guard let rulemodelStatus:String = ruleModel.status else {return}
          guard let status:DocumentStatus = DocumentStatus(rawValue: rulemodelStatus) else {return}
        
          if let stepModels = stepModels?.first(where: {$0.id == ruleModel.id}){
            stepModels.updateStatus(status: status)
          }
//          if let stepID = stepModels?.firstIndex(where: {$0.id == ruleModel.id}) {
//            stepModels?.remove(at: stepID)
//            stepModels?.append(KYCStepViewModel(from: stepModel, initialRule: ruleModel, topController: self))
//          }
        }
      }
      stepModels = stepModels?.sorted{ $0.sortOrder < $1.sortOrder }
      return stepModels
    }
    
    
    return nil
  }
  
  func setBackgroundColorOfTableView(color: UIColor) {
    self.kycStepTblView.backgroundColor = color
  }
  
  public func bind(customerData: CustomerResponseModel, nonKYCManager: NonKYCStepManager? = nil) {
    self.customerData = customerData
    self.nonKYCStepManager = nonKYCManager
  }

  // MARK: - Overridable data methods

  func setCustomerInfo(model: CustomerResponseModel) {
    kycStepTblView.showKYCStep(stepModels: stepModels!, onSelectCallback: { [weak self] kycStepTblViewModel in
      AmaniUI.sharedInstance.markStepAsProcessing(id: kycStepTblViewModel!.id)
      DispatchQueue.main.async {
        self?.kycStepTblView.updateStatus(for: kycStepTblViewModel!, status: .PROCESSING)
      }
      kycStepTblViewModel!.upload { (result,args) in }
    })
  }

  func onStepModel(rules: [AmaniSDK.KYCRuleModel]?) {
    DispatchQueue.main.async {
      if self.viewAppeared {
        guard let kycStepTblView = self.kycStepTblView else { return }
        guard let stepModelleri = try? self.generateKYCStepViewModels(from: AmaniUI.sharedInstance.rulesKYC) else { return }
        self.kycStepTblView.updateDataAndReload(stepModels: stepModelleri)
        self.goToSuccess()
        self.updateContinueButtonVisibility()
      }
    }
  }

}

// MARK: - HomeViewDelegate methods
extension HomeViewController {

  func goToSuccess() {

    guard let stepModels = self.stepModels else {
      print("no model info passed 209")
      return
    }

    let stepResults: [Bool] = stepModels.compactMap {

      return
      ($0.identifier == "kyc" || $0.identifier == nil)
      &&
      (
        $0.status == .APPROVED
        || $0.status == .PENDING_REVIEW
      )
    }

    guard
      !isSuccess,
      stepResults.count > 0,
      !stepResults.contains(false)
    else {
      return
    }

    performSuccessNavigation()
  }

  /// Shared success-screen transition, used both by the automatic all-steps-complete path
  /// in `goToSuccess()` and by the manual "Continue" button when optional steps are skipped.
  /// Not private: `HomeV2ViewController`'s own Continue button calls this directly.
  func performSuccessNavigation() {
    // Computed before isSuccess flips to true, since hasPendingOptionalSteps() only makes sense
    // against the pre-navigation step state.
    let viaOptionalSkip = hasPendingOptionalSteps()

    isSuccess = true
    setContinueButtonVisible(false)

    /*
     KYC tamamlandı.

     Eğer POST-KYC step varsa önce onları çalıştır.
     */
    if let nonKYCManager = nonKYCStepManager,
       nonKYCManager.hasPostSteps() {

      print("[Home] Starting post-KYC flow")

      nonKYCManager.startFlow(
        forPreSteps: false
      ) { [weak self] in

        DispatchQueue.main.async {

          guard let self else {
            return
          }

          print(
            "[Home] Post-KYC flow completed - showing success"
          )

          let successVC =
          self.makeSuccessViewController(allowsReturnToHome: viaOptionalSkip)

          guard let navigationController =
                  self.navigationController
          else {
            print(
              "[Home] navigationController nil"
            )
            return
          }

          /*

           Final stack:
           Home -> Success
           */
          navigationController.setViewControllers(
            [
              self,
              successVC
            ],
            animated: true
          )
        }
      }

      return
    }


    DispatchQueue.main.async { [weak self] in

      guard let self else {
        return
      }

      print(
        "[Home] No post-KYC steps - showing success"
      )

      let successVC =
      self.makeSuccessViewController(allowsReturnToHome: viaOptionalSkip)

      self.navigationController?
        .pushViewController(
          successVC,
          animated: true
        )
    }
  }

  func makeSuccessViewController(allowsReturnToHome: Bool = false) -> UIViewController {
    if AmaniUI.sharedInstance.uiVersion == .v2 {
      let vc = SuccessV2ViewController()
      vc.bind(stepModels: stepModels)
      return vc
    } else {
      let vc = SuccessViewController()
      vc.allowsReturnToHome = allowsReturnToHome
      return vc
    }
  }

  @objc
  func didReceiveStepModel(_ notification: Notification) {
    if let rules = (notification.object as? [Any?])?[1] as? [KYCRuleModel] {
      self.onStepModel(rules: rules)
    }
  }
  
  @objc
  func didReceiveProfileStatus(_ notification: Notification) {
    if let profileStatusModel = (notification.object as? [Any?])?[1] as?
        AmaniSDK.wsProfileStatusModel {
      self.onProfileStatus(profile: profileStatusModel)
    }
  }
  
  private func refreshCurrentKYCState() {
    do {
      try generateKYCStepViewModels(
        from: AmaniUI.sharedInstance.rulesKYC
      )
    } catch {
      debugPrint(error)
    }
    
    UIView.performWithoutAnimation {
      refreshUI()
      view.layoutIfNeeded()
    }
  }
  
  
}

extension HomeViewController {

  func onProfileStatus(profile: AmaniSDK.wsProfileStatusModel) {

  }

}
extension HomeViewController {
  private func setConstraints() {
    
    view.addSubview(descriptionLabel)
    view.addSubview(kycStepTblView)
    view.addSubview(continueButton)
    view.addSubview(amaniLogo)

    tableBottomToLogoConstraint = kycStepTblView.bottomAnchor.constraint(
      equalTo: amaniLogo.topAnchor,
      constant: -24
    )
    tableBottomToButtonConstraint = kycStepTblView.bottomAnchor.constraint(
      equalTo: continueButton.topAnchor,
      constant: -16
    )

    NSLayoutConstraint.activate([
      
      // MARK: Description
      
      descriptionLabel.topAnchor.constraint(
        equalTo: view.safeAreaLayoutGuide.topAnchor,
        constant: 32
      ),
      
      descriptionLabel.leadingAnchor.constraint(
        equalTo: view.safeAreaLayoutGuide.leadingAnchor,
        constant: 20
      ),
      
      descriptionLabel.trailingAnchor.constraint(
        equalTo: view.safeAreaLayoutGuide.trailingAnchor,
        constant: -20
      ),
      
      // MARK: Logo
      
      amaniLogo.widthAnchor.constraint(
        equalToConstant: 114
      ),
      
      amaniLogo.heightAnchor.constraint(
        equalToConstant: 13
      ),
      
      amaniLogo.centerXAnchor.constraint(
        equalTo: view.centerXAnchor
      ),
      
      amaniLogo.bottomAnchor.constraint(
        equalTo: view.safeAreaLayoutGuide.bottomAnchor,
        constant: -16
      ),
      
      // MARK: Table

      kycStepTblView.topAnchor.constraint(
        equalTo: descriptionLabel.bottomAnchor,
        constant: 24
      ),

      kycStepTblView.leadingAnchor.constraint(
        equalTo: view.safeAreaLayoutGuide.leadingAnchor,
        constant: 20
      ),

      kycStepTblView.trailingAnchor.constraint(
        equalTo: view.safeAreaLayoutGuide.trailingAnchor,
        constant: -20
      ),

      tableBottomToLogoConstraint,

      // MARK: Continue button (optional-steps skip)

      continueButton.leadingAnchor.constraint(
        equalTo: view.safeAreaLayoutGuide.leadingAnchor,
        constant: 20
      ),

      continueButton.trailingAnchor.constraint(
        equalTo: view.safeAreaLayoutGuide.trailingAnchor,
        constant: -20
      ),

      continueButton.bottomAnchor.constraint(
        equalTo: amaniLogo.topAnchor,
        constant: -16
      ),

      continueButton.heightAnchor.constraint(
        equalToConstant: AmaniUI.sharedInstance.style.ctaButtonHeight
      )
    ])
  }
}
