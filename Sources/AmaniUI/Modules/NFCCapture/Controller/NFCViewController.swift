import AmaniSDK
import UIKit

@available(iOS 13, *)
class NFCViewController: BaseViewController {

  var nfcFormView: NFCConfigureView!
    // MARK: Properties
  private var headerLabel = UILabel()
  private var continueButton = UIButton()
  private var labelsContainerView = UIView()
  private var desc1Label = UILabel()
  private var desc2Label = UILabel()
  private var desc3Label = UILabel()
  private var amaniLogo = UIImageView()
  var docID: String?
  private var documentVersion: DocumentVersion?
  private var onFinishCallback: (() -> Void)?
    
  let idCaptureModule =  Amani.sharedInstance.IdCapture()
  let amani:Amani = Amani.sharedInstance
  var isDone: Bool = false
  var maxAttempts: Int = 0
  
  var appConfig: AppConfigModel?  {
          didSet {
            guard let config = appConfig else { return }
      
      }
  }
  
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        Task { @MainActor in
//            setConstraints()
         
            await initialSetup()
            continueButton.addTarget(self, action: #selector(continueButtonPressed(_:)), for: .touchUpInside)
        }
        
    }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
#if canImport(AmaniVoiceAssistantSDK)
    Task { @MainActor in
      do {
        try? await AmaniUI.sharedInstance.voiceAssistant?.stop()
      }catch(let err) {
        debugPrint("\(err)")
      }
    }
#endif
  }
  
    func initialSetup() async {
        guard let documentVersion = documentVersion else { return }
        
      self.appConfig = try? amani.appConfig().getApplicationConfig()
        
      let navFontColor = appConfig?.generalconfigs?.topBarFontColor ?? "ffffff"
      let textColor = appConfig?.generalconfigs?.appFontColor ?? "ffffff"
      
      
      self.headerLabel.translatesAutoresizingMaskIntoConstraints = false
      self.headerLabel.font = UIFont.systemFont(ofSize: 22.0, weight: .bold)
      self.headerLabel.textAlignment = .center
      self.headerLabel.textColor = .black
      
      self.continueButton.translatesAutoresizingMaskIntoConstraints = false
      self.continueButton.setTitleColor(.white, for: .normal)
      
      self.labelsContainerView.translatesAutoresizingMaskIntoConstraints = false
      self.desc1Label.translatesAutoresizingMaskIntoConstraints = false
      self.desc1Label.font = UIFont.systemFont(ofSize: 17.0, weight: .light)
      self.desc1Label.textAlignment = .center
      self.desc1Label.textColor = .black
      
      self.desc2Label.translatesAutoresizingMaskIntoConstraints = false
      self.desc2Label.font = UIFont.systemFont(ofSize: 17.0, weight: .light)
      self.desc2Label.textAlignment = .center
      self.desc2Label.textColor = .black
      
      self.desc3Label.translatesAutoresizingMaskIntoConstraints = false
      self.desc3Label.font = UIFont.systemFont(ofSize: 17.0, weight: .light)
      self.desc3Label.textAlignment = .center
      self.desc3Label.textColor = .black
      
      self.amaniLogo = UIImageView(image: UIImage(named: "ic_poweredBy", in: AmaniUI.sharedInstance.getBundle(), with: nil)?.withRenderingMode(.alwaysTemplate))
      self.amaniLogo.translatesAutoresizingMaskIntoConstraints = false
      self.amaniLogo.contentMode = .scaleAspectFit
      self.amaniLogo.clipsToBounds = true
      self.amaniLogo.tintAdjustmentMode = .normal
        
        setNavigationBarWith(title: (documentVersion.nfcTitle)!, textColor: hextoUIColor(hexString: navFontColor))
        setNavigationLeftButton(TintColor: navFontColor)
        amaniLogo.isHidden = appConfig?.generalconfigs?.hideLogo ?? false
        amaniLogo.tintColor = hextoUIColor(hexString: textColor)
        desc1Label.textColor = hextoUIColor(hexString: textColor)
        desc2Label.textColor = hextoUIColor(hexString: textColor)
        desc3Label.textColor = hextoUIColor(hexString: textColor)
        headerLabel.textColor = hextoUIColor(hexString: textColor)
        headerLabel.text = documentVersion.nfcTitle
        desc1Label.text = documentVersion.nfcDescription1
        desc2Label.text = documentVersion.nfcDescription2
        desc3Label.text = documentVersion.nfcDescription3
        desc1Label.numberOfLines = 0
        desc2Label.numberOfLines = 0
        desc3Label.numberOfLines = 0
        desc1Label.lineBreakMode = .byWordWrapping
        desc2Label.lineBreakMode = .byWordWrapping
        desc3Label.lineBreakMode = .byWordWrapping
        
        continueButton.alpha = 1
        continueButton.isEnabled = true
        continueButton.setTitleColor(hextoUIColor(hexString: appConfig?.generalconfigs?.primaryButtonTextColor ?? ThemeColor.whiteColor.toHexString()), for: .normal)
        continueButton.backgroundColor = hextoUIColor(hexString: appConfig?.generalconfigs?.primaryButtonBackgroundColor ?? ThemeColor.whiteColor.toHexString())
        continueButton.addCornerRadiousWith(radious: CGFloat(appConfig?.generalconfigs?.buttonRadius ?? 10))
        continueButton.setTitle(appConfig?.generalconfigs?.continueText ?? "Devam", for: .normal)
      
        setConstraints()
      
       
    }
    
    func bind(documentVersion: DocumentVersion, callback: @escaping (() -> Void)) {
        self.documentVersion = documentVersion
        self.onFinishCallback = callback
    }
    
    
    @objc func continueButtonPressed(_ sender: Any) {
        Task { @MainActor in
          #if canImport(AmaniVoiceAssistantSDK)
                if let docID = self.docID {
                  do {
                    try? await AmaniUI.sharedInstance.voiceAssistant?.play(key: "VOICE_\(docID)")
                  }catch(let error) {
                    debugPrint("\(error)")
                  }
                }
                
          #endif
          maxAttempts += 1
          let sdkMaxAttemptValue = (documentVersion?.maxNfcAttempt ?? (documentVersion?.maxAttempt ?? 3))
          if maxAttempts <= sdkMaxAttemptValue {
            await scanNFC()
          } else {
            self.doNext(done: true)
          }
        }
    }
    
    func uploadNFCResult() {
        idCaptureModule.upload(location: nil) { isUploadSuccess in
            if isUploadSuccess != nil {
                self.isDone = true
                self.doNext(done: self.isDone)
            } else {
                self.isDone = false
                self.doNext(done: self.isDone)
            }
        }
        
    }
    
    func scanNFC() async {
        //    let idCaptureModule = Amani.sharedInstance.IdCapture()
        continueButton.isEnabled = false
        //    guard let nvi = AmaniUI.sharedInstance.nviData else { return }
        //    let isDone = await idCaptureModule.startNFC(nvi: nvi)
        //    self.doNext(done: isDone)
      if let nvi:NviModel = AmaniUI.sharedInstance.nviData {
            print(nvi)
            let isDone = await idCaptureModule.startNFC(nvi: nvi)
          if isDone {
            self.doNext(done: isDone)
          } else {
            continueButton.isEnabled = true
            await animateWithNFCFormUI(nvi: nvi)
          }
        }
    }
    
    func doNext(done:Bool) {
        let tryAgainText = try? Amani.sharedInstance.appConfig().getApplicationConfig().generalconfigs?.tryAgainText
        
        if done {
            DispatchQueue.main.async {
                if let onFinishCallback = self.onFinishCallback {
                    onFinishCallback()
                }
            }
        } else {
            DispatchQueue.main.async { [self] in
                continueButton.setTitle(tryAgainText ?? "Tekrar Dene", for: .normal)
                continueButton.isEnabled = true
            }
        }
    }
  
  private func setNFCFormUIView(nvi: NviModel) async {
    nfcFormView = NFCConfigureView()
    self.nfcConfigureView = nfcFormView
    nfcFormView.appConfig = appConfig
    nfcFormView.setTextsFrom(nvi: nvi)
    nfcFormView.delegate = self
    self.view.addSubview(nfcFormView)

    nfcFormView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      nfcFormView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
      nfcFormView.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor),
      nfcFormView.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor),
      nfcFormView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
      
    ])
    
    nfcFormView.setButtonCb = { [weak self] newNvi in
      guard let self = self else { return }
      nfcFormView.removeFromSuperview()
      debugPrint("nfc configure ekranından dönen nvi data : \(newNvi)")
      self.maxAttempts += 1
      let isDone = await idCaptureModule.startNFC(nvi: newNvi)
      if isDone {
        self.doNext(done: isDone)
      } else {
        if newNvi.dateOfBirth == "" || newNvi.dateOfExpire == "" || newNvi.documentNo == "" {
          await animateWithNFCFormUI(nvi: nvi)
        } else {
          await animateWithNFCFormUI(nvi: newNvi)
        }
      }
    }
  }
  private func animateWithNFCFormUI(nvi: NviModel) async {
    await animateAsync(withDuration: 0.3) { [weak self] in
      Task {
        guard let self = self else { return }
#if canImport(AmaniVoiceAssistantSDK)
        try? await AmaniUI.sharedInstance.voiceAssistant?.stop()
#endif
       
        let sdkMaxAttemptValue = (self.documentVersion?.maxNfcAttempt ?? (self.documentVersion?.maxAttempt ?? 3))
        if self.maxAttempts <= sdkMaxAttemptValue {
          await self.setNFCFormUIView(nvi: nvi)
        } else {
          self.doNext(done: true)
        }
       
      }
    }
  }
  
 private func animateAsync(withDuration duration: TimeInterval, animations: @escaping () -> Void) async {
    await withCheckedContinuation { continuation in
      UIView.animate(withDuration: duration, animations: animations) { _ in
        continuation.resume()
      }
    }
  }
}

