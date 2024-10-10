//
//  PhoneOTPView.swift
//  AmaniUI
//
//  Created by Deniz Can on 26.12.2023.
//

import Foundation
import UIKit
import Combine
import AmaniSDK
#if canImport(AmaniLocalization)
import AmaniLocalization
#endif

class PhoneOTPView: UIView {
  
  private var cancellables = Set<AnyCancellable>()
  private var viewModel: PhoneOTPViewModel!
  private var completion: (() -> Void)? = nil
    
  var selectCountryButtonAction: (() -> Void)?
  var dialCodeDecimal = Int()
  var appConfig: AppConfigModel? {
        didSet {
            guard let config = appConfig else { return }
            setupUI()
            setupErrorHandling()
        }
    }

  private lazy var descriptionText: UILabel = {
    let label = UILabel()
    label.text = "We will send a ‘one time PIN’ to your phone number for verification"
    label.font = UIFont.systemFont(ofSize: 16.0, weight: .light)
    label.numberOfLines = 2
    label.textColor = UIColor(hexString: "#20202F")
    
    return label
  }()
  
  private lazy var phoneLegend: UILabel = {
    let label = UILabel()
    label.text = "Phone Number"
    label.textColor = UIColor(hexString: "#20202F")
    label.font = UIFont.systemFont(ofSize: 14.0, weight: .regular)
    label.numberOfLines = 1
    label.setContentCompressionResistancePriority(.required, for: .vertical)
    return label
  }()
  
    lazy var phoneInput: RoundedTextInput = {
    let input = RoundedTextInput(
      placeholderText: "Enter your phone here",
      borderColor: UIColor(hexString: "#515166"),
      placeholderColor: UIColor(hexString: "#C0C0C0"),
      isPasswordToggleEnabled: false,
      keyboardType: .phonePad
      
    )
        if appConfig?.generalconfigs?.language == "ar" {
          input.field.textAlignment = .right
        }
        
        input.field.text = "+1"
        
    return input
  }()
    
    lazy var selectCountryView: UIView = {
        let countryView = UIView()
        countryView.backgroundColor = UIColor(hexString: "#D9D9D9")
        countryView.layer.cornerRadius = 25
        countryView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]

        let countryFlag = UILabel()
        countryFlag.text = "🇺🇸"
        countryFlag.translatesAutoresizingMaskIntoConstraints = false

        let arrowImage = UIImageView()
        arrowImage.image = UIImage(named: "Polygon")
        arrowImage.translatesAutoresizingMaskIntoConstraints = false
        
