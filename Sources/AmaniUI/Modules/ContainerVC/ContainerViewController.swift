//
//  AnimationViewController.swift
//  AmaniUIv1
//
//  Created by Münir Ketizmen on 7.01.2023.
//

import Lottie
import UIKit
import AmaniSDK
#if canImport(AmaniVoiceAssistantSDK)
import AmaniVoiceAssistantSDK
#endif

class ContainerViewController: BaseViewController {
    // MARK: Properties
  private var btnContinue = UIButton()
  private var animationView = UIView()
  private var titleDescription = UILabel()
    
  private var animationName : String?
  private var callback: (() -> Void)?
  private var disappearCallback: (() -> Void)?
  private var docStep:DocumentStepModel?
  private var lottieAnimationView:LottieAnimationView?
  private var step:steps = .front
  private var isDissapeared = false
  
  var stepConfig: StepConfig?
  var docID: DocumentID?
    
  func bind(animationName:String?,
            docStep:DocumentStepModel,
            step:steps,
            callback: @escaping (() -> Void)) {
    self.animationName = animationName
    self.callback = callback
    self.step = step
    self.docStep = docStep
  }
    
   
    
  func setDisappearCallback(_ callback: @escaping (() -> Void)) {
    self.disappearCallback = callback
  }
    
 
  
    override func viewDidLoad() {
      super.viewDidLoad()
      self.setupUI()
     
      self.btnContinue.addTarget(self, action: #selector(actBtnContinue(_ :)), for: .touchUpInside)
    }
    
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
      
      isDissapeared = false

    if let animationName = animationName {
      var side:String = "front"
      switch step {
      case .front:
        side = "front"
        break
      case .back:
        side = "back"
        break
      default:
        side = "front"
        break
      }
      var name = "\((animationName.lowercased()))_\(side)"
      
      var animation = LottieAnimation.named(name, bundle: AmaniUI.sharedInstance.getBundle())
      
      if animation == nil {
        print("\(name) not found")
        name = "xxx_id_\(side)"
      }
      
      #if canImport(AmaniVoiceAssistantSDK)
          if let docID = self.docID {
            Task { @MainActor in
              do {
                try? await AmaniUI.sharedInstance.voiceAssistant?.play(key: "VOICE_\(docID.getDocumentType())\(self.step.rawValue)")
              }catch(let error) {
                debugPrint("\(error)")
              }
              
            }
          }
          
      #endif
        DispatchQueue.main.async {
            self.lottieInit(name: name) {[weak self] _ in
        //      print(finishedAnimation)
              self?.callback!()
            }
        }
        self.setConstraints()
    } else {
   
      lottieAnimationView?.removeFromSuperview()
      self.callback!()
        
    }

  }
  

    
  override func viewWillDisappear(_ animated: Bool) {
    // remove the sdk view on exiting by calling the callback
      #if canImport(AmaniVoiceAssistantSDK)
      
          Task { @MainActor in
            do {
              try? await AmaniUI.sharedInstance.voiceAssistant?.stop()
            }catch(let error) {
              debugPrint("\(error)")
            }
            
          }
        
        
      #endif
    print("Container View disappear")
//    cleanupViews()
    if let disappearCb = self.disappearCallback {
      disappearCb()
    }
      isDissapeared = true
    super.viewWillDisappear(animated)
  }

}
extension ContainerViewController {
   
  @objc func actBtnContinue(_ sender: UIButton) {
    print("LOTTIE ANIMATION STOPPED")
    self.lottieAnimationView?.stop()
  }

