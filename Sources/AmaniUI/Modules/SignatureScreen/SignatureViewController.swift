//
//  File.swift
//  Demo
//
//  Created by Münir Ketizmen on 26.01.2022.
//

import UIKit
import AmaniSDK
import Lottie
#if canImport(AmaniVoiceAssistantSDK)
import AmaniVoiceAssistantSDK
#endif

final class SignatureViewController: BaseViewController {

    // MARK: Properties
  private let signature = Amani.sharedInstance.signature()
  private var btnContinue = UIButton()
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
  private var disappearCallback: VoidCallback?
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
   
  }
  
  func setDisappearCallback(_ callback: @escaping VoidCallback) {
    self.disappearCallback = callback
  }
   
    override func viewDidLoad() {
        super.viewDidLoad()
      self.setupUI()
      clearBtn.isHidden = true
      confirmBtn.isHidden = true
      self.btnContinue.addTarget(self, action: #selector(actBtnContinue(_ :)), for: .touchUpInside)
    }
  
  override func viewWillAppear(_ animated: Bool) {
//    self.navigationItem.leftBarButtonItem?.title = ""
      self.playLottieAnimation()
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
  
  @objc func actBtnContinue(_ sender: UIButton) {
    print("LOTTIE ANIMATION STOPPED")
    self.lottieAnimationView?.stop()
  }
  
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
//                self?.setupUI()
//                self?.setupAmaniSignature()
                self?.clearBtn.isHidden = false
                self?.confirmBtn.isHidden = false
                self?.btnContinue.isHidden = true
                self?.disappearCallback?()
               
                
              }
            }
    self.setConstraints()
            
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
           let appConfig = try! Amani.sharedInstance.appConfig().getApplicationConfig()
           let buttonRadious = CGFloat(appConfig.generalconfigs?.buttonRadius ?? 10)
           
           
           // Navigation Bar
           self.setNavigationBarWith(title: self.docStep?.captureTitle ?? "", textColor: UIColor(hexString: appConfig.generalconfigs?.topBarFontColor ?? "ffffff"))
           self.setNavigationLeftButton(TintColor: appConfig.generalconfigs?.topBarFontColor ?? "ffffff")
           self.view.backgroundColor = UIColor(hexString: appConfig.generalconfigs?.appBackground ?? "#263B5B")
           self.confirmBtn.backgroundColor = UIColor(hexString: appConfig.generalconfigs?.primaryButtonBackgroundColor ?? ThemeColor.primaryColor.toHexString())
           self.confirmBtn.layer.borderColor = UIColor(hexString: appConfig.generalconfigs?.primaryButtonBorderColor ?? "#263B5B").cgColor
           self.confirmBtn.setTitle(appConfig.generalconfigs?.confirmText, for: .normal)
           self.confirmBtn.setTitleColor(UIColor(hexString: appConfig.generalconfigs?.primaryButtonTextColor ?? ThemeColor.whiteColor.toHexString()), for: .normal)
           self.confirmBtn.tintColor = UIColor(hexString: appConfig.generalconfigs?.primaryButtonTextColor ?? ThemeColor.whiteColor.toHexString())
           self.confirmBtn.addCornerRadiousWith(radious: buttonRadious)
     
          self.animationView.translatesAutoresizingMaskIntoConstraints = false
          self.animationView.backgroundColor = .clear
         
        btnContinue.translatesAutoresizingMaskIntoConstraints = false
         btnContinue.backgroundColor = UIColor(hexString: appConfig.generalconfigs?.primaryButtonBackgroundColor ?? ThemeColor.primaryColor.toHexString())
         btnContinue.layer.borderColor = UIColor(hexString: appConfig.generalconfigs?.primaryButtonBorderColor ?? "#263B5B").cgColor
         btnContinue.setTitle(appConfig.generalconfigs?.continueText, for: .normal)
         btnContinue.setTitleColor(UIColor(hexString: appConfig.generalconfigs?.primaryButtonTextColor ?? ThemeColor.whiteColor.toHexString()), for: .normal)
         btnContinue.tintColor = UIColor(hexString: appConfig.generalconfigs?.primaryButtonTextColor ?? ThemeColor.whiteColor.toHexString())
         btnContinue.addCornerRadiousWith(radious: buttonRadious)
           
           let secondaryBackgroundColor:UIColor = appConfig.generalconfigs?.secondaryButtonBackgroundColor == nil ? UIColor.clear :UIColor(hexString: (appConfig.generalconfigs?.secondaryButtonBackgroundColor)!)

           self.clearBtn.backgroundColor = secondaryBackgroundColor
           self.clearBtn.addBorder(borderWidth: 1, borderColor: UIColor(hexString: appConfig.generalconfigs?.secondaryButtonBorderColor ?? "#263B5B").cgColor)
           self.clearBtn.setTitle(self.documentVersion?.clearText ?? "Temizle", for: .normal)
           self.clearBtn.setTitleColor(UIColor(hexString: appConfig.generalconfigs?.secondaryButtonTextColor ?? ThemeColor.whiteColor.toHexString()), for: .normal)
           self.clearBtn.tintColor = UIColor(hexString: appConfig.generalconfigs?.secondaryButtonTextColor ?? ThemeColor.whiteColor.toHexString())
           self.clearBtn.addCornerRadiousWith(radious: buttonRadious)
           
           self.clearBtn.translatesAutoresizingMaskIntoConstraints = false
           self.confirmBtn.translatesAutoresizingMaskIntoConstraints = false
         
         
         self.clearBtn.addTarget(self, action: #selector(self.clearAct(_:)), for: .touchUpInside)
         self.confirmBtn.addTarget(self, action: #selector(self.confirmAct(_:)), for: .touchUpInside)
          
        self.setupAmaniSignature()
        self.setCanvasConstraints()
      
        
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
    DispatchQueue.main.async { [self] in
      view.addSubview(btnContinue)
      view.bringSubviewToFront(btnContinue)
      
      NSLayoutConstraint.activate([
        btnContinue.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
        btnContinue.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
        btnContinue.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        btnContinue.heightAnchor.constraint(equalToConstant: 50),
        
      ])
    }
    
  }
    
    private func setCanvasConstraints() {
        DispatchQueue.main.async { [self] in
            view.addSubviews(confirmBtn, clearBtn)
           
         
          guard let signBoard: UIView = self.viewContainer else { return }
          signBoard.layer.borderWidth = 0.7
          signBoard.layer.borderColor = UIColor.lightGray.cgColor
          signBoard.layer.masksToBounds = true
          signBoard.backgroundColor = .clear
          
          signBoard.translatesAutoresizingMaskIntoConstraints = false
          

            NSLayoutConstraint.activate([
              signBoard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
              signBoard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
              signBoard.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -125),
              signBoard.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 32),
              clearBtn.topAnchor.constraint(equalTo: view.bottomAnchor, constant: 40),
              confirmBtn.topAnchor.constraint(equalTo: view.bottomAnchor, constant: 40),
             clearBtn.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -40),
             confirmBtn.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -40),
              
             clearBtn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
             confirmBtn.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
              
             clearBtn.trailingAnchor.constraint(equalTo: view.centerXAnchor, constant: -10),
             confirmBtn.leadingAnchor.constraint(equalTo: view.centerXAnchor, constant: 10),
              
             clearBtn.heightAnchor.constraint(equalToConstant: 50),
             confirmBtn.heightAnchor.constraint(equalTo: clearBtn.heightAnchor),
              
             clearBtn.widthAnchor.constraint(equalTo: confirmBtn.widthAnchor),
              
             
             
            ])
          
          view.layoutIfNeeded()
        }
    }
  
  
  private func lottieInit(name: String = "signature", completion: @escaping (_ finishedAnimation: Int) -> ()) {
      //    var animation = LottieAnimation.named(name, bundle: AmaniUI.sharedInstance.getBundle())
    
    guard let animation = LottieAnimation.named(name, bundle: AmaniUI.sharedInstance.getBundle()) else{
      print("Animation not found")
      return
    }
    
    self.lottieAnimationView = LottieAnimationView(animation: animation)
    guard let lottieAnimationView = self.lottieAnimationView else {
      print("Failed to create Lottie animation view")
      return
    }
    
    
    
    lottieAnimationView.frame = animationView.bounds
    lottieAnimationView.backgroundColor = .white
    lottieAnimationView.contentMode = .scaleToFill
    lottieAnimationView.translatesAutoresizingMaskIntoConstraints = false
    DispatchQueue.main.async { [self] in
      view.addSubview(animationView)
      animationView.addSubview(lottieAnimationView)
      NSLayoutConstraint.activate([
        //               animationView.centerXAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.centerXAnchor),
        //                animationView.centerYAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.centerYAnchor),
        //               animationView.topAnchor.constraint(equalTo: self.titleDescription.bottomAnchor, constant: 16),
        //
        //                animationView.widthAnchor.constraint(equalTo: self.view.widthAnchor),
        //               animationView.heightAnchor.constraint(equalTo: self.view.heightAnchor, multiplier: 0.5),
        animationView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 0),
        animationView.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor),
        animationView.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor),
        animationView.bottomAnchor.constraint(equalTo: btnContinue.topAnchor, constant: -16),
        
        lottieAnimationView.leadingAnchor.constraint(equalTo: animationView.leadingAnchor),
        lottieAnimationView.trailingAnchor.constraint(equalTo: animationView.trailingAnchor),
        lottieAnimationView.topAnchor.constraint(equalTo: animationView.topAnchor),
        lottieAnimationView.bottomAnchor.constraint(equalTo: animationView.bottomAnchor)
      ])
      
      animationView.bringSubviewToFront(view)
      lottieAnimationView.play {[weak self] (_) in
        lottieAnimationView.removeFromSuperview()
        if let isdp = self?.isDissapeared, !isdp{
          completion(steps.front.rawValue)
        }
      }
    }
  }
    
  }

