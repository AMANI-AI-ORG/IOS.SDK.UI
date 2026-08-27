//
//  File.swift
//  Demo
//
//  Created by Münir Ketizmen on 26.01.2022.
//

import UIKit
import AmaniSDK
import Lottie

final class SignatureViewController: BaseViewController {

    // MARK: Properties
  private let signature = Amani.sharedInstance.signature()
  private var clearBtn = UIButton()
  private var confirmBtn = UIButton()
  private var animationName : String?
  private var animationView = UIView()
  private var lottieAnimationView:LottieAnimationView?
//  let amani:Amani = Amani.sharedInstance.signature()
  var viewContainer:UIView?
  var stepCount:Int = 0
  var docStep:DocumentStepModel?
  var documentVersion: DocumentVersion?
  var callback:((UIImage)->())?
  private var isDissapeared = false
  private var disappearCallback: (() -> Void)?
  private var step:steps = .front

    @objc func confirmAct(_ sender: UIButton) {
      signature.capture()
    }
    
    @objc func clearAct(_ sender: Any) {
      signature.clear()
    }

  func start(docStep: AmaniSDK.DocumentStepModel, version: AmaniSDK.DocumentVersion, completion: ((UIImage)->())?) {
    guard let steps = version.steps else {return}
    stepCount = steps.count
    self.documentVersion = version
    self.docStep = docStep
    self.callback = completion
    self.animationName = version.type
    self.playLottieAnimation()
  }
  
  func setDisappearCallback(_ callback: @escaping (() -> Void)) {
    self.disappearCallback = callback
  }
   
    override func viewDidLoad() {
        super.viewDidLoad()

    }
  
  override func viewWillAppear(_ animated: Bool) {
//    self.navigationItem.leftBarButtonItem?.title = ""
  
    }
  
    override func viewDidAppear(_ animated: Bool) {
     
      
    }
  
  override func viewWillDisappear(_ animated: Bool) {
      // remove the sdk view on exiting by calling the callback
    debugPrint("Container View disappear")
    if let disappearCb = self.disappearCallback {
      disappearCb()
    }
    isDissapeared = true
    super.viewWillDisappear(animated)
  }
  
}

// MARK: Initial setup and setting constraints
extension SignatureViewController {
  private func playLottieAnimation() {
   
    var name = "signature"
      //
            if ((AmaniUI.sharedInstance.getBundle().url(forResource: name, withExtension: "json")?.isFileURL) == nil) {
              name = "signature"
            }
            DispatchQueue.main.async {
              self.lottieInit(name: name) {[weak self] _ in
                  //      print(finishedAnimation)
                debugPrint("lottie closure'a girdi")
                self?.disappearCallback?()
                self?.setupAmaniSignature()
                self?.setupUI()
              }
            }
            
  }

