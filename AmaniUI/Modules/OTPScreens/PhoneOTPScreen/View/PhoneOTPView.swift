//
//  PhoneOTPView.swift
//  AmaniUI
//
//  Created by Deniz Can on 26.12.2023.
//

import Foundation
import UIKit
import Combine

class PhoneOTPView: UIView {
  
  private var cancellables = Set<AnyCancellable>()
  private var viewModel: PhoneOTPViewModel!
  
  private lazy var titleText: UILabel = {
    let label = UILabel()
    label.text = "Verify Phone Number"
    label.font = UIFont.systemFont(ofSize: 20.0, weight: .bold)
    label.textColor = UIColor(hexString: "#20202F")
    return label
  }()
  
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
  
  private lazy var phoneInput: RoundedTextInput = {
    let input = RoundedTextInput(
      placeholderText: "Enter your phone here",
      borderColor: UIColor(hexString: "#515166"),
      placeholderColor: UIColor(hexString: "#C0C0C0"),
      isPasswordToggleEnabled: false,
      keyboardType: .emailAddress
    )
    return input
  }()
  
  private lazy var submitButton: RoundedButton = {
    let button = RoundedButton(
      withTitle: "Continue",
      withColor: UIColor(hexString: "#EA3365")
    )
    return button
  }()
  
  private lazy var formView: UIStackView = {
    let stackView = UIStackView(arrangedSubviews: [
      phoneLegend, phoneInput
    ])
    
    stackView.axis = .vertical
    stackView.distribution = .fill
    stackView.spacing = 6.0
    return stackView
  }()
  
  private lazy var mainStackView: UIStackView = {
    let stackView = UIStackView(arrangedSubviews: [
      titleText,
      descriptionText,
      formView,
      submitButton,
    ])
    
    stackView.axis = .vertical
    stackView.distribution = .fill
    stackView.spacing = 0.0
    
    stackView.setCustomSpacing(16.0, after: titleText)
    stackView.setCustomSpacing(80.0, after: descriptionText)
    stackView.setCustomSpacing(150.0, after: formView)
    
    
    return stackView
  }()
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    setupUI()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
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
  
  func bind(withViewModel viewModel: PhoneOTPViewModel) {
    phoneInput.setDelegate(delegate: self)
    
    phoneInput.textPublisher
      .assign(to: \.phone, on: viewModel)
      .store(in: &cancellables)
    
    viewModel.isEmailValidPublisher
      .sink(receiveValue: { [weak self] isValidEmail in
        if !isValidEmail {
          self?.phoneInput.showError(message: "This email Address is wrong")
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
          // TODO: Navigate to CheckEmailScreen
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
  }
  
  func setSubmitButtonHandler(handler: @escaping () -> Void) {
    submitButton.bind {
      handler()
    }
  }
  
}

extension PhoneOTPView: UITextFieldDelegate {
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    viewModel.submitPhoneForOTP()
    phoneInput.field.resignFirstResponder()
    return true
  }
}