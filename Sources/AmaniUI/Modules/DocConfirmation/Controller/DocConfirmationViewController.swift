//
//  DocConfirmationViewController.swift
//  AmaniUIv1
//
//  Created by Deniz Can on 5.10.2022.
//

import UIKit
import AmaniSDK


class DocConfirmationViewController: BaseViewController {
  // MARK: Properties
  private var selfieImageView = UIImageView()
  private var titleLabel = UILabel()
  private var imgOuterView = UIImageView()
  private var lblView = UIView()
  private var stackView = UIStackView()
  private var tryAgainBtn = UIButton()
  private var confirmBtn = UIButton()
  private var physicalContractImageView = UIImageView()
  private var descriptionLabel = UILabel()
  private var amaniLogo = UIImageView()
  private var idImgView = UIImageView()
    
  private var ovalView: OvalOverlayView!
  let child = AnimationViewDocConfirmation()
  var stepid:Int = 0
  private var image: UIImage?
  private var confirmCallback: (() -> Void)?
  
  private var documentID: DocumentID?
  private var documentVersion: DocumentVersion?
  private var documentStep: DocumentStepModel?
  private var mrzDocumentId: String?
  private var confirmClicked:Bool = false
    
  let appConfig = try? Amani.sharedInstance.appConfig().getApplicationConfig()
  
