//
//  BaseViewController.swift
//  AmaniUIv1
//
//  Created by Deniz Can on 6.09.2022.
//

import UIKit
import CoreLocation
import AmaniSDK

/**
 Base controller for all view controllers
 */

class BaseViewController: UIViewController {
    
    //  let orientation: UIInterfaceOrientationMask = .portrait
    var navBarFontColor: String = "#000000"
    var navbarRightButtonAction:(() -> Void)? = nil
    var navbarLeftButtonAction: (() -> Void)? = nil
    
    override open var shouldAutorotate: Bool {
        return true
    }
    
    //  override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
    //    return orientation
    //  }
    
    //  func rotateScreen(orientation: UIInterfaceOrientationMask) {
    //    // turn screen to portrait mode
    //    UIDevice.current.setValue(orientation.rawValue, forKey: "orientation")
    //    UINavigationController.attemptRotationToDeviceOrientation()
    //  }
    
    /// The **locationManager** is a refernce of CLLocationManager which helps in determining location of user
    //  let locationManager = CLLocationManager()
    
    /// The configuration of the SDK.
    
    // MARK: - Life cycle methods
    override func viewDidLoad() {
        
        //    rotateScreen(orientation: orientation)
        self.navigationController?.delegate = self
        
        super.viewDidLoad()
        //    self.locationManager.delegate = self
       
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.baseSetup()
    }
    
    // MARK: Set up methods
    /**
     This method set up all the commmon initial feature of a controller
     */
    private func baseSetup() {
        self.setThemeColor()
        self.setupFirstPop()
        self.navigationController?.navigationBar.isHidden = false
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        }
    }
    
    func setNavigationRightButtonPDF(text: String?, tintColor: String?) {
        let leftButton: UIButton = UIButton(type: .custom)
        leftButton.setTitle(text, for: .normal)
//        leftButton.tintColor = hextoUIColor(hexString: tintColor ?? navBarFontColor)
        leftButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0)
        leftButton.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        leftButton.backgroundColor = .clear
//        leftButton.tintColor = hextoUIColor(hexString: tintColor ?? navBarFontColor)
        leftButton.setTitleColor(hextoUIColor(hexString: tintColor ?? "#20202F"), for: .normal)
        leftButton.addTarget(self, action: #selector(selectorFunc), for: .touchUpInside)
//        leftButton.addTarget(self, action: #selector(popViewController), for: .touchUpInside)
        let backBarButtonItem: UIBarButtonItem = UIBarButtonItem(customView: leftButton)
      self.navigationItem.rightBarButtonItem = backBarButtonItem
    }
    
    func setNavigationLeftButton(TintColor:String? = nil) {
        let leftButton: UIButton = UIButton(type: .custom)

        leftButton.setImage(UIImage(named: "ic_backArrow", in: AmaniUI.sharedInstance.getBundle(), compatibleWith: nil), for: .normal)
        leftButton.tintColor = hextoUIColor(hexString: TintColor ?? navBarFontColor)
        leftButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: -10, bottom: 0, right: 0)
        leftButton.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        leftButton.backgroundColor = .clear
