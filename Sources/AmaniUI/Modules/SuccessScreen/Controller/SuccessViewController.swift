import AmaniSDK
import UIKit
#if canImport(AmaniLocalization)
import AmaniLocalization
#endif

class SuccessViewController: BaseViewController {
    private lazy var stackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.alignment = .center
        stack.axis = .vertical
        stack.distribution = .fill
        stack.contentMode = .scaleToFill
        stack.spacing = 8
        return stack
    }()
    
    private lazy var approveImage: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "checkmark.circle")
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.tintAdjustmentMode = .normal
        imageView.tintColor = UIColor(hexString: "#6FF7D1")
        
        return imageView
    }()
    
    private lazy var labelContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
//        view.backgroundColor = .red
        return view
    }()
   
    private lazy var headerLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 20.0, weight: .bold)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = .black
        return label
    }()
    
    private lazy var info1TextLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 17.0, weight: .light)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = .black
        
        return label
    }()
    
    private lazy var info2TextLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 17.0, weight: .light)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = .black
        return label
    }()
    
    private lazy var continueButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var amaniLogo: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "ic_poweredBy", in: AmaniUI.sharedInstance.getBundle(), with: nil)?.withRenderingMode(.alwaysTemplate))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.tintAdjustmentMode = .normal
        
        return imageView
    }()
  
  let isVoiceAssistantEnabled = AmaniUI.sharedInstance.getVoiceAssistantValue()
    
  override func viewDidLoad() {
    super.viewDidLoad()
    initialSetup()
    setConstraints()
    continueButton.addTarget(self, action: #selector(continueBtnAction(_:)), for: .touchUpInside)
  }


  override func popViewController() {
    navigationController?.dismiss(animated: true, completion: nil)
  }
    
  @objc func continueBtnAction(_ sender: UIButton) {
        let customer = Amani.sharedInstance.customerInfo().getCustomer()
        guard let customerId: String = customer.id else { return }
        AmaniUI.sharedInstance.delegate?.onKYCSuccess(CustomerId: customerId)
        navigationController?.dismiss(animated: true, completion: nil)
  }

}

extension SuccessViewController {
    private func initialSetup() {
      let generalConfig = try? Amani.sharedInstance.appConfig().getApplicationConfig().generalconfigs
      let textColor = generalConfig?.appFontColor ?? "ffffff"
      #if canImport(AmaniLocalization)
      setNavigationBarWith(title: AmaniLocalization.localizedString(forKey: "GENERAL_SUCCESSTITLE"), textColor: UIColor(hexString: textColor))
      continueButton.setTitle(AmaniLocalization.localizedString(forKey: "GENERAL_CONTINUETEXT"), for: .normal)
      headerLabel.text = AmaniLocalization.localizedString(forKey: "GENERAL_SUCCESSHEADERTEXT")
      info1TextLabel.text = AmaniLocalization.localizedString(forKey: "GENERAL_SUCCESSINFO1TEXT")
      info2TextLabel.text = AmaniLocalization.localizedString(forKey: "GENERAL_SUCCESSINFO2TEXT")
      if isVoiceAssistantEnabled!{
        VoiceAssistant.shared.speakManager(text: AmaniLocalization.localizedString(forKey: "VOICE_SUCCESS"), language: AmaniLocalization.selectedLanguage)
      }
      #else
      setNavigationBarWith(title: generalConfig?.successTitle ?? "Adımları Tamamladınız", textColor: UIColor(hexString: textColor))
      continueButton.setTitle(generalConfig?.continueText, for: .normal)
      headerLabel.text = generalConfig?.successHeaderText ?? "Tebrikler"
      info1TextLabel.text = generalConfig?.successInfo1Text ?? "Bütün adımları tamamladınız."
      info2TextLabel.text = generalConfig?.successInfo2Text ?? "Evraklarınızı kontrol edip başvurunuzu değerlendireceğiz."
      #endif
      setNavigationLeftButton(TintColor: textColor)
      continueButton.setTitleColor(UIColor(hexString: generalConfig?.primaryButtonTextColor ?? ThemeColor.whiteColor.toHexString()), for: .normal)
      continueButton.backgroundColor = UIColor(hexString: generalConfig?.primaryButtonBackgroundColor ?? ThemeColor.whiteColor.toHexString())
      continueButton.addCornerRadiousWith(radious: CGFloat(generalConfig?.buttonRadius ?? 10))
      amaniLogo.isHidden = generalConfig?.hideLogo ?? false
      amaniLogo.tintColor = UIColor(hexString: textColor)
      continueButton.backgroundColor = UIColor(hexString: generalConfig?.primaryButtonBackgroundColor ?? "#EA3365")
      continueButton.layer.cornerRadius = 25
      headerLabel.textColor = UIColor(hexString: textColor)
      info1TextLabel.textColor = UIColor(hexString: textColor)
      info2TextLabel.textColor = UIColor(hexString: textColor)
    }
    
    private func setConstraints() {
       
            self.view.addSubview(self.stackView)
            self.stackView.addArrangedSubview(self.approveImage)
            self.stackView.addArrangedSubview(self.labelContainerView)
            self.labelContainerView.addSubviews(headerLabel, self.info1TextLabel, self.info2TextLabel)
            self.view.addSubview(continueButton)
            self.view.addSubview(amaniLogo)
            
            NSLayoutConstraint.activate([
                stackView.centerYAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.centerYAnchor),
                stackView.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor),
                stackView.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor),
                
                
                approveImage.heightAnchor.constraint(equalToConstant: 100),
                approveImage.widthAnchor.constraint(equalToConstant: 100),
                
                labelContainerView.widthAnchor.constraint(equalTo: stackView.widthAnchor, multiplier: 0.9),

                headerLabel.leadingAnchor.constraint(equalTo: labelContainerView.leadingAnchor, constant: 16),
                headerLabel.trailingAnchor.constraint(equalTo: self.labelContainerView.trailingAnchor, constant: -16),
                headerLabel.topAnchor.constraint(equalTo: self.labelContainerView.topAnchor),
                headerLabel.bottomAnchor.constraint(equalTo: self.info1TextLabel.topAnchor, constant: -24),
                
                info1TextLabel.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 24),
                info1TextLabel.leadingAnchor.constraint(equalTo: self.labelContainerView.leadingAnchor, constant: 16),
                info1TextLabel.trailingAnchor.constraint(equalTo: self.labelContainerView.trailingAnchor, constant: -16),
                info1TextLabel.bottomAnchor.constraint(equalTo: self.info2TextLabel.topAnchor, constant: -16),
                
                info2TextLabel.topAnchor.constraint(equalTo: self.info1TextLabel.bottomAnchor, constant: 16),
                info2TextLabel.leadingAnchor.constraint(equalTo: self.labelContainerView.leadingAnchor, constant: 16),
                info2TextLabel.trailingAnchor.constraint(equalTo: self.labelContainerView.trailingAnchor, constant: -16),
                info2TextLabel.bottomAnchor.constraint(equalTo: self.labelContainerView.bottomAnchor, constant: -24),
                
                continueButton.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 16),
                continueButton.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -16),
                continueButton.bottomAnchor.constraint(equalTo: amaniLogo.topAnchor, constant: -16),
                continueButton.heightAnchor.constraint(equalToConstant: 50),
                
                
                amaniLogo.widthAnchor.constraint(equalToConstant: 114),
                amaniLogo.heightAnchor.constraint(equalToConstant: 13),
                amaniLogo.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
                amaniLogo.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -30)
            
            ])
        
       
    }
}