  override func viewDidLoad() {
    super.viewDidLoad()
      let appBackground = appConfig?.generalconfigs?.appBackground
    ovalView = OvalOverlayView(bgColor: hextoUIColor(hexString: appBackground ?? "253C59"), strokeColor: hextoUIColor(hexString: "ffffff engine='xlsxwrite"), screenBounds: UIScreen.main.bounds)
    self.confirmBtn.addTarget(self, action: #selector(confirmAction(_:)), for: .touchUpInside)
    self.tryAgainBtn.addTarget(self, action: #selector(tryAgainAction(_:)), for: .touchUpInside)
    self.initialSetup()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(true)
    confirmClicked = false
  }
  
  func initialSetup() {
    let appConfig = try! Amani.sharedInstance.appConfig().getApplicationConfig()
    let buttonRadious = CGFloat(appConfig.generalconfigs?.buttonRadius ?? 10)
    
    self.selfieImageView.translatesAutoresizingMaskIntoConstraints = false
    self.selfieImageView.clipsToBounds = true
    
    self.idImgView.translatesAutoresizingMaskIntoConstraints = false
    self.idImgView.contentMode = .scaleAspectFit
    
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = false
    self.imgOuterView.translatesAutoresizingMaskIntoConstraints = false
    self.lblView.translatesAutoresizingMaskIntoConstraints = false
    self.stackView.translatesAutoresizingMaskIntoConstraints = false
    
    self.stackView.axis = .horizontal
    self.stackView.alignment = .fill
    self.stackView.distribution = .fillEqually
    self.stackView.spacing = 20
    
    self.tryAgainBtn.translatesAutoresizingMaskIntoConstraints = false
    self.tryAgainBtn.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .regular)
    
    self.confirmBtn.translatesAutoresizingMaskIntoConstraints = false
    self.confirmBtn.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .regular)
    
    self.physicalContractImageView.translatesAutoresizingMaskIntoConstraints = false
    self.physicalContractImageView.clipsToBounds = true
    
    self.descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
    self.descriptionLabel.textAlignment = .center
    self.descriptionLabel.numberOfLines = 3
    self.descriptionLabel.font = UIFont.systemFont(ofSize: 16.0, weight: .bold)
    
    self.amaniLogo = UIImageView(image: UIImage(named: "ic_poweredBy", in: AmaniUI.sharedInstance.getBundle(), with: nil)?.withRenderingMode(.alwaysTemplate))
    self.amaniLogo.translatesAutoresizingMaskIntoConstraints = false
    self.amaniLogo.contentMode = .scaleAspectFit
    self.amaniLogo.clipsToBounds = true
    self.amaniLogo.tintAdjustmentMode = .normal
    
    
    if !AmaniUI.sharedInstance.isEnabledClientSideMrz {
      Amani.sharedInstance.setMRZDelegate(delegate: self)
    }
    // Setting labels
   
    self.titleLabel.text = documentStep?.confirmationTitle ?? ""
    self.descriptionLabel.text = documentStep?.confirmationDescription ?? ""
    self.titleLabel.textColor = hextoUIColor(hexString: appConfig.generalconfigs?.appFontColor ?? "ffffff")
    self.descriptionLabel.textColor = hextoUIColor(hexString: appConfig.generalconfigs?.appFontColor ?? "ffffff")
    // Buttons corner radious
    self.tryAgainBtn.addCornerRadiousWith(radious: buttonRadious)
    self.confirmBtn.addCornerRadiousWith(radious: buttonRadious)
    // Setting titles
    self.tryAgainBtn.setTitle(appConfig.generalconfigs?.tryAgainText, for: .normal)
    self.confirmBtn.setTitle(appConfig.generalconfigs?.confirmText, for: .normal)
    // Border color for try again button
    self.tryAgainBtn.addBorder(borderWidth: 2, borderColor: hextoUIColor(hexString: appConfig.generalconfigs?.secondaryButtonBorderColor ?? ThemeColor.whiteColor.toHexString()).cgColor)
    // Title Colors
    self.tryAgainBtn.setTitleColor(hextoUIColor(hexString: appConfig.generalconfigs?.secondaryButtonTextColor ?? ThemeColor.whiteColor.toHexString()), for: .normal)
    self.confirmBtn.setTitleColor(hextoUIColor(hexString: appConfig.generalconfigs?.primaryButtonTextColor ?? ThemeColor.whiteColor.toHexString()), for: .normal)
    // Background Colors
    self.confirmBtn.backgroundColor = hextoUIColor(hexString: appConfig.generalconfigs?.primaryButtonBackgroundColor ?? ThemeColor.primaryColor.toHexString())
    if let color = appConfig.generalconfigs?.secondaryButtonBackgroundColor {
      self.tryAgainBtn.backgroundColor = hextoUIColor(hexString: color)
    }
    
    // Navigation Bar
    
    self.setNavigationBarWith(title: documentStep?.confirmationTitle ?? "", textColor: hextoUIColor(hexString: appConfig.generalconfigs?.appFontColor ?? "ffffff"))
    self.setNavigationLeftButton(TintColor: appConfig.generalconfigs?.topBarFontColor ?? "ffffff")
    
    // labels and powered by image
      amaniLogo.tintColor = hextoUIColor(hexString: appConfig.generalconfigs?.appFontColor ?? "ffffff")
      amaniLogo.isHidden = appConfig.generalconfigs?.hideLogo ?? false
    
    // Document spesific settings
    // Selfie
    if documentID == DocumentID.SE {
      titleLabel.isHidden = true
      physicalContractImageView.isHidden = true
      imgOuterView.isHidden = true
      
      selfieImageView.image = image
      selfieImageView.isHidden = false
      selfieImageView.contentMode = .scaleAspectFill
      let ovalView = OvalOverlayView(
        bgColor: hextoUIColor(hexString: appConfig.generalconfigs?.appBackground ?? "", alpha: 1),
        strokeColor: hextoUIColor(hexString: "ffffff"),
        screenBounds: UIScreen.main.bounds
      )
        self.view.addSubview(selfieImageView)
        self.view.addSubview(lblView)
        self.lblView.addSubview(descriptionLabel)
        self.setDefaultConstraints()
        selfieImageView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                selfieImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                selfieImageView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
                selfieImageView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
                selfieImageView.bottomAnchor.constraint(equalTo: lblView.bottomAnchor, constant: -63),
                
                lblView.topAnchor.constraint(equalTo: selfieImageView.bottomAnchor, constant: 63),
                lblView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
                lblView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
                lblView.bottomAnchor.constraint(equalTo: stackView.topAnchor, constant: -17.5),
                
                descriptionLabel.leadingAnchor.constraint(equalTo: lblView.leadingAnchor),
                descriptionLabel.trailingAnchor.constraint(equalTo: lblView.trailingAnchor),
                descriptionLabel.bottomAnchor.constraint(equalTo: lblView.bottomAnchor, constant: -10),
            ])
      
    }
    // Contract or Utility Bill
      else if documentID == DocumentID.CO.self || documentID == DocumentID.UB||documentID == DocumentID.IB {
      imgOuterView.isHidden = true
      self.setNavigationBarWith(title: (self.documentStep?.confirmationTitle)!)
      self.physicalContractImageView.image = image
      physicalContractImageView.isHidden = false
      titleLabel.isHidden = true
      selfieImageView.isHidden = true
      self.setDefaultConstraints()
//      self.setConstraints()
    }
      else if documentID == DocumentID.SG{
          imgOuterView.isHidden = false
          self.idImgView.image = image
          self.idImgView.backgroundColor = hextoUIColor(hexString: appConfig.generalconfigs?.appBackground ?? "#263B5B")
          
//          self.setConstraints()
        self.setNavigationBarWith(title: (self.documentStep?.captureTitle)!)
          titleLabel.isHidden = true
          selfieImageView.isHidden = true
          physicalContractImageView.isHidden = true
          descriptionLabel.isHidden = true
          idImgView.translatesAutoresizingMaskIntoConstraints = false
          idImgView.backgroundColor = .white
          descriptionLabel.removeFromSuperview()
          view.addSubview(imgOuterView)
          imgOuterView.addSubview(idImgView)
          self.setDefaultConstraints()
          NSLayoutConstraint.activate([
            imgOuterView.topAnchor.constraint(equalTo: view.topAnchor),
            imgOuterView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            imgOuterView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            imgOuterView.bottomAnchor.constraint(equalTo: stackView.topAnchor, constant: -30),

            idImgView.topAnchor.constraint(equalTo: imgOuterView.topAnchor),
            idImgView.bottomAnchor.constraint(equalTo: imgOuterView.bottomAnchor),
            idImgView.leadingAnchor.constraint(equalTo: imgOuterView.leadingAnchor),
            idImgView.trailingAnchor.constraint(equalTo: imgOuterView.trailingAnchor),
            
          ])
        self.view.layoutIfNeeded()
      }
    // For everything else
    else {
      imgOuterView.isHidden = false
      self.idImgView.image = image
      self.idImgView.backgroundColor = hextoUIColor(hexString: appConfig.generalconfigs?.appBackground ?? "#263B5B")
      self.view.layoutIfNeeded()
      titleLabel.isHidden = true
      selfieImageView.isHidden = true
      physicalContractImageView.isHidden = true
        descriptionLabel.backgroundColor = .clear
        view.addSubview(titleLabel)
        view.addSubview(imgOuterView)
        imgOuterView.addSubview(idImgView)
        view.addSubview(lblView)
        lblView.addSubview(descriptionLabel)
        self.setDefaultConstraints()
        idImgView.translatesAutoresizingMaskIntoConstraints = false
        
            NSLayoutConstraint.activate([
                
                titleLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 23),
                titleLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -23),
                titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 30),
                titleLabel.heightAnchor.constraint(equalToConstant: 30),
                titleLabel.bottomAnchor.constraint(greaterThanOrEqualToSystemSpacingBelow: imgOuterView.topAnchor, multiplier: -58.5),
                
                imgOuterView.topAnchor.constraint(greaterThanOrEqualToSystemSpacingBelow: titleLabel.bottomAnchor, multiplier: 58.5),
                imgOuterView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
                imgOuterView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
                imgOuterView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor, constant: -40),
                imgOuterView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -260),
    
                idImgView.topAnchor.constraint(equalTo: imgOuterView.topAnchor),
                idImgView.bottomAnchor.constraint(equalTo: imgOuterView.bottomAnchor),
                idImgView.leadingAnchor.constraint(equalTo: imgOuterView.leadingAnchor),
                idImgView.trailingAnchor.constraint(equalTo: imgOuterView.trailingAnchor),
                
                lblView.topAnchor.constraint(equalTo: imgOuterView.bottomAnchor, constant: 63),
                lblView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
                lblView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
                lblView.bottomAnchor.constraint(equalTo: stackView.topAnchor, constant: -17.5),
                
                descriptionLabel.leadingAnchor.constraint(equalTo: lblView.leadingAnchor),
                descriptionLabel.trailingAnchor.constraint(equalTo: lblView.trailingAnchor),
                descriptionLabel.bottomAnchor.constraint(equalTo: lblView.bottomAnchor, constant: -10),

            ])
       
    }
      
   
    