//        leftButton.titleLabel?.text = ""
        leftButton.addTarget(self, action: #selector(popViewController), for: .touchUpInside)
        let backBarButtonItem: UIBarButtonItem = UIBarButtonItem(customView: leftButton)
        self.navigationItem.leftBarButtonItem = backBarButtonItem
    }
    
    func setPopButton(TintColor:String? = nil) {
        let leftButton: UIButton = UIButton(type: .custom)
        leftButton.setImage(UIImage(named: "ic_backArrow", in: AmaniUI.sharedInstance.getBundle(), compatibleWith: nil), for: .normal)
        leftButton.tintColor = hextoUIColor(hexString: TintColor ?? navBarFontColor)
        leftButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: -10, bottom: 0, right: 0)
        leftButton.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        leftButton.backgroundColor = .clear
        leftButton.addTarget(self, action: #selector(popToCustomerVC), for: .touchUpInside)
        let backBarButtonItem: UIBarButtonItem = UIBarButtonItem(customView: leftButton)
        self.navigationItem.leftBarButtonItem = backBarButtonItem
    }
    
    @objc func popViewController() {
        if(self.navigationController?.viewControllers.count == 1) {
          AmaniUI.sharedInstance.popViewController()
        } else {
          navigationController?.popViewController(animated: true)
        }
    }
    
    @objc func selectorFunc() {
        if let navbarRightButtonAction = navbarRightButtonAction  {
            navbarRightButtonAction()
        } else if let navbarLeftButtonAction = navbarLeftButtonAction {
            navbarLeftButtonAction()
        }
    }
    
    
    func setRightNavBarButtonAction(cb:@escaping (() -> Void)) {
        navbarRightButtonAction = cb
    }
    func setLeftNavBarButtonAction(cb:@escaping (() -> Void)) {
        navbarLeftButtonAction = cb
    }
    
    func setNavigationRightButton(text:String = "Elle Kırp", TintColor:String? = nil) {
        let rightButton: UIButton = UIButton(type: .custom)
        rightButton.setTitle(text,for: .normal)
        rightButton.setTitleColor(hextoUIColor(hexString: TintColor ?? navBarFontColor), for: .normal)
        //        rightButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: -10, bottom: 0, right: 0)
        //        rightButton.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        rightButton.backgroundColor = .clear
        rightButton.addTarget(self, action: #selector(selectorFunc), for: .touchUpInside)
        let manualCropBarButtonItem: UIBarButtonItem = UIBarButtonItem(customView: rightButton)
        self.navigationItem.rightBarButtonItem = manualCropBarButtonItem
        
    }
    
    /**
     This method used to set navigation title
     - parameter title: String
     */
    func setNavigationBarWith(title: String,textColor:UIColor? = nil) {
        self.navigationItem.title = title
        
        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = self.navigationController?.navigationBar.standardAppearance.backgroundColor
            appearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor: textColor ?? hextoUIColor(hexString: navBarFontColor)]
            self.navigationController?.navigationBar.standardAppearance = appearance;
            self.navigationController?.navigationBar.scrollEdgeAppearance =  self.navigationController?.navigationBar.standardAppearance
            
        } else {
            self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: textColor ?? hextoUIColor(hexString: navBarFontColor)]
        }
    }
    
    // If the navigation controller only has a single item
    // this function allows customer to quit the process
    func setupFirstPop() {
        if (self.navigationController?.viewControllers.count == 1) {
          
            self.setPopButton()
        }
    }
    
    /**
     This method set up the theme color
     */
    func setThemeColor() {
        let config = AmaniUI.sharedInstance.config
        
        
        navBarFontColor = config?.generalconfigs?.topBarFontColor ?? "000000"
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = hextoUIColor(hexString: config?.generalconfigs?.topBarBackground ?? "0F2435")
        appearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor: hextoUIColor(hexString: navBarFontColor)]
        appearance.shadowColor = .clear
        self.navigationController?.navigationBar.standardAppearance = appearance
        self.navigationController?.navigationBar.scrollEdgeAppearance = appearance
        self.navigationController?.navigationBar.isTranslucent = true
        self.view.backgroundColor = hextoUIColor(hexString: config?.generalconfigs?.appBackground ?? "253C59")
        self.navigationController?.navigationBar.backgroundColor = hextoUIColor(hexString: config?.generalconfigs?.topBarBackground ?? "0F2435")
        
        // Setup bottom line
        
        if let navigationBar = self.navigationController?.navigationBar {
            
            let existingLineView = navigationBar.viewWithTag(1001)
            
            if existingLineView == nil {
                
                navigationBar.setValue(true, forKey: "hidesShadow")
                
                
                let lineView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 1))
                lineView.backgroundColor = hextoUIColor(hexString: "#CACFD6")
                lineView.tag = 1001
                
                navigationBar.addSubview(lineView)
                
                // Set up constraints
                lineView.translatesAutoresizingMaskIntoConstraints = false
                lineView.widthAnchor.constraint(equalTo: navigationBar.widthAnchor).isActive = true
                lineView.heightAnchor.constraint(equalToConstant: 1).isActive = true
                lineView.centerXAnchor.constraint(equalTo: navigationBar.centerXAnchor).isActive = true
                lineView.topAnchor.constraint(equalTo: navigationBar.bottomAnchor).isActive = true
            }
        }
        
    }
    
    func setToolBar() -> UIToolbar {
        let config = AmaniUI.sharedInstance.config
        
        let toolBar = UIToolbar()
        toolBar.barStyle = UIBarStyle.default
        toolBar.isTranslucent = true
        toolBar.tintColor = .black
        toolBar.sizeToFit()
        
        let doneButton = UIBarButtonItem(title: config?.generalconfigs!.okText ?? "Tamam", style: UIBarButtonItem.Style.done, target: self, action: #selector(self.donePressOnPicker))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        toolBar.setItems([spaceButton, doneButton], animated: false)
        toolBar.isUserInteractionEnabled = true
        return toolBar
    }
    
    func addPoweredByIcon() {
        let imageView = UIImageView(image: UIImage(named: "ic_poweredBy"))
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -30)
        ])
    }
    
    // MARK: - Actions
    /**
     This action used to pop out the controller on click of navigation back button
     */
    
    
    @objc func donePressOnPicker() {
        self.view.endEditing(true)
    }
    
    @objc
    func popToCustomerVC() {
        AmaniUI.sharedInstance.popViewController()
    }
    
    
}

extension BaseViewController {
    
    /**
     This method used to show error prompts
     - parameter error: BPError
     */
    func showError(error: NetworkError) {
        print(error)
        let generalConfigs = try? Amani.sharedInstance.appConfig().getApplicationConfig().generalconfigs
        if (error.error_code != 10500) {
            DispatchQueue.main.async {
                AlertDialogueUtility.shared.showMsgAlertWithHandler(controller: self, alertTitle: "", message: error.error_message ?? "", successTitle: (generalConfigs?.okText ?? "Tamam")!, success: { (_: UIAlertAction) in
                    self.navigationController?.dismiss(animated: true, completion: nil)
                    self.navigationController?.popToRootViewController(animated: true)
                }, failureTitle: nil, failure: nil)
            }
            
        }
    }
    
}

extension  BaseViewController: UINavigationControllerDelegate {
    public func navigationControllerSupportedInterfaceOrientations(_ navigationController: UINavigationController) -> UIInterfaceOrientationMask {
        return navigationController.topViewController!.supportedInterfaceOrientations
    }
    
}
