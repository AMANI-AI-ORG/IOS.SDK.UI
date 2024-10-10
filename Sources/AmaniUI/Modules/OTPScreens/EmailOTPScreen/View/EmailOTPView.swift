//
//  EmailOTPView.swift
//  AmaniStudio
//
//  Created by Deniz Can on 10.12.2023.
//

import Foundation
import UIKit
import Combine
import AmaniSDK
#if canImport(AmaniLocalization)
import AmaniLocalization
#endif

class EmailOTPView: UIView {
  
  private var cancellables = Set<AnyCancellable>()
  private var viewModel: EmailOTPViewModel!
  private var completionHandler: (() -> Void)? = nil
//  private var emailValidationText: String? = "This email Address is wrong"
    var appConfig: AppConfigModel? {
          didSet {
              guard let config = appConfig else { return }
              setupUI()
              setupErrorHandling()
          }
      }

  private lazy var descriptionText: UILabel = {
    let label = UILabel()
    label.text = "We will send you a ‘one time PIN’ to reset your password"
    label.font = UIFont.systemFont(ofSize: 16.0, weight: .light)
    label.numberOfLines = 2
    label.textColor = UIColor(hexString: "#20202F")
    
    return label
  }()
  
  private lazy var emailLegend: UILabel = {
    let label = UILabel()
    label.text = "Email Adress"
    label.textColor = UIColor(hexString: "#20202F")
    label.font = UIFont.systemFont(ofSize: 14.0, weight: .regular)
    label.numberOfLines = 1
    label.setContentCompressionResistancePriority(.required, for: .vertical)
    return label
  }()
  
  private lazy var emailInput: RoundedTextInput = {
    let input = RoundedTextInput(
      placeholderText: "Enter your email address here",
      borderColor: UIColor(hexString: "#515166"),
      placeholderColor: UIColor(hexString: "#C0C0C0"),
      isPasswordToggleEnabled: false,
      keyboardType: .emailAddress
    )
    return input
  }()
  
  private lazy var submitButton: RoundedButton = {
    let button = RoundedButton(
    withTitle: appConfig?.generalconfigs?.continueText ?? "Continue",
    withColor: UIColor(hexString: appConfig?.generalconfigs?.primaryButtonBackgroundColor ?? "#EA3365")
    )
    return button
  }()
  
  private lazy var formView: UIStackView = {
    let stackView = UIStackView(arrangedSubviews: [
      emailLegend, emailInput
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
      name: NSNotification.Name(AppConstants.AmaniDelegateNotifications.onError.rawValue),
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
    withViewModel viewModel: EmailOTPViewModel,
    withDocument document: DocumentVersion?
  ) {
    emailInput.setDelegate(delegate: self)
    
    emailInput.textPublisher
      .assign(to: \.email, on: viewModel)
      .store(in: &cancellables)
    
    viewModel.isEmailValidPublisher
      .sink(receiveValue: { [weak self] isValidEmail in
        if !isValidEmail {
          #if canImport(AmaniLocalization)
          self?.emailInput.showError(message: AmaniLocalization.localizedString(forKey: "EMAIL_INVALIDEMAILERROR") )
          #else
          let message = self?.appConfig?.stepConfig?[1].documents?[0].versions?[0].invalidEmailError
          print(message)
          self?.emailInput.showError(message: message ?? "This email Address is wrong")
          #endif
        } else {
          self?.emailInput.hideError()
        }
      }).store(in: &cancellables)
    
    viewModel.$state
      .sink { [weak self] state in
        switch state {
        case .loading:
          self?.submitButton.showActivityIndicator()
        case .success:
          DispatchQueue.main.async {
            if let handler = self?.completionHandler {
              handler()
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
      viewModel.submitEmailForOTP()
    }
    
    self.viewModel = viewModel
    
    if let doc = document {
      setTextsFrom(document: doc)
    }
  }
  
  private func setTextsFrom(document: DocumentVersion) {
    // This view is single step, we need capture title and confirmation title for this specific screen
    let step = document.steps!.first!
    DispatchQueue.main.async {
      // FIXME: Button titles DOES NOT EXISTS in the configuration
    #if canImport(AmaniLocalization)
      self.descriptionText.text = AmaniLocalization.localizedString(forKey: "EMAIL_CAPTUREDESCRIPTION")
      self.emailLegend.text = AmaniLocalization.localizedString(forKey: "EMAIL_EMAILTITLE")
      self.emailInput.updatePlaceHolder(text: AmaniLocalization.localizedString(forKey: "EMAIL_EMAILHINT"))
    #else
      self.descriptionText.text = step.captureDescription
      self.emailLegend.text = document.emailTitle!
      self.emailInput.updatePlaceHolder(text: document.emailHint!, color: UIColor(hexString: "#C0C0C0"))
    #endif
    }
    
  }
  
  func setCompletion(handler: @escaping () -> Void) {
    self.completionHandler = handler
  }
  
  func setupErrorHandling() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(didReceiveError(_:)),
      name: Notification.Name(
        AppConstants.AmaniDelegateNotifications.onError.rawValue
      ),
      object: nil
    )
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
              self.emailInput.showError(message: message!)
            }
          }
        } else {
          DispatchQueue.main.async {
            self.emailInput.showError(message: "There is a problem with this email address")
          }
        }
      }
    }
  }
  
}

extension EmailOTPView: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        viewModel.submitEmailForOTP()
        emailInput.field.resignFirstResponder()
        return true
    }
    
//    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
//        // Get the current text in the text field
//        guard let currentText = textField.text as NSString? else { return true }
//        
//        // Construct the new text by replacing characters in the specified range
//        var newText = currentText.replacingCharacters(in: range, with: string)
//        
//        // Make the first letter lowercase
//        newText = newText.lowercasedFirstLetter()
//        
//        // Set the new text in the text field
//        textField.text = newText
//        
//        // Notify the view model about the change
//        viewModel.email = newText
//        
//        // Always return false to prevent the system from replacing the text
//        return false
//    }


}
