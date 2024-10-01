//
//  AmaniUIv1.swift
//  AmaniUIv1
//
//  Created by Deniz Can on 2.09.2022.
//

import AmaniSDK
import UIKit
import CoreLocation
private class AmaniBundleLocator {}

public class AmaniUI {
  public static let sharedInstance = AmaniUI()
  /// General Application Config
  /// This property represents the delegate methods.
  public weak var delegate: AmaniUIDelegate?
  // MARK: - Private setups
  /// Home Screen is the initial view controller
  private var initialVC: HomeViewController?
  private var parentVC: UIViewController?
  
  /// Internal navigation controller.
  private var sdkNavigationController: UINavigationController?
  
  // MARK: - Internal configurations
  internal var config: AppConfigModel?
  internal let sharedSDKInstance = Amani.sharedInstance
  
  
  var missingRules:[[String:String]]? = nil
  var stepsBeforeKYC: [KYCStepViewModel] = []
  
  private var bundle: Bundle!
  private var customerRespData: CustomerResponseModel? = nil
  
  private var server: String? = nil
  private var token: String? = nil
  private var userName: String? = nil
  private var password: String? = nil
  private var sharedSecret: String? = nil
  private var customer: CustomerRequestModel? = nil
  private var language: String = "tr"
  var apiVersion: ApiVersions = .v2
  private var nonKYCStepManager: NonKYCStepManager? = nil
  public var country: String? = nil
  public var nviData: NviModel? = nil
  public var location: CLLocation? = nil
  
  public var idVideoRecord:Bool = false
  public var idHologramDetection:Bool = false
  public var poseEstimationRecord:Bool = false
  public var isEnabledClientSideMrz: Bool = false
  public var isVoiceAssistantEnabled: Bool = false
  
  
  public func setVoiceAssistantValue(_ value: Bool) {
    isVoiceAssistantEnabled = value
  }
  
  public func getVoiceAssistantValue() -> Bool? {
    return isVoiceAssistantEnabled
  }
  
  /**
   This method used to get SDK bundle
   - returns: Bundle
   */
  func getBundle() -> Bundle {
    return self.bundle
  }
  
  public init() {
    setBundle()
  }
  
  //  public func setNvi(nvi:NviModel){
  //    nviData = nvi
  //  }
  public func getNvi()->NviModel?{
    return nviData
  }
  
  /**
   This method set up the SDK bundle
   
   */
  private func setBundle() {
    if let bundle = Bundle(path: "AmaniUI.bundle") {
      self.bundle = bundle
    } else if let path = Bundle(for: AmaniBundleLocator.self).path(forResource: "AmaniUI", ofType: "bundle"),
              let bundle = Bundle(path: path)  {
      self.bundle = bundle
    } else {
      //FIXME: SPM doğru konfigüre edilmediği için alttaki blok doğru çalışmıyor
//    #if !SPM
//        let bundle = Bundle(for: AmaniBundleLocator.self)
//    #else
//      let bundle = Bundle.module
//    #endif
      let bundle = Bundle.module
      self.bundle = bundle
    }
  }
  
  
  /**
   This method set the SDK configuration
   - parameter server: Server
   - parameter token:String
   - parameter sharedSecret:String
   - parameter customer: CustomerRequestModel
   - parameter language:String
   - parameter nviModel: NviModel? = nil
   - parameter country: String? = nil
   - parameter completion: (CustomerResponseModel, Error) -> ()
   */
  public func set(
    server: String,
    token: String,
    sharedSecret: String? = nil,
    customer: CustomerRequestModel? = nil,
    language: String = "tr",
    nviModel: NviModel? = nil,
    country: String? = nil,
    location: CLLocation? = nil,
    apiVersion:ApiVersions = .v2
  ) {
    self.server = server
    self.token = token
    self.sharedSecret = sharedSecret
    self.customer = customer
    self.country = country
    self.nviData = nviModel
    self.location = location
    self.apiVersion = apiVersion
    self.language = language
  }
  
  /**
   This method set the SDK configuration
   - parameter server: Server
   - parameter email: String
   - parameter password: String
   - parameter sharedSecret:String
   - parameter customer: CustomerRequestModel
   - parameter language:String
   - parameter nviModel: NviModel?
   - parameter country: NviModel?
   - parameter completion: (CustomerResponseModel, Error) -> ()
   */
  public func set(
    server: String,
    userName: String,
    password: String,
    sharedSecret: String? = nil,
    customer: CustomerRequestModel,
    language: String = "tr",
    nviModel: NviModel? = nil,
    country: String? = nil,
    location: CLLocation? = nil,
    apiVersion:ApiVersions = .v2
  ) {
    self.server = server
    self.userName = userName
    self.password = password
    self.sharedSecret = sharedSecret
    self.customer = customer
    self.country = country
    self.nviData = nviModel
    self.location = location
    self.apiVersion = apiVersion
    self.language = language
  }
  
