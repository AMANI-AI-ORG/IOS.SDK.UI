import AmaniSDK
import UIKit

class SuccessViewController: BaseViewController {
    private var stackView = UIStackView()
    private var approveImage = UIImageView()
    private var labelContainerView = UIView()
    private var headerLabel = UILabel()
    private var info1TextLabel = UILabel()
    private var info2TextLabel = UILabel()
    private var continueButton = UIButton()
    private var amaniLogo = UIImageView()
    
  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
    
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(true)

     
#if canImport(AmaniVoiceAssistantSDK)
    
        Task { @MainActor in
          do {
            try? await AmaniUI.sharedInstance.voiceAssistant?.play(key: "VOICE_SUCCESS")
          }catch(let error) {
            debugPrint("\(error)")
          }
          
        }
#endif

  }
  
  override func popViewController() {
    AmaniUI.sharedInstance.closeAmaniSDK()
    navigationController?.dismiss(animated: true, completion: nil)
  }
    
  @objc func continueBtnAction(_ sender: UIButton) {
        let customer = Amani.sharedInstance.customerInfo().getCustomer()
        guard let customerId: String = customer.id else { return }
        AmaniUI.sharedInstance.delegate?.onKYCSuccess(CustomerId: customerId)
        AmaniUI.sharedInstance.closeAmaniSDK()

        navigationController?.dismiss(animated: true, completion: nil)
  }

}

extension SuccessViewController {
    private func setupUI() {
      let generalConfig = try? Amani.sharedInstance.appConfig().getApplicationConfig().generalconfigs
      let textColor = generalConfig?.appFontColor ?? "ffffff"
      
      self.stackView.translatesAutoresizingMaskIntoConstraints = false
      self.stackView.alignment = .center
      self.stackView.axis = .vertical
      self.stackView.distribution = .fill
      self.stackView.contentMode = .scaleToFill
      self.stackView.spacing = 8
      
      
      self.labelContainerView.translatesAutoresizingMaskIntoConstraints = false
      
      self.approveImage.image = UIImage(systemName: "checkmark.circle")
      self.approveImage.translatesAutoresizingMaskIntoConstraints = false
      self.approveImage.contentMode = .scaleAspectFit
      self.approveImage.clipsToBounds = true
      self.approveImage.tintAdjustmentMode = .normal
      self.approveImage.tintColor = hextoUIColor(hexString: "#6FF7D1")
      
      
      self.headerLabel.translatesAutoresizingMaskIntoConstraints = false
      self.headerLabel.font = UIFont.systemFont(ofSize: 20.0, weight: .bold)
      self.headerLabel.textAlignment = .center
      self.headerLabel.numberOfLines = 0
      self.headerLabel.textColor = .black
      
      self.info1TextLabel.translatesAutoresizingMaskIntoConstraints = false
      self.info1TextLabel.font = UIFont.systemFont(ofSize: 17.0, weight: .light)
      self.info1TextLabel.textAlignment = .center
      self.info1TextLabel.numberOfLines = 0
      self.info1TextLabel.textColor = .black
      
      self.info2TextLabel.translatesAutoresizingMaskIntoConstraints = false
      self.info2TextLabel.font = UIFont.systemFont(ofSize: 17.0, weight: .light)
      self.info2TextLabel.textAlignment = .center
      self.info2TextLabel.numberOfLines = 0
      self.info2TextLabel.textColor = .black
      
      self.continueButton.translatesAutoresizingMaskIntoConstraints = false
      
      self.amaniLogo = UIImageView(image: UIImage(named: "ic_poweredBy", in: AmaniUI.sharedInstance.getBundle(), with: nil)?.withRenderingMode(.alwaysTemplate))
      self.amaniLogo.translatesAutoresizingMaskIntoConstraints = false
      self.amaniLogo.contentMode = .scaleAspectFit
      self.amaniLogo.clipsToBounds = true
      self.amaniLogo.tintAdjustmentMode = .normal
      
      setNavigationBarWith(title: generalConfig?.successTitle ?? "Adımları Tamamladınız", textColor: hextoUIColor(hexString: textColor))
      setNavigationLeftButton(TintColor: textColor)
      continueButton.setTitleColor(hextoUIColor(hexString: generalConfig?.primaryButtonTextColor ?? ThemeColor.whiteColor.toHexString()), for: .normal)
      continueButton.backgroundColor = hextoUIColor(hexString: generalConfig?.primaryButtonBackgroundColor ?? ThemeColor.whiteColor.toHexString())
      continueButton.addCornerRadiousWith(radious: CGFloat(generalConfig?.buttonRadius ?? 10))
      amaniLogo.isHidden = generalConfig?.hideLogo ?? false
      amaniLogo.tintColor = hextoUIColor(hexString: textColor)
      continueButton.setTitle(generalConfig?.continueText, for: .normal)
        continueButton.backgroundColor = hextoUIColor(hexString: generalConfig?.primaryButtonBackgroundColor ?? "#EA3365")
        continueButton.layer.cornerRadius = 25
      headerLabel.textColor = hextoUIColor(hexString: textColor)
      info1TextLabel.textColor = hextoUIColor(hexString: textColor)
      info2TextLabel.textColor = hextoUIColor(hexString: textColor)
      headerLabel.text = generalConfig?.successHeaderText ?? "Tebrikler"
      info1TextLabel.text = generalConfig?.successInfo1Text ?? "Bütün adımları tamamladınız."
      info2TextLabel.text = generalConfig?.successInfo2Text ?? "Evraklarınızı kontrol edip başvurunuzu değerlendireceğiz."
      continueButton.addTarget(self, action: #selector(continueBtnAction(_:)), for: .touchUpInside)
      
      setConstraints()
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
