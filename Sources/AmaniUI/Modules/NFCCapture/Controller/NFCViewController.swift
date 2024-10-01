import AmaniSDK
import UIKit
#if canImport(AmaniLocalization)
import AmaniLocalization
#endif

typealias VoidCallback = () -> Void

@available(iOS 13, *)
class NFCViewController: BaseViewController {
    // MARK: Properties
    private var headerLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 22.0, weight: .bold)
        label.textAlignment = .center
        label.textColor = .black
        return label
    }()
    
    private var continueButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitleColor(.white, for: .normal)
        
        return button
    }()
    
    private var labelsContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var desc1Label: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 17.0, weight: .light)
        label.textAlignment = .center
        label.textColor = .black
        return label
    }()
    
    private lazy var desc2Label: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 17.0, weight: .light)
        label.textAlignment = .center
        label.textColor = .black
        return label
    }()
    
    private lazy var desc3Label: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 17.0, weight: .light)
        label.textAlignment = .center
        label.textColor = .black
        return label
    }()
    
    private lazy var amaniLogo: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "ic_poweredBy", in: AmaniUI.sharedInstance.getBundle(), with: nil)?.withRenderingMode(.alwaysTemplate))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.tintAdjustmentMode = .normal
        
        return imageView
    }()
    
    private var documentVersion: DocumentVersion?
    private var onFinishCallback: VoidCallback?
    
    let idCaptureModule =  Amani.sharedInstance.IdCapture()
    let amani:Amani = Amani.sharedInstance
    var isDone: Bool = false
    let isVoiceAssistantEnabled = AmaniUI.sharedInstance.getVoiceAssistantValue()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        Task { @MainActor in
            setConstraints()
            await initialSetup()
            
            continueButton.addTarget(self, action: #selector(continueButtonPressed(_:)), for: .touchUpInside)
        }
        
    }
    
    func initialSetup() async {
        guard let documentVersion = documentVersion else { return }
        
        let generalConfigs = try? amani.appConfig().getApplicationConfig().generalconfigs
        
        let navFontColor = generalConfigs?.topBarFontColor ?? "ffffff"
        let textColor = generalConfigs?.appFontColor ?? "ffffff"
      
      #if canImport(AmaniLocalization)
      setNavigationBarWith(title: AmaniLocalization.localizedString(forKey: "nf_nfcTitle"), textColor: UIColor(hexString: navFontColor))
      headerLabel.text = AmaniLocalization.localizedString(forKey: "nf_nfcTitle")
      desc1Label.text = AmaniLocalization.localizedString(forKey: "nf_nfcDescription1")
      desc2Label.text = AmaniLocalization.localizedString(forKey: "nf_nfcDescription2")
      desc3Label.text = AmaniLocalization.localizedString(forKey: "nf_nfcDescription3")
      continueButton.setTitle(AmaniLocalization.localizedString(forKey: "general_continueText"), for: .normal)
      if isVoiceAssistantEnabled!{
        VoiceAssistant.shared.speakManager(text: AmaniLocalization.localizedString(forKey: "voice_nfc"), language: AmaniLocalization.selectedLanguage)
      }
      #else
      setNavigationBarWith(title: (documentVersion.nfcTitle)!, textColor: UIColor(hexString: navFontColor))
      headerLabel.text = documentVersion.nfcTitle
      desc1Label.text = documentVersion.nfcDescription1
      desc2Label.text = documentVersion.nfcDescription2
      desc3Label.text = documentVersion.nfcDescription3
      continueButton.setTitle(generalConfigs?.continueText ?? "Devam", for: .normal)
      #endif
        
        setNavigationLeftButton(TintColor: navFontColor)
        amaniLogo.isHidden = generalConfigs?.hideLogo ?? false
        amaniLogo.tintColor = UIColor(hexString: textColor)
        desc1Label.textColor = UIColor(hexString: textColor)
        desc2Label.textColor = UIColor(hexString: textColor)
        desc3Label.textColor = UIColor(hexString: textColor)
        headerLabel.textColor = UIColor(hexString: textColor)
        desc1Label.numberOfLines = 0
        desc2Label.numberOfLines = 0
        desc3Label.numberOfLines = 0
        desc1Label.lineBreakMode = .byWordWrapping
        desc2Label.lineBreakMode = .byWordWrapping
        desc3Label.lineBreakMode = .byWordWrapping
        
        continueButton.alpha = 1
        continueButton.isEnabled = true
        continueButton.setTitleColor(UIColor(hexString: generalConfigs?.primaryButtonTextColor ?? ThemeColor.whiteColor.toHexString()), for: .normal)
        continueButton.backgroundColor = UIColor(hexString: generalConfigs?.primaryButtonBackgroundColor ?? ThemeColor.whiteColor.toHexString())
        continueButton.addCornerRadiousWith(radious: CGFloat(generalConfigs?.buttonRadius ?? 10))
        await scanNFC()
    }
    
    func bind(documentVersion: DocumentVersion, callback: @escaping VoidCallback) {
        self.documentVersion = documentVersion
        self.onFinishCallback = callback
    }
    
    
    @objc func continueButtonPressed(_ sender: Any) {
        Task { @MainActor in
            await scanNFC()
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
            self.doNext(done: isDone)
            
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
            
            continueButton.widthAnchor.constraint(equalToConstant: 333),
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