  public func setIdVideoRecord(enable:Bool){
    idVideoRecord = enable
  }
  
  public func setIdHologramDetection(enable:Bool){
    idHologramDetection = enable
  }
  
  public func setPoseEstimationRecord(enable:Bool){
    poseEstimationRecord = enable
  }
    
    
  public func setClientSideMrz(enabled: Bool) {
    isEnabledClientSideMrz = enabled
  }

  public func setSSLPinning(certificate:URL) throws{
    do {
      try sharedSDKInstance.setSSLPinning(certificate: certificate)
    } catch (let error){
      throw error
    }
  }
  
  fileprivate func getConfig(customerModel: CustomerResponseModel?,
                             error: NetworkError?,
                             completion: ((CustomerResponseModel?, NetworkError?) -> Void)?) {
    do {
      self.config = try sharedSDKInstance.appConfig().getApplicationConfig()
    } catch let error {
      print("Error while fetching app configuration \(error)")
    }
    if let customerResponseModel = customerModel {
      self.customerRespData = customerResponseModel
    }
    
    if let comp = completion {
      comp(customerModel, error)
      updateConfig()
    }
  }
  
  public func showSDK(on parentViewController: UIViewController,
                      completion: ((CustomerResponseModel?, NetworkError?) -> ())?
  ) {
    parentVC = parentViewController
    // set the delegate regardless of init method
    self.sharedSDKInstance.setDelegate(delegate: self)
    if let customer = customer {
      if (userName != nil && password != nil) {
        sharedSDKInstance.initAmani(server: server!, userName: self.userName!, password: self.password!, sharedSecret: sharedSecret, customer: customer, language: language, apiVersion: apiVersion) {[weak self] (customerModel, error) in
          self?.getConfig(customerModel: customerModel, error: error, completion: completion)
        }
      }
    } else {
      if (token != nil){
        sharedSDKInstance.initAmani(server: server!, token: token!, sharedSecret: sharedSecret, language: language, apiVersion: apiVersion) {[weak self] (customerModel, error) in
          self?.getConfig(customerModel: customerModel, error: error, completion: completion)
        }
      }
    }

  }
  
  
  
  public func setDelegate(delegate: AmaniUIDelegate) {
    self.delegate = delegate
  }
  
  @objc
  public func popViewController() {
    let customer = sharedSDKInstance.customerInfo().getCustomer()
    guard let customerId:String = customer.id else {return}
    
    if let missingRules = missingRules {
      self.delegate?.onKYCFailed(CustomerId: customerId, Rules: missingRules)
    }
    
    
    if let sdkNavigationController = sdkNavigationController {
      sdkNavigationController.dismiss(animated: true)
    } else {
      if let navcontroller = nonKYCStepManager?.navigationController {
        navcontroller.dismiss(animated: true)
      }
    }
  }
  
  // MARK: - internal methods
  internal func updateConfig() {
    sharedSDKInstance.appConfig().fetchAppConfig {[weak self] (newConfig, error) in
      if let newConfig = newConfig {
        if let self = self {
          self.config = newConfig
          if apiVersion == .v2 {
            // launch the steps before kyc flow
            self.nonKYCStepManager = NonKYCStepManager(for: (config?.stepConfig!)!, customer: customerRespData!, vc: self.parentVC!)
            self.nonKYCStepManager!.startFlow(forPreSteps: true) {[weak self] navController in
              self?.sdkNavigationController = navController
              // This method also checks the existence of nav controller and
              // since both types are optional no need to check it here
              self?.startKYCHome()
            }
          } else {
            // It doesn't matter for api v1
            self.startKYCHome()
          }
        }
      } else {
        if let error = error {
          print("Failed to update the application configuration. Reason: \(String(describing: error.error_code)): \(String(describing: error.error_message))")
        }
      }
    }
  }
  
