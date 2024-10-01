//
//  File.swift
//  Demo
//
//  Created by Münir Ketizmen on 26.01.2022.
//

import UIKit
import AmaniSDK
#if canImport(AmaniLocalization)
import AmaniLocalization
#endif

final class SignatureViewController: BaseViewController {
    
    // MARK: Properties
    private lazy var clearBtn: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        
        return button
    }()
    
    private lazy var confirmBtn: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        
        return button
    }()
    
    
    let amani:Amani = Amani.sharedInstance
    var viewContainer:UIView?
  var stepCount:Int = 0
  var docStep:DocumentStepModel?
  var documentVersion: DocumentVersion?
  var callback:((UIImage)->())?
    
//  @IBOutlet weak var clearBtn: UIButton!
//  @IBOutlet weak var confirmBtn: UIButton!
  
    @objc func confirmAct(_ sender: UIButton) {
        amani.signature().capture()
    }
    
    @objc func clearAct(_ sender: Any) {
        amani.signature().clear()
    }
//  @IBAction func ConfirmAct(_ sender: UIButton) {
//        amani.signature().capture()
//  }
//    
//  @IBAction func ClearAct() {
//    amani.signature().clear()
//  }
  
  func start(docStep: AmaniSDK.DocumentStepModel, version: AmaniSDK.DocumentVersion, completion: ((UIImage)->())?) {
    guard let steps = version.steps else {return}
    stepCount = steps.count
    self.documentVersion = version
    self.docStep = docStep
    self.callback = completion
    initialSetup()
    

  }
   
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setConstraints()
        clearBtn.addTarget(self, action: #selector(clearAct(_:)), for: .touchUpInside)
        confirmBtn.addTarget(self, action: #selector(confirmAct(_:)), for: .touchUpInside)
    }
  
  override func viewWillAppear(_ animated: Bool) {
        do {
            let signature = amani.signature()
            signature.setViewArea(viewArea: view.bounds)
            
            signature.setConfirmButtonCallback {
              self.confirmBtn.isEnabled = true
            }
          
          signature.setOnConfirmPressedCallback { image, currentSignatureNo in
            print(image.cgImage?.width, image.cgImage?.height, currentSignatureNo)
          }
          
          guard let signatureView:UIView = try signature.start(stepId: stepCount, completion: { [weak self] (previewImage) in
                DispatchQueue.main.async {
                  guard let callback = self?.callback else {return}
                  callback(previewImage)
//                  callback(.success(self.stepViewModel))
//
//                    guard let previewVC:UIViewController  = self?.storyboard?.instantiateViewController(withIdentifier: "preview") else {return}
////                  ( previewVC as! DocConfirmationViewController).preImage = previewImage
//                    self?.navigationController?.pushViewController(previewVC, animated: true)
//                    self?.viewContainer?.removeFromSuperview()
                }
            }) else {return}
          
            DispatchQueue.main.async {
                self.viewContainer = signatureView
                self.view.addSubview(signatureView)
                self.view.bringSubviewToFront(self.confirmBtn)
                self.view.bringSubviewToFront(self.clearBtn)
            }
        }
        catch  {
            print("Unexpected error: \(error).")
        }
    }
  
    override func viewDidAppear(_ animated: Bool) {
    }
 
   
    
}
// MARK: Initial setup and setting constraints
extension SignatureViewController {
   private func initialSetup() {
       DispatchQueue.main.async {
           let appConfig = try! Amani.sharedInstance.appConfig().getApplicationConfig()
           let buttonRadious = CGFloat(appConfig.generalconfigs?.buttonRadius ?? 10)
           
         #if canImport(AmaniLocalization)
         self.setNavigationBarWith(title: AmaniLocalization.localizedString(forKey: "sg_captureTitle"), textColor: UIColor(hexString: appConfig.generalconfigs?.topBarFontColor ?? "ffffff"))
         self.confirmBtn.setTitle(AmaniLocalization.localizedString(forKey: "general_confirmText"), for: .normal)
         self.clearBtn.setTitle(AmaniLocalization.localizedString(forKey: "sg_clearText"), for: .normal)
         #else
         self.setNavigationBarWith(title: self.docStep?.captureTitle ?? "", textColor: UIColor(hexString: appConfig.generalconfigs?.topBarFontColor ?? "ffffff"))
         self.confirmBtn.setTitle(appConfig.generalconfigs?.confirmText, for: .normal)
         self.clearBtn.setTitle(self.documentVersion?.clearText ?? "Temizle", for: .normal)
         #endif
         
           self.setNavigationLeftButton(TintColor: appConfig.generalconfigs?.topBarFontColor ?? "ffffff")
           self.view.backgroundColor = UIColor(hexString: appConfig.generalconfigs?.appBackground ?? "#263B5B")
           self.confirmBtn.backgroundColor = UIColor(hexString: appConfig.generalconfigs?.primaryButtonBackgroundColor ?? ThemeColor.primaryColor.toHexString())
           self.confirmBtn.layer.borderColor = UIColor(hexString: appConfig.generalconfigs?.primaryButtonBorderColor ?? "#263B5B").cgColor

           self.confirmBtn.setTitleColor(UIColor(hexString: appConfig.generalconfigs?.primaryButtonTextColor ?? ThemeColor.whiteColor.toHexString()), for: .normal)
           self.confirmBtn.tintColor = UIColor(hexString: appConfig.generalconfigs?.primaryButtonTextColor ?? ThemeColor.whiteColor.toHexString())
           self.confirmBtn.addCornerRadiousWith(radious: buttonRadious)
           
           let secondaryBackgroundColor:UIColor = appConfig.generalconfigs?.secondaryButtonBackgroundColor == nil ? UIColor.clear :UIColor(hexString: (appConfig.generalconfigs?.secondaryButtonBackgroundColor)!)

           self.clearBtn.backgroundColor = secondaryBackgroundColor
           self.clearBtn.addBorder(borderWidth: 1, borderColor: UIColor(hexString: appConfig.generalconfigs?.secondaryButtonBorderColor ?? "#263B5B").cgColor)

           self.clearBtn.setTitleColor(UIColor(hexString: appConfig.generalconfigs?.secondaryButtonTextColor ?? ThemeColor.whiteColor.toHexString()), for: .normal)
           self.clearBtn.tintColor = UIColor(hexString: appConfig.generalconfigs?.secondaryButtonTextColor ?? ThemeColor.whiteColor.toHexString())
           self.clearBtn.addCornerRadiousWith(radious: buttonRadious)
           
           self.clearBtn.translatesAutoresizingMaskIntoConstraints = false
           self.confirmBtn.translatesAutoresizingMaskIntoConstraints = false
           
          
       }
    }
    
    private func setConstraints() {
        DispatchQueue.main.async {
            self.view.addSubviews(self.confirmBtn, self.clearBtn)
            
            NSLayoutConstraint.activate([
             self.clearBtn.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -40),
             self.confirmBtn.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -40),
              
             self.clearBtn.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 20),
             self.confirmBtn.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -20),
              
             self.clearBtn.trailingAnchor.constraint(equalTo: self.view.centerXAnchor, constant: -10),
             self.confirmBtn.leadingAnchor.constraint(equalTo: self.view.centerXAnchor, constant: 10),
              
             self.clearBtn.heightAnchor.constraint(equalToConstant: 50),
             self.confirmBtn.heightAnchor.constraint(equalTo: self.clearBtn.heightAnchor),
              
             self.clearBtn.widthAnchor.constraint(equalTo: self.confirmBtn.widthAnchor)
            ])
        }
    }
}
