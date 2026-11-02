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

class EmailOTPView: UIView {
  //MARK: Properties
  private var descriptionText = UILabel()
  private var emailLegend = UILabel()
  private var emailInput = RoundedTextInput()
  private var submitButton = RoundedButton()
  private var formView = UIStackView()
  private var mainStackView = UIStackView()
  
  
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
    
    self.descriptionText.text = "We will send you a ‘one time PIN’ to reset your password"
    self.descriptionText.font = UIFont.systemFont(ofSize: 16.0, weight: .light)
    self.descriptionText.numberOfLines = 2
    self.descriptionText.textColor = hextoUIColor(hexString: "#20202F")
    
    
    self.emailLegend.text = "Email Adress"
    self.emailLegend.textColor = hextoUIColor(hexString: "#20202F")
    self.emailLegend.font = UIFont.systemFont(ofSize: 14.0, weight: .regular)
    self.emailLegend.numberOfLines = 1
    self.emailLegend.setContentCompressionResistancePriority(.required, for: .vertical)
    
    self.emailInput = RoundedTextInput(
      placeholderText: "Enter your email address here",
      borderColor: hextoUIColor(hexString: "#515166"),
      placeholderColor: hextoUIColor(hexString: "#C0C0C0"),
      isPasswordToggleEnabled: false,
      keyboardType: .emailAddress
    )
    
    self.submitButton = RoundedButton(
      withTitle: appConfig?.generalconfigs?.continueText ?? "Continue",
      withColor: hextoUIColor(hexString: appConfig?.generalconfigs?.primaryButtonBackgroundColor ?? "#EA3365")
    )
    
    self.formView = UIStackView(arrangedSubviews: [
      emailLegend, emailInput
    ])
    
    self.formView.axis = .vertical
    self.formView.distribution = .fill
    self.formView.spacing = 6.0
    
    self.mainStackView = UIStackView(arrangedSubviews: [
      descriptionText,
      formView,
      submitButton,
    ])
    
    self.mainStackView.axis = .vertical
    self.mainStackView.distribution = .fill
    self.mainStackView.spacing = 0.0
    
    self.mainStackView.setCustomSpacing(80.0, after: descriptionText)
    self.mainStackView.setCustomSpacing(150.0, after: formView)
    
    
    setConstraints()
  }
  
  private func setConstraints() {
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
    // `document` is already the resolved DocumentVersion for this OTP step, and carries its own
    // invalidEmailError — no need to re-derive it via a hardcoded stepConfig array index.
    let invalidEmailMessage = document?.invalidEmailError

    emailInput.textPublisher
      .assign(to: \.email, on: viewModel)
      .store(in: &cancellables)

    viewModel.isEmailValidPublisher
      .sink(receiveValue: { [weak self] isValidEmail in
        if !isValidEmail {
            self?.emailInput.showError(message: invalidEmailMessage ?? "This email Address is wrong")
          
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
      self.descriptionText.text = step.captureDescription
      self.emailLegend.text = document.emailTitle!
      self.emailInput.updatePlaceHolder(text: document.emailHint!, color: hextoUIColor(hexString: "#C0C0C0"))
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