  private func startKYCHome() {
    DispatchQueue.main.async {
        self.initialVC = HomeViewController()
//      self.initialVC = HomeViewController(nibName: String(describing: HomeViewController.self), bundle: self.getBundle())
      self.initialVC!.bind(customerData: self.customerRespData!, nonKYCManager: self.nonKYCStepManager)
      
      // Check if sdk navigation controller in pre kyc steps
      if self.sdkNavigationController == nil {
        self.sdkNavigationController = UINavigationController(rootViewController: self.initialVC!)
        self.sdkNavigationController?.modalPresentationStyle = .fullScreen
        // Adding shadow to NavigationBar
//        self.sdkNavigationController?.setupNavigationBarShadow()
        // Show the SDK!
        self.setAppTheme(model: self.config?.generalconfigs!, onVC: self.initialVC!)
        self.parentVC?.present(self.sdkNavigationController!, animated: true)
      } else {
        // Using this method will also clear the backstack making the homevc
        // is the first controller again.
        self.setAppTheme(model: self.config?.generalconfigs!, onVC: self.initialVC!)
        self.sdkNavigationController?.setViewControllers(
          [self.initialVC!],
          animated: true
        )
      }
    }
  }
  
  /**
   This method set up the app theme color
   */
  internal func setAppTheme(model: GeneralConfig?, onVC: HomeViewController) {
    guard let model = model else {
      return
    }
    
    guard let navigationController = sdkNavigationController else {
      return
    }
    
    DispatchQueue.main.async {
      if #available(iOS 13.0, *) {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(hexString: model.topBarBackground ?? "0F2435")
        appearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor(hexString: model.topBarFontColor ?? "000000")]
        navigationController.navigationBar.standardAppearance = appearance;
        navigationController.navigationBar.scrollEdgeAppearance = appearance
      } else {
        navigationController.navigationBar.backgroundColor = UIColor(hexString: (model.topBarBackground ?? "000000"))
        navigationController.navigationBar.barTintColor = UIColor(hexString: model.topBarBackground ?? "0F2435")
        navigationController.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor(hexString: model.topBarFontColor ?? "000000")]
      }
      
      onVC.view.backgroundColor = UIColor(hexString: model.appBackground ?? "253C59")
      
      onVC.setNavigationLeftButton(TintColor: model.topBarFontColor ?? "000000")
      
      onVC.setNavigationBarWith(title: model.mainTitleText!, textColor: UIColor(hexString: model.topBarFontColor ?? "000000"))
      //      onVC.headView.layer.cornerRadius = 25
//      onVC.headView.backgroundColor = UIColor(hexString: model.appBackground ?? "0F2435")
      onVC.setBackgroundColorOfTableView(color: UIColor(hexString: model.appBackground ?? "253C59"))
    }
  }
  
  internal func generateStepsBeforeKYCOld() {
    guard let steps = self.config?.stepConfig else {
      return
    }
    
    guard let rules = self.customerRespData?.rules else {
      return
    }
    
    let stepIdentifiers = AppConstants.StepsBeforeKYC.allCases.map { $0.rawValue }
    
      let viewModels: [KYCStepViewModel?] = rules.map { ruleModel in
        // No need to add the step if it's already been approved
        if ruleModel.status == DocumentStatus.APPROVED.rawValue { return nil }
        if let stepModel = steps.first(where: { $0.id == ruleModel.id }) {
          if stepIdentifiers.contains(stepModel.identifier ?? "") {
            // NOTE(ddnzcn): Since the step model is made for using in Home
            // DO NOT run the step with KYCStepViewModel#onStepPressed
            // This is used due to it works as a mapper between rule and step
            // model. 
            // @see PreKYCStepManager class
            return KYCStepViewModel(from: stepModel, initialRule: ruleModel, topController: self.parentVC!)
          }
        }
        return nil
      }
    
    let filteredVMs = viewModels.filter { $0 != nil } as! [KYCStepViewModel]
    self.stepsBeforeKYC = filteredVMs.sorted { $0.sortOrder < $1.sortOrder }
  }
    
  }
  


extension AmaniUI: AmaniDelegate {
  public func onProfileStatus(customerId: String, profile: AmaniSDK.wsProfileStatusModel) {
    let object: [Any?] = [customerId, profile]
    NotificationCenter.default.post(
      name: NSNotification.Name(AppConstants.AmaniDelegateNotifications.onProfileStatus.rawValue),
      object: object
    )
  }
  
  public func onStepModel(customerId: String, rules: [AmaniSDK.KYCRuleModel]?) {
    let object: [Any?] = [customerId, rules]
    NotificationCenter.default.post(
      name: NSNotification.Name(AppConstants.AmaniDelegateNotifications.onStepModel.rawValue),
      object: object)
  }
  
  public func onError(type: String, error: [AmaniSDK.AmaniError]) {
    let errors = error.map { $0.toDictonary() }
    let errorObject: [String: Any] = ["type": type, "errors": errors]
    NotificationCenter.default.post(
      name: NSNotification.Name(
        AppConstants.AmaniDelegateNotifications.onError.rawValue
      ),
      object: errorObject
    )
    AmaniUI.sharedInstance.delegate?.onError(type: type, Error: error)
  }
}

