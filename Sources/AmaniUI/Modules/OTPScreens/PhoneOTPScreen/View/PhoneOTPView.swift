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

class PhoneOTPView: UIView {
  private var entryInputView = UIView()
  private var countryFlag = UILabel()
  private var arrowImage = UIImageView()
  private var descriptionText = UILabel()
  private var phoneLegend = UILabel()
  var phoneInput = RoundedTextInput()
  var selectCountryView = UIView()
  private var submitButton = RoundedButton()
  private var phoneInputView = UIStackView()
  private var formView = UIStackView()
  private var mainStackView = UIStackView()
  
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

  override init(frame: CGRect) {
    super.init(frame: frame)
//    setupUI()
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
  override func layoutSubviews() {
    super.layoutSubviews()
    
  }
  
  func setupUI() {
      // Description Text
    descriptionText.text = "We will send a ‘one time PIN’ to your phone number for verification"
    descriptionText.font = UIFont.systemFont(ofSize: 16.0, weight: .light)
    descriptionText.numberOfLines = 2
    descriptionText.textColor = hextoUIColor(hexString: "#20202F")
    
      // Phone Legend
    phoneLegend.text = "Phone Number"
    phoneLegend.font = UIFont.systemFont(ofSize: 14.0, weight: .regular)
    phoneLegend.textColor = hextoUIColor(hexString: "#20202F")
    
      // Phone Input
    phoneInput = RoundedTextInput(
      placeholderText: "Enter your phone here",
      borderColor: hextoUIColor(hexString: "#515166"),
      placeholderColor: hextoUIColor(hexString: "#C0C0C0"),
      isPasswordToggleEnabled: false,
      keyboardType: .phonePad
    )
    
    phoneInput.field.textAlignment = appConfig?.generalconfigs?.language == "ar" ? .right : .left
    phoneInput.field.text = "+1"
    
      // Select Country View
  
    selectCountryView.backgroundColor = hextoUIColor(hexString: "#D9D9D9")
    selectCountryView.layer.cornerRadius = 25
    selectCountryView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
    
    
    countryFlag.text = "🇺🇸"
    
    arrowImage.image = UIImage(named: "Polygon", in: AmaniUI.sharedInstance.getBundle(), with: .none)
    arrowImage.contentMode = .scaleAspectFit
    arrowImage.clipsToBounds = true
    arrowImage.tintAdjustmentMode = .normal

      // Gesture Recognizer for Country Selection
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(selectCountryButtonTapped))
    selectCountryView.addGestureRecognizer(tapGesture)
    
      // Submit Button
    submitButton = RoundedButton(
      withTitle: appConfig?.generalconfigs?.continueText ?? "Continue",
      withColor: hextoUIColor(hexString: appConfig?.generalconfigs?.primaryButtonBackgroundColor ?? "#EA3365")
    )
    
    setConstraints()
  }
  
  private func setConstraints() {
    selectCountryView.translatesAutoresizingMaskIntoConstraints = false
    countryFlag.translatesAutoresizingMaskIntoConstraints = false
    arrowImage.translatesAutoresizingMaskIntoConstraints = false
   
      // StackViews
    phoneInputView.translatesAutoresizingMaskIntoConstraints = false
    phoneInputView = UIStackView(arrangedSubviews: [entryInputView])
    phoneInputView.axis = .horizontal
    phoneInputView.spacing = 4.0
    phoneInputView.distribution = .fill
    phoneInputView.alignment = .center
   
    
    formView.translatesAutoresizingMaskIntoConstraints = false
    formView = UIStackView(arrangedSubviews: [phoneLegend, phoneInputView])
    formView.axis = .vertical
    formView.spacing = 6.0
//    formView.alignment = .fill
//    formView.distribution = .fillProportionally
    
    mainStackView.translatesAutoresizingMaskIntoConstraints = false
    mainStackView = UIStackView(arrangedSubviews: [descriptionText, formView, submitButton])
    mainStackView.axis = .vertical
    mainStackView.spacing = 16.0
    mainStackView.translatesAutoresizingMaskIntoConstraints = false
    mainStackView.setCustomSpacing(80.0, after: descriptionText)
    mainStackView.setCustomSpacing(150.0, after: formView)

    formView.translatesAutoresizingMaskIntoConstraints = false
    phoneInput.translatesAutoresizingMaskIntoConstraints = false
      // Add subviews
    
    selectCountryView.addSubview(countryFlag)
    selectCountryView.addSubview(arrowImage)
    phoneInput.addSubview(selectCountryView)
    entryInputView.addSubview(phoneInput)   
    addSubview(mainStackView)
  
    NSLayoutConstraint.activate([
    
      countryFlag.leadingAnchor.constraint(equalTo: selectCountryView.leadingAnchor, constant: 8),
      countryFlag.centerYAnchor.constraint(equalTo: selectCountryView.centerYAnchor),
      
      arrowImage.leadingAnchor.constraint(equalTo: countryFlag.trailingAnchor, constant: 8),
      arrowImage.trailingAnchor.constraint(equalTo: selectCountryView.trailingAnchor, constant: -8),
      arrowImage.centerYAnchor.constraint(equalTo: selectCountryView.centerYAnchor),
      arrowImage.heightAnchor.constraint(equalToConstant: 24),
      
      selectCountryView.leadingAnchor.constraint(equalTo: phoneInput.leadingAnchor),
      selectCountryView.topAnchor.constraint(equalTo: phoneInput.topAnchor),
      selectCountryView.bottomAnchor.constraint(equalTo: phoneInput.bottomAnchor),
      selectCountryView.widthAnchor.constraint(equalToConstant: 66),
       
      phoneInput.leadingAnchor.constraint(equalTo: entryInputView.leadingAnchor),
      phoneInput.trailingAnchor.constraint(equalTo: entryInputView.trailingAnchor),
      phoneInput.topAnchor.constraint(equalTo: entryInputView.topAnchor),
      phoneInput.bottomAnchor.constraint(equalTo: entryInputView.bottomAnchor),
      phoneInput.field.leadingAnchor.constraint(equalTo: entryInputView.leadingAnchor, constant: 70),
      phoneInput.field.topAnchor.constraint(equalTo: entryInputView.topAnchor),
      phoneInput.field.bottomAnchor.constraint(equalTo: entryInputView.bottomAnchor),
      phoneInput.field.trailingAnchor.constraint(equalTo: entryInputView.trailingAnchor),
      
  
      
      mainStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
      mainStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
      mainStackView.topAnchor.constraint(equalTo: topAnchor),
      mainStackView.bottomAnchor.constraint(equalTo: bottomAnchor),
  
    ])
  }
  
  func bind(
    withViewModel viewModel: PhoneOTPViewModel,
    withDocument document: DocumentVersion?
  ) {
    phoneInput.setDelegate(delegate: self)
    // `document` is already the resolved DocumentVersion for this OTP step, and carries its own
    // invalidPhoneNumberError — no need to re-derive it via a hardcoded stepConfig array index.
    let invalidPhoneMessage = document?.invalidPhoneNumberError

    phoneInput.textPublisher
      .assign(to: \.phone, on: viewModel)
      .store(in: &cancellables)

    viewModel.isEmailValidPublisher
      .sink(receiveValue: { [weak self] isValidEmail in
          if !isValidEmail || self?.phoneInput.field.text == "" {
          self?.phoneInput.showError(message: invalidPhoneMessage ?? "This phone number is wrong")
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
        self.submitButton.titleLabel?.text = document.nextButtonText
        self.descriptionText.text = step.captureDescription
        self.phoneLegend.text = document.phoneTitle ?? document.phoneHint
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