        countryView.addSubview(arrowImage)
        countryView.addSubview(countryFlag)
        NSLayoutConstraint.activate([
            countryFlag.leadingAnchor.constraint(equalTo: countryView.leadingAnchor, constant: 8),
            countryFlag.centerYAnchor.constraint(equalTo: countryView.centerYAnchor),

            arrowImage.leadingAnchor.constraint(equalTo: countryFlag.trailingAnchor, constant: 8),
            arrowImage.trailingAnchor.constraint(equalTo: countryView.trailingAnchor, constant: -8),
            arrowImage.centerYAnchor.constraint(equalTo: countryView.centerYAnchor),
            arrowImage.heightAnchor.constraint(equalToConstant: 24),
        ])

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(selectCountryButtonTapped))
        countryView.addGestureRecognizer(tapGesture)
        return countryView
    }()



    
  private lazy var submitButton: RoundedButton = {
    let button = RoundedButton(
//        withTitle: appConfig?.stepConfig?[2].documents?[0].versions?[0].steps?[0].captureTitle ?? "Verify Phone Number",
        withTitle: appConfig?.generalconfigs?.continueText ?? "Continue",
      withColor: UIColor(hexString: appConfig?.generalconfigs?.primaryButtonBackgroundColor ?? "#EA3365")
    )
    return button
  }()
    
    private lazy var phoneInputView: UIStackView = {
        let inputView = UIView()
        phoneInput.addSubview(selectCountryView)
        inputView.addSubview(phoneInput)
        
        selectCountryView.translatesAutoresizingMaskIntoConstraints = false
        phoneInput.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            selectCountryView.leadingAnchor.constraint(equalTo: phoneInput.leadingAnchor),
            selectCountryView.topAnchor.constraint(equalTo: phoneInput.topAnchor),
            selectCountryView.bottomAnchor.constraint(equalTo: phoneInput.bottomAnchor),
            selectCountryView.widthAnchor.constraint(equalToConstant: 66),
            
            phoneInput.leadingAnchor.constraint(equalTo: inputView.leadingAnchor),
            phoneInput.topAnchor.constraint(equalTo: inputView.topAnchor),
            phoneInput.bottomAnchor.constraint(equalTo: inputView.bottomAnchor),
            phoneInput.trailingAnchor.constraint(equalTo: inputView.trailingAnchor),
            
            phoneInput.field.leadingAnchor.constraint(equalTo: inputView.leadingAnchor, constant: 70),
            phoneInput.field.topAnchor.constraint(equalTo: inputView.topAnchor),
            phoneInput.field.bottomAnchor.constraint(equalTo: inputView.bottomAnchor),
            phoneInput.field.trailingAnchor.constraint(equalTo: inputView.trailingAnchor)
        ])
        
        let stackView = UIStackView(arrangedSubviews: [inputView])
        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.alignment = .center
        stackView.spacing = 4.0
        
        return stackView
    }()

  
  private lazy var formView: UIStackView = {
    let stackView = UIStackView(arrangedSubviews: [
      phoneLegend, phoneInputView
    ])
    
    stackView.axis = .vertical
    stackView.distribution = .fill
    stackView.spacing = 6.0
    return stackView
  }()
  
  private lazy var mainStackView: UIStackView = {
    let stackView = UIStackView(arrangedSubviews: [
      descriptionText,
      formView,
      submitButton,
    ])
    
    stackView.axis = .vertical
    stackView.distribution = .fill
    stackView.spacing = 0.0
    
    stackView.setCustomSpacing(80.0, after: descriptionText)
    stackView.setCustomSpacing(150.0, after: formView)
    
    
    return stackView
  }()
  
  override init(frame: CGRect) {
    super.init(frame: frame)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  deinit {
    NotificationCenter.default.removeObserver(
      self,
      name: NSNotification.Name(
        AppConstants.AmaniDelegateNotifications.onError.rawValue
      ),
      object: nil
    )
  }
  
  func setupUI() {
    mainStackView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(mainStackView)
    NSLayoutConstraint.activate([
      mainStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
      mainStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
      mainStackView.topAnchor.constraint(equalTo: topAnchor),
      mainStackView.bottomAnchor.constraint(equalTo: bottomAnchor)
    ])
  }
  
  func bind(
    withViewModel viewModel: PhoneOTPViewModel,
    withDocument document: DocumentVersion?
  ) {
    phoneInput.setDelegate(delegate: self)
    
    phoneInput.textPublisher
      .assign(to: \.phone, on: viewModel)
      .store(in: &cancellables)
    
    viewModel.isEmailValidPublisher
      .sink(receiveValue: { [weak self] isValidEmail in
          if !isValidEmail || self?.phoneInput.field.text == "" {
              let message = self?.appConfig?.stepConfig?[2].documents?[0].versions?[0].invalidPhoneNumberError
            #if canImport(AmaniLocalization)
            self?.phoneInput.showError(message: AmaniLocalization.localizedString(forKey: "PHONE_INVALIDPHONENUMBERERROR"))
            #else
            self?.phoneInput.showError(message: message ?? "This phone number is wrong")
            #endif
        } else {
          self?.phoneInput.hideError()
        }
      }).store(in: &cancellables)
    
    viewModel.$state
      .sink { [weak self] state in
        switch state {
        case .loading:
          self?.submitButton.showActivityIndicator()
        case .success:
          DispatchQueue.main.async {
            if let completion = self?.completion {
              completion()
            }
          }
          self?.submitButton.hideActivityIndicator()
        case .failed:
          self?.submitButton.hideActivityIndicator()
        case .none:
          break
        }
      }
      .store(in: &cancellables)
    
    submitButton.bind {
      viewModel.submitPhoneForOTP()
    }
    
    self.viewModel = viewModel
    if let doc = document {
      setTextsFrom(document: doc)
    }
  }
  
  func setCompletion(handler: @escaping () -> Void) {
    self.completion = handler
  }
  
  func setupErrorHandling() {
    NotificationCenter.default.addObserver(self, selector: #selector(didReceiveError(_:)), name: Notification.Name(AppConstants.AmaniDelegateNotifications.onError.rawValue), object: nil)
  }
    
    @objc func selectCountryButtonTapped() {
        selectCountryButtonAction?()
        }
  
  @objc func didReceiveError(_ notification: Notification) {
    //                                            type, errors
    if let errorObjc = notification.object as? [String: Any] {
      let type = errorObjc["type"] as! String
      let errors = errorObjc["errors"] as! [[String: String]]
      if (type == "customer_error") {
        if let errorMessageJson = errors.first?["errorMessage"] {
          if let detail = try? JSONDecoder()
            .decode(
              [String: String].self,
              from: errorMessageJson.data(using: .utf8)!
            ) {
            let message = detail["detail"]
            DispatchQueue.main.async {
              self.phoneInput.showError(message: message!)
            }
          }
        } else {
          DispatchQueue.main.async {
            self.phoneInput.showError(message: "There is a problem with this phone number")
          }
        }
      }
    }
  }
  
  private func setTextsFrom(document: DocumentVersion) {
    if let step = document.steps?.first {
      // FIXME: No button text
      DispatchQueue.main.async {
      #if canImport(AmaniLocalization)
        self.submitButton.titleLabel?.text = document.nextButtonText
        self.descriptionText.text = AmaniLocalization.localizedString(forKey: "PHONE_CAPTUREDESCRIPTION")
        self.phoneLegend.text = AmaniLocalization.localizedString(forKey: "PHONE_PHONEHINT")
      #else
        self.submitButton.titleLabel?.text = document.nextButtonText
        self.descriptionText.text = step.captureDescription
        self.phoneLegend.text = document.phoneHint
      #endif
      }
    }
  }
  
}

extension PhoneOTPView: UITextFieldDelegate {
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    viewModel.submitPhoneForOTP()
    phoneInput.field.resignFirstResponder()
      return true
  }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let currentText = textField.text,
              let textRange = Range(range, in: currentText) else {
            return true
        }
        
        let updatedText = currentText.replacingCharacters(in: textRange, with: string)
        
        if appConfig?.generalconfigs?.language == "ar" {
             textField.textAlignment = .right
         } else {
             textField.textAlignment = .left
         }
        
        if string.isEmpty && range.location < phoneInput.field.text?.count ?? 0 {
            // Ensure the dial code and subsequent digit(s) remain intact
            if let dialCode = phoneInput.field.text?.prefix(dialCodeDecimal + 1), !updatedText.hasPrefix(dialCode) {
//                textField.text = "\(dialCode)\(updatedText)"
                return false
            }
        }
        return true
    }
}