//    if let errorList = idCaptureResponseModel?.errors{
//      if !errorList.isEmpty{
//        AlertDialogueUtility.shared.showMsgAlertWithHandler(controller: self, alertTitle:  (AppConfigUtility.shared.getAppConfiguration()?.generalconfigs?.tryAgainText)!, message: errorList[0].errorMessage, successTitle: Localization.okTitle.description,success:{ _ in
//          if self.attempt ?? 3 < 2{
//            self.confirmBtn.isEnabled = false
//            self.confirmBtn.alpha = 0.6
//            self.tryAgainBtn.isEnabled = true
//            self.tryAgainBtn.alpha = 1
//            if let completion = self.nfcCompletion {
//              completion(true)
//            }
//          }
//          else{
//            self.confirmBtn.isEnabled = true
//            self.confirmBtn.alpha = 1
//            self.tryAgainBtn.isEnabled = false
//            self.tryAgainBtn.alpha = 0.6
//          }
//        })
//      }
//    }
    
  }
    
    func checkMRZ() {

            //         #warning("buraya full ekran indicator koyulacak")
            if !AmaniUI.sharedInstance.isEnabledClientSideMrz {
                createAnimationView()
                Amani.sharedInstance.IdCapture().getMrz { mrzDocumentId in
                  self.mrzDocumentId = mrzDocumentId
                  
                }
            }
    }
  
  func bind(image: UIImage, documentID: DocumentID, docVer: DocumentVersion, docStep: DocumentStepModel, stepid:Int ,callback: @escaping () -> Void) {
    self.image = image
    self.documentID = documentID
    self.documentVersion = docVer
    self.documentStep = docStep
    self.stepid = stepid
    self.confirmCallback = callback
    self.confirmClicked = false
  }
  
    
    // MARK: Button actions
    @objc func tryAgainAction(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc func confirmAction(_ sender: Any) {
        if (!confirmClicked){
          
          confirmClicked = true
          if documentVersion?.nfc ?? false{

            if (documentID == DocumentID.ID && stepid == steps.back.rawValue) ||
                (documentID == DocumentID.PA && stepid == steps.front.rawValue )  {
              checkMRZ()
            } else {
              if let confirmCallback = confirmCallback {
                confirmCallback()
              }
            }
          } else {
            if let confirmCallback = confirmCallback {
              confirmCallback()
            }
          }
        }
    }
    
    func createAnimationView() {
        // add the spinner view controller
        DispatchQueue.main.async {
          self.view.addSubview(self.child)
            self.child.frame = self.view.frame
            self.view.addSubview(self.child)
            self.view.bringSubviewToFront(self.child)
            self.child.bind(config: self.documentVersion!)

        }
    }
    
    func dismissAnimationView() {
        DispatchQueue.main.async {
            // then remove the spinner view controller
            self.child.removeFromSuperview()
        }
    }
  
}

