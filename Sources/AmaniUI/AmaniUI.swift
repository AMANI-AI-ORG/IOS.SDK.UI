  //
  //  AmaniUIv1.swift
  //  AmaniUIv1
  //
  //  Created by Deniz Can on 2.09.2022.
  //

import AmaniSDK
import UIKit
import CoreLocation
#if canImport(AmaniVoiceAssistantSDK)
import AmaniVoiceAssistantSDK
#endif
private class AmaniBundleLocator {}

public class AmaniUI {
  public static let sharedInstance = AmaniUI()
    /// General Application Config
    /// This property represents the delegate methods.
  public weak var delegate: AmaniUIDelegate?
    // MARK: - Private setups
    /// Home Screen is the initial view controller
  private  var initialVC: HomeViewController?
  private  var parentVC: UIViewController?
  
  var sdkNavigationController: UINavigationController
  
    // MARK: - Internal configurations
  internal var config: AppConfigModel?
#if canImport(AmaniVoiceAssistantSDK)
  internal var voiceAssistant: AmaniVoiceAssistant?
#endif
  internal let sharedSDKInstance = Amani.sharedInstance
  
  
  var missingRules:[[String:String]]? = nil
  var rulesKYC: [KYCRuleModel] = []
  
  
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
  
  /**
   This method used to get SDK bundle
   - returns: Bundle
   */
  func getBundle() -> Bundle {
    return self.bundle
  }
  
  public init() {
    self.sdkNavigationController = UINavigationController()
    setBundle()
  }
  deinit {
    debugPrint("AmaniUI deallocated")
    config = nil
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
#if SWIFT_PACKAGE
      let bundle = Bundle.module
      self.bundle = bundle
#else
      let bundle = Bundle(for: AmaniBundleLocator.self)
      self.bundle = bundle
#endif
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
    
      sharedSDKInstance.appConfig().fetchAppConfig { [weak self] result, error in
        if let error = error {
          debugPrint(error)
        } else if let result:AppConfigModel = result {
          
          self?.config =  result
           
            //    MARK: Initialize AmaniVoiceAssistant
#if canImport(AmaniVoiceAssistantSDK)
          if let generalconfig = result.generalconfigs {
            if let ttsvoices:String = generalconfig.ttsVoices {
              Task { @MainActor in
                do {
                  AmaniUI.sharedInstance.voiceAssistant = try await AmaniVoiceAssistant.init(url: ttsvoices)
                } catch(let error) {
                  debugPrint("can't init voice assistant \(error)")
                }
              }
            }

          }
#endif
          
          
          if let customerResponseModel = customerModel {
            self?.customerRespData = customerResponseModel
          }
          
          if let comp = completion {
            self?.updateConfig(config: result)
            comp(customerModel, error)
            
          }
        }
      }

  }
  
  public func showSDK(on parentViewController: UIViewController,
                      completion: ((CustomerResponseModel?, NetworkError?) -> ())?
  ) {
    parentVC = parentViewController
      // set the delegate regardless of init method
    self.sharedSDKInstance.setDelegate(delegate: self)
 
    if (token != nil){
     
      sharedSDKInstance.initAmani(server: server!, token: token!, sharedSecret: sharedSecret, customer: customer, language: language, apiVersion: apiVersion) {[weak self] (customerModel, error) in
          self?.getConfig(customerModel: customerModel, error: error, completion: completion)
        
      }
    } else {
      
      if (userName != nil && password != nil) {
        if let customer = customer {
          sharedSDKInstance.initAmani(server: server!, userName: self.userName!, password: self.password!, sharedSecret: sharedSecret, customer: customer, language: language, apiVersion: apiVersion) {[weak self] (customerModel, error) in
            self?.getConfig(customerModel: customerModel, error: error, completion: completion)
          }
        }
      }
    }
    
  }
  
  
  
  public func setDelegate(delegate: AmaniUIDelegate) {
    self.delegate = delegate
  }
  
  func closeAmaniSDK() {
    config = nil
    rulesKYC = []
    sharedSDKInstance.removeDelegates()
    sharedSDKInstance.disconnectFromSocket()
  }
  
  @objc
  public func popViewController() {
    let customer = sharedSDKInstance.customerInfo().getCustomer()
    guard let customerId:String = customer.id else {return}
    
    if let missingRules = missingRules {
      self.delegate?.onKYCFailed(CustomerId: customerId, Rules: missingRules)
    }
    closeAmaniSDK()
    DispatchQueue.main.async {
      self.sdkNavigationController.dismiss(animated: true)
    }
    
  }
  
  internal func updateConfig(config: AppConfigModel) {
          guard let rules = self.customerRespData?.rules else {
            return
          }
    DispatchQueue.main.async {

      self.generateRulesKYC(rules: rules )
          
      self.setAppTheme(model: self.config?.generalconfigs! )
    if self.apiVersion == .v2 {
        // launch the steps before kyc flow
        
      self.nonKYCStepManager = NonKYCStepManager(for: config.stepConfig!, customer: self.customerRespData!, navigationController: self.sdkNavigationController, vc: self.parentVC!)
        self.nonKYCStepManager!.startFlow(forPreSteps: true) { [weak self] () in
          guard let self = self else {return}
          self.startKYCHome()
        }
        
      } else {
          // It doesn't matter for api v1
        self.startKYCHome()
      }
    }

  }
  
  private func startKYCHome() {
    DispatchQueue.main.async {
      self.initialVC = HomeViewController()
      self.initialVC?.bind(customerData: self.customerRespData!, nonKYCManager: self.nonKYCStepManager)
      try? self.initialVC?.generateKYCStepViewModels(from: self.rulesKYC)
      self.sdkNavigationController.setViewControllers(
          [self.initialVC!],
          animated: true
        )
      guard self.parentVC?.presentedViewController == nil else  { return }
      guard !self.sdkNavigationController.isBeingPresented else { return }
      self.parentVC?.present(self.sdkNavigationController, animated: true)
    }
  }
  
  /**
   This method set up the app theme color
   */
  internal func setAppTheme(model: GeneralConfig?) {
    guard let model = model else {
      return
    }
      self.sdkNavigationController.modalPresentationStyle = .fullScreen
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = hextoUIColor(hexString: model.topBarBackground ?? "0F2435")
        appearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor: hextoUIColor(hexString: model.topBarFontColor ?? "000000")]
      self.sdkNavigationController.navigationBar.standardAppearance = appearance;
      self.sdkNavigationController.navigationBar.scrollEdgeAppearance = appearance
  }
  
  func generateRulesKYC(rules: [KYCRuleModel]?) {
    guard let stepConfig = self.config?.stepConfig else {
      return
    }
    
    guard let rules = rules else {
      return
    }
    
    for ruleModel in rules {
      if let stepModel = stepConfig.first(where: {$0.id == ruleModel.id}){
        if (stepModel.identifier == "kyc"||stepModel.identifier == nil ) {
          var indexOfRules:Int = -1
          if let indexOfRulesKYC = self.rulesKYC.firstIndex(where: {$0.id == ruleModel.id}) {
            rulesKYC[indexOfRulesKYC] = ruleModel
          }else{
            self.rulesKYC.append(ruleModel)
          }
            
          }
      } else {
        print("Config issue relate with rule model id ")
      }
    }
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
    debugPrint(rules)
//    DispatchQueue.main.async {
      self.generateRulesKYC(rules: rules)
//    }
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