    func setupUI() {
      if AmaniUI.sharedInstance.isEnabledClientSideMrz {
        Amani.sharedInstance.setMRZDelegate(delegate: self)
      }
      let appConfig = try! Amani.sharedInstance.appConfig().getApplicationConfig()
      let buttonRadious = CGFloat(appConfig.generalconfigs?.buttonRadius ?? 10)
      
      self.btnContinue.translatesAutoresizingMaskIntoConstraints = false
      self.titleDescription.translatesAutoresizingMaskIntoConstraints = false
      if stepConfig?.documents?[0].versions?.count != 0 {
        self.titleDescription.text = stepConfig?.documents?[0].versions?[0].informationScreenDesc1 ?? "\(stepConfig?.documents?[0].versions?[0].steps?[0].captureDescription ?? "Click continue to take a photo within the specified area")"
      } else {
        self.titleDescription.text = stepConfig?.documents?[1].versions?[0].steps?[0].captureDescription
      }
      
     
      self.titleDescription.font = UIFont.systemFont(ofSize: 16.0, weight: .light)
      self.titleDescription.numberOfLines = 0
      self.titleDescription.lineBreakMode = .byWordWrapping
      self.titleDescription.textColor = hextoUIColor(hexString: appConfig.generalconfigs?.appFontColor ?? "#20202F")
      
      self.animationView.translatesAutoresizingMaskIntoConstraints = false
      self.animationView.backgroundColor = .clear
      
        if animationName == nil {
            self.btnContinue.isHidden = true
            self.titleDescription.isHidden = true
            self.setNavigationRightButtonPDF(text: appConfig.generalconfigs?.uploadPdf ?? "Upload PDF" ,tintColor: appConfig.generalconfigs?.topBarFontColor ?? "20202F")
          self.setNavigationLeftButton(TintColor: appConfig.generalconfigs?.topBarFontColor ?? "#ffffff")
        } else {
            self.btnContinue.isHidden = false
            self.titleDescription.isHidden = false
            self.setNavigationLeftButton(TintColor: appConfig.generalconfigs?.topBarFontColor ?? "#ffffff")
            btnContinue.backgroundColor = hextoUIColor(hexString: appConfig.generalconfigs?.primaryButtonBackgroundColor ?? ThemeColor.primaryColor.toHexString())
            btnContinue.layer.borderColor = hextoUIColor(hexString: appConfig.generalconfigs?.primaryButtonBorderColor ?? "#263B5B").cgColor
            btnContinue.setTitle(appConfig.generalconfigs?.continueText, for: .normal)
            btnContinue.setTitleColor(hextoUIColor(hexString: appConfig.generalconfigs?.primaryButtonTextColor ?? ThemeColor.whiteColor.toHexString()), for: .normal)
            btnContinue.tintColor = hextoUIColor(hexString: appConfig.generalconfigs?.primaryButtonTextColor ?? ThemeColor.whiteColor.toHexString())
            btnContinue.addCornerRadiousWith(radious: buttonRadious)
            
        }

      // Navigation Bar
      self.setNavigationBarWith(title: docStep?.captureTitle ?? "", textColor: hextoUIColor(hexString: appConfig.generalconfigs?.topBarFontColor ?? "ffffff"))

      self.view.backgroundColor = hextoUIColor(hexString: appConfig.generalconfigs?.appBackground ?? "#263B5B")
      
      
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
  
  private func lottieInit(name: String, completion: @escaping (_ finishedAnimation: Int) -> ()) {
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
          lottieAnimationView.backgroundColor = .clear
          lottieAnimationView.contentMode = .scaleAspectFit
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
                animationView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 64),
                animationView.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor),
                animationView.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor),
                animationView.bottomAnchor.constraint(equalTo: btnContinue.topAnchor, constant: -32),
                
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
    

    
    private func setConstraints() {
        DispatchQueue.main.async { [self] in
            view.addSubview(titleDescription)
            view.addSubview(btnContinue)
            
            NSLayoutConstraint.activate([
                titleDescription.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
                titleDescription.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
                titleDescription.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
                
                btnContinue.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
                btnContinue.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
                btnContinue.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
                btnContinue.heightAnchor.constraint(equalToConstant: 50),

            ])
        }
      
    }
}



extension ContainerViewController: mrzInfoDelegate {
  func mrzInfo(_ mrz: AmaniSDK.MrzModel?, documentId: String?) {
    print("MRZ INFO DELEGATE'E GELDI")
    if let mrzData = mrz {
      var isReady: Bool = false
      switch AmaniUI.sharedInstance.apiVersion {
      case .v1:
        isReady = true
      case .v2:
        if AmaniUI.sharedInstance.isEnabledClientSideMrz {
          isReady = true
        }
      default:
        break
      }
      
      if isReady {
        AmaniUI.sharedInstance.nviData = NviModel(mrzModel: mrzData)
      }
    } else {
//      DispatchQueue.main.async {
//        var actions: [(String, UIAlertAction.Style)] = []
//        
//        let title = self.appConfig?.generalconfigs?.tryAgainText
//        let buttonTitle = self.appConfig?.generalconfigs?.okText
//        let message = self.documentVersion?.mrzReadErrorText
//        
//        actions.append(("\(buttonTitle ?? "Re-try")", UIAlertAction.Style.default))
//        
//        AlertDialogueUtility.shared.showAlertWithActions(vc: self, title: title, message: message, actions: actions) { index in
//          if index == 0 {
//            self.dismissAnimationView()
//            self.popViewController()
//          }
//        }
//      }
      
    }
  }
}