  private func setupAmaniSignature() {
    do {
      
      
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
  
   private func setupUI() {
       DispatchQueue.main.async {
           let appConfig = try! Amani.sharedInstance.appConfig().getApplicationConfig()
           let buttonRadious = CGFloat(appConfig.generalconfigs?.buttonRadius ?? 10)
           
           
           // Navigation Bar
           self.setNavigationBarWith(title: self.docStep?.captureTitle ?? "", textColor: hextoUIColor(hexString: appConfig.generalconfigs?.topBarFontColor ?? "ffffff"))
           self.setNavigationLeftButton(TintColor: appConfig.generalconfigs?.topBarFontColor ?? "ffffff")
           self.view.backgroundColor = hextoUIColor(hexString: appConfig.generalconfigs?.appBackground ?? "#263B5B")
           self.confirmBtn.backgroundColor = hextoUIColor(hexString: appConfig.generalconfigs?.primaryButtonBackgroundColor ?? ThemeColor.primaryColor.toHexString())
           self.confirmBtn.layer.borderColor = hextoUIColor(hexString: appConfig.generalconfigs?.primaryButtonBorderColor ?? "#263B5B").cgColor
           self.confirmBtn.setTitle(appConfig.generalconfigs?.confirmText, for: .normal)
           self.confirmBtn.setTitleColor(hextoUIColor(hexString: appConfig.generalconfigs?.primaryButtonTextColor ?? ThemeColor.whiteColor.toHexString()), for: .normal)
           self.confirmBtn.tintColor = hextoUIColor(hexString: appConfig.generalconfigs?.primaryButtonTextColor ?? ThemeColor.whiteColor.toHexString())
           self.confirmBtn.addCornerRadiousWith(radious: buttonRadious)
           
           let secondaryBackgroundColor:UIColor = appConfig.generalconfigs?.secondaryButtonBackgroundColor == nil ? UIColor.clear :hextoUIColor(hexString: (appConfig.generalconfigs?.secondaryButtonBackgroundColor)!)

           self.clearBtn.backgroundColor = secondaryBackgroundColor
           self.clearBtn.addBorder(borderWidth: 1, borderColor: hextoUIColor(hexString: appConfig.generalconfigs?.secondaryButtonBorderColor ?? "#263B5B").cgColor)
           self.clearBtn.setTitle(self.documentVersion?.clearText ?? "Temizle", for: .normal)
           self.clearBtn.setTitleColor(hextoUIColor(hexString: appConfig.generalconfigs?.secondaryButtonTextColor ?? ThemeColor.whiteColor.toHexString()), for: .normal)
           self.clearBtn.tintColor = hextoUIColor(hexString: appConfig.generalconfigs?.secondaryButtonTextColor ?? ThemeColor.whiteColor.toHexString())
           self.clearBtn.addCornerRadiousWith(radious: buttonRadious)
           
           self.clearBtn.translatesAutoresizingMaskIntoConstraints = false
           self.confirmBtn.translatesAutoresizingMaskIntoConstraints = false
         
         
         self.clearBtn.addTarget(self, action: #selector(self.clearAct(_:)), for: .touchUpInside)
         self.confirmBtn.addTarget(self, action: #selector(self.confirmAct(_:)), for: .touchUpInside)
           
          
       }
      setConstraints()
        
  //    // For everything else
  //      imgOuterView.isHidden = false
  //      self.idImgView.image = image

  //      self.previewHeightConstraints.constant = (UIScreen.main.bounds.width - 46) * CGFloat((documentVersion?.aspectRatio!)!)
  //      self.previewHeightConstraints.isActive = true
  //      self.view.layoutIfNeeded()
  //      titleLabel.isHidden = false
  //      selfieImageView.isHidden = true
  //      physicalContractImageView.isHidden = true
  //
  //
    }
    
    private func setConstraints() {
        DispatchQueue.main.async {
            self.view.addSubviews(self.confirmBtn, self.clearBtn)
         
          guard let signBoard: UIView = self.viewContainer else { return }
          signBoard.layer.borderWidth = 0.7
          signBoard.layer.borderColor = UIColor.lightGray.cgColor
          signBoard.layer.masksToBounds = true
//          signBoard.backgroundColor = .white
          
          signBoard.translatesAutoresizingMaskIntoConstraints = false
          

            NSLayoutConstraint.activate([
              signBoard.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 32),
              signBoard.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -32),
              signBoard.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -125),
              signBoard.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 32),
              self.clearBtn.topAnchor.constraint(equalTo: self.view.bottomAnchor, constant: 40),
              self.confirmBtn.topAnchor.constraint(equalTo: self.view.bottomAnchor, constant: 40),
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
          
          self.view.layoutIfNeeded()
        }
    }
  
  
  private func lottieInit(name:String = "signature", completion: @escaping (_ finishedAnimation:Bool) -> ()) {
    
    guard let animation = LottieAnimation.named(name, bundle: AmaniUI.sharedInstance.getBundle()) else {
      debugPrint("Lottie animation not found")
      return
    }
    
    self.lottieAnimationView = LottieAnimationView(animation: animation)
    guard let lottieAnimationView = self.lottieAnimationView else {
      debugPrint("Failed to create Lottie animation view")
      return
    }
    
    lottieAnimationView.frame = view.bounds
    lottieAnimationView.translatesAutoresizingMaskIntoConstraints = false
    lottieAnimationView.contentMode = .scaleAspectFit
    lottieAnimationView.backgroundColor = .white
    lottieAnimationView.loopMode = .playOnce
    lottieAnimationView.backgroundBehavior = .pauseAndRestore
    view.addSubview(lottieAnimationView)
    
    lottieAnimationView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0).isActive = true
    lottieAnimationView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 0).isActive = true
    lottieAnimationView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: 0).isActive = true
    lottieAnimationView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0).isActive = true

      lottieAnimationView.play {[weak self] (isPlayed) in
        
        debugPrint("lottie animation oynatıldı: \(isPlayed)")
        lottieAnimationView.removeFromSuperview()
        if let isdp = self?.isDissapeared, !isdp{
          
          completion(isdp)
        }
      }
    }
    
  }