extension NFCViewController: AlertDelegate {
  func showAlert(title: String, message: String, actions: [(String, UIAlertAction.Style)], completion: ((Int) -> Void)?) {
    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    
    for (index, action) in actions.enumerated() {
      let alertAction = UIAlertAction(title: action.0, style: action.1) { _ in
        completion?(index)
      }
      alert.addAction(alertAction)
    }
    
    self.present(alert, animated: true)
  }
  
  
}

extension NFCViewController {
    private func setConstraints() {
        
        self.view.addSubviews(headerLabel,labelsContainerView, amaniLogo, continueButton )
        labelsContainerView.addSubviews(desc1Label,desc2Label,desc3Label)
        
        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 47),
            headerLabel.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor, constant: 23),
            headerLabel.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor, constant: -23),
            headerLabel.bottomAnchor.constraint(equalTo:labelsContainerView.topAnchor, constant: -72),
            headerLabel.heightAnchor.constraint(equalToConstant: 30),
            
            labelsContainerView.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 72),
            labelsContainerView.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            labelsContainerView.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            labelsContainerView.heightAnchor.constraint(equalToConstant: 229),
            
            desc1Label.leadingAnchor.constraint(equalTo:labelsContainerView.leadingAnchor),
            desc1Label.trailingAnchor.constraint(equalTo:labelsContainerView.trailingAnchor),
            desc1Label.centerXAnchor.constraint(equalTo:labelsContainerView.centerXAnchor),
            desc1Label.heightAnchor.constraint(equalToConstant: 60),
            
            desc2Label.topAnchor.constraint(equalTo:desc1Label.bottomAnchor, constant: 20),
            desc2Label.bottomAnchor.constraint(equalTo:desc3Label.topAnchor, constant: -20),
            desc2Label.leadingAnchor.constraint(equalTo:labelsContainerView.leadingAnchor),
            desc2Label.trailingAnchor.constraint(equalTo:labelsContainerView.trailingAnchor),
            desc2Label.centerXAnchor.constraint(equalTo:labelsContainerView.centerXAnchor),
            desc2Label.centerYAnchor.constraint(equalTo:labelsContainerView.centerYAnchor),
            
            desc3Label.topAnchor.constraint(equalTo:desc2Label.bottomAnchor, constant: 20),
            desc3Label.leadingAnchor.constraint(equalTo:labelsContainerView.leadingAnchor),
            desc3Label.trailingAnchor.constraint(equalTo:labelsContainerView.trailingAnchor),
            desc3Label.centerXAnchor.constraint(equalTo:labelsContainerView.centerXAnchor),
            
//            continueButton.widthAnchor.constraint(equalToConstant: 333),
            continueButton.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            continueButton.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            continueButton.heightAnchor.constraint(equalToConstant: 50),
            continueButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            continueButton.bottomAnchor.constraint(equalTo: amaniLogo.topAnchor, constant: -20),
            
            amaniLogo.widthAnchor.constraint(equalToConstant: 114),
            amaniLogo.heightAnchor.constraint(equalToConstant: 13),
            amaniLogo.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            amaniLogo.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -30)
            
            
        ])
        
    }
}
