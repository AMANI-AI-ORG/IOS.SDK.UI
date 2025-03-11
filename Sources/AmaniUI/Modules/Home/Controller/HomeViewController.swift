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
  
    
    // MARK: - Properties
    private var descriptionLabel = UILabel()
  private var kycStepTblView: KYCStepTblView! = KYCStepTblView()
    private var amaniLogo = UIImageView()
    
 // MARK: - HomeViewController LifeCycle
  override func viewDidLoad() {
    super.viewDidLoad()
//      setConstraints()
      
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(true)
    NotificationCenter.default.addObserver(self, selector: #selector(didReceiveStepModel), name: Notification.Name(
      AppConstants.AmaniDelegateNotifications.onStepModel.rawValue
    ), object: nil)
    
    NotificationCenter.default.addObserver(self, selector: #selector(didReceiveProfileStatus), name: NSNotification.Name(
      AppConstants.AmaniDelegateNotifications.onProfileStatus.rawValue
    ), object: nil)
    do {
      try generateKYCStepViewModels(from: AmaniUI.sharedInstance.rulesKYC)
    }catch(let error) {
      debugPrint(error)
    }
    DispatchQueue.main.async {
      self.setupUI()
    }
    
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(true)
//    self.initialSetUp()
   
    viewAppeared = true
   
  }
  
  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    NotificationCenter.default.removeObserver(self)
//    if !isMovingFromParent && !((self.navigationController?.viewControllers.count)! > 1) {
//      AmaniUI.sharedInstance.popViewController()
//    }
  }
  

  // MARK: - Initial setup methods
  private func setupUI() {
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
    
    self.setPopButton(TintColor: appConfig.generalconfigs?.topBarFontColor ?? "000000")
    
    self.setNavigationBarWith(title: (appConfig.generalconfigs?.mainTitleText!)!, textColor: hextoUIColor(hexString: appConfig.generalconfigs?.topBarFontColor ?? "000000"))
      //      onVC.headView.layer.cornerRadius = 25
      //      onVC.headView.backgroundColor = hextoUIColor(hexString: model.appBackground ?? "0F2435")
    self.setBackgroundColorOfTableView(color: hextoUIColor(hexString: appConfig.generalconfigs?.appBackground ?? "253C59"))
    setConstraints()
    
    var customerInfo = Amani.sharedInstance.customerInfo().getCustomer()
    if (customerInfo.rules != nil && customerInfo.rules!.isEmpty) {
      if let customerResp = self.customerData {
        customerInfo = customerResp
      }
    }
   
//    if(stepModels == nil) {
     
     

      
//    }
    self.setCustomerInfo(model: customerInfo)
    if (customerInfo.status?.uppercased() == ProfileStatus.PENDING_REVIEW.rawValue || customerInfo.status?.uppercased() == ProfileStatus.APPROVED.rawValue) {
      goToSuccess()
      return
    }
    
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
  
}

// MARK: - HomeViewDelegate methods
extension HomeViewController {
  
  /**
   This method renders the rules, and uploads the document.
   */
  func setCustomerInfo(model: CustomerResponseModel) {
    
    kycStepTblView.showKYCStep(stepModels: stepModels!, onSelectCallback: { [weak self] kycStepTblViewModel in
      
      self?.kycStepTblView.updateStatus(for: kycStepTblViewModel!, status: .PROCESSING)
      kycStepTblViewModel!.upload { (result,args) in
        
//        if result == true {
//          print("upload success")
//        } else if let errors = errors {
//          
//          print(errors)
//        }
      }
    })
  }
  
  func goToSuccess() {
    
    if let nonKYCManager = self.nonKYCStepManager, nonKYCManager.hasPostSteps() {
        nonKYCManager.startFlow(forPreSteps: false) {[weak self] () in
          DispatchQueue.main.async {
            let successVC = SuccessViewController()
//            let successVC = SuccessViewController(nibName: String(describing: SuccessViewController.self), bundle: AmaniUI.sharedInstance.getBundle())
            self?.navigationController?.pushViewController(successVC, animated: true)
          }
        }
    } else {
      DispatchQueue.main.async {
          let successVC = SuccessViewController()
//        let successVC = SuccessViewController(nibName: String(describing: SuccessViewController.self), bundle: AmaniUI.sharedInstance.getBundle())
        self.navigationController?.pushViewController(successVC, animated: false)
      }  
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
  
  
}

extension HomeViewController {
  
  func onProfileStatus(profile: AmaniSDK.wsProfileStatusModel) {
    if (profile.status?.uppercased() == ProfileStatus.PENDING_REVIEW.rawValue || profile.status?.uppercased() == ProfileStatus.APPROVED.rawValue) {
      goToSuccess()
      return
    }
  }
  
  func onStepModel(rules: [AmaniSDK.KYCRuleModel]?) {
    // CHECK RULES AND OPEN SUCCESS SCREEN
    // Reload customer when upload is complete
//    print("on stepmodel \(AmaniUI.sharedInstance.rulesKYC)")
    if viewAppeared{
      guard let kycStepTblView = kycStepTblView else {return}
//      guard let rules = rules else {
//        return
//      }
//      print(AmaniUI.sharedInstance.rulesKYC)
      guard let stepModelleri =  try? self.generateKYCStepViewModels(from:  AmaniUI.sharedInstance.rulesKYC) else {return}

      DispatchQueue.main.async {
        self.kycStepTblView.updateDataAndReload(stepModels: stepModelleri)

      }
    }
  }
  
}
extension HomeViewController {
    private func setConstraints() {
        DispatchQueue.main.async { [self] in
            view.addSubview(descriptionLabel)
            view.addSubview(kycStepTblView)
            view.addSubview(amaniLogo)
            
//            self.view.addSubviews(self.kycStepTblView, self.descriptionLabel, amaniLogo)
            
            NSLayoutConstraint.activate([
              descriptionLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
              descriptionLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
              descriptionLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
              descriptionLabel.bottomAnchor.constraint(equalTo: kycStepTblView.topAnchor, constant: -40),
              // kycStepTblView constraints
              kycStepTblView.topAnchor.constraint(equalTo:  descriptionLabel.bottomAnchor, constant: 40),
              kycStepTblView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
              kycStepTblView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
              kycStepTblView.bottomAnchor.constraint(equalTo:  view.safeAreaLayoutGuide.bottomAnchor, constant: -40),

              // amaniLogo constraints
//              amaniLogo.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
//              amaniLogo.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor)
              amaniLogo.widthAnchor.constraint(equalToConstant: 114),
              amaniLogo.heightAnchor.constraint(equalToConstant: 13),
              amaniLogo.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
              amaniLogo.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -30)
            ])
        }
     
    }
}