extension DocConfirmationViewController: mrzInfoDelegate {
    func mrzInfo(_ mrz: AmaniSDK.MrzModel?, documentId: String?) {
        print("MRZ INFO DELEGATE'E GELDI")
        if let mrzData = mrz {
            var isReady: Bool = false
            switch AmaniUI.sharedInstance.apiVersion {
            case .v1:
                isReady = true
            case .v2:
                if !AmaniUI.sharedInstance.isEnabledClientSideMrz {
                    isReady = self.mrzDocumentId == documentId
                } else {
                    isReady = true
                }

            default:
                break
            }
            
            if isReady {
                AmaniUI.sharedInstance.nviData = NviModel(mrzModel: mrzData)
                if !AmaniUI.sharedInstance.isEnabledClientSideMrz {
                    dismissAnimationView()
                }
              if let confirmCallback = self.confirmCallback {
                confirmCallback()
              }
                
            }
        } else {
            DispatchQueue.main.async {
                var actions: [(String, UIAlertAction.Style)] = []
                
                let title = self.appConfig?.generalconfigs?.tryAgainText
                let buttonTitle = self.appConfig?.generalconfigs?.okText
                let message = self.documentVersion?.mrzReadErrorText
                
                actions.append(("\(buttonTitle ?? "Re-try")", UIAlertAction.Style.default))
                
                AlertDialogueUtility.shared.showAlertWithActions(vc: self, title: title, message: message, actions: actions) { index in
                    if index == 0 {
                        self.dismissAnimationView()
                        self.popViewController()
                    }
                }
            }
            
            //            let uiAlertView = AlertDialogueUtility.shared.showMsgAlertWithHandler(controller: self, alertTitle: "Failed", message: "Re-try back Image", successTitle: "OK", failureTitle: "Re try") { _ in
            //
            //            }
        }
    }
}

extension DocConfirmationViewController {
    private func setDefaultConstraints() {
            view.addSubview(stackView)
            stackView.addArrangedSubviews(tryAgainBtn, confirmBtn)
            view.addSubview(amaniLogo)
            
            NSLayoutConstraint.activate([
             
                stackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
                stackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
                stackView.bottomAnchor.constraint(equalTo: amaniLogo.topAnchor, constant: -16),
                stackView.heightAnchor.constraint(equalToConstant: 50),
                
                amaniLogo.widthAnchor.constraint(equalToConstant: 114),
                amaniLogo.heightAnchor.constraint(equalToConstant: 13),
                amaniLogo.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                amaniLogo.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -30)
                
            
            ])
            
        
    }
}
