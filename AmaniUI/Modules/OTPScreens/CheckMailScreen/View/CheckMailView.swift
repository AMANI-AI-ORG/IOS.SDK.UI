//
//  CheckMailView.swift
//  AmaniStudio
//
//  Created by Deniz Can on 11.12.2023.
//

import Combine
import Foundation
import UIKit
import AmaniSDK

class CheckMailView: UIView {
  private var viewModel: CheckMailViewModel!
  private var cancellables = Set<AnyCancellable>()
  private var completionHandler: (() -> Void)!
  private var shouldShowError: Bool?
  
  private let retrySeconds = 180 // 3 minutes
  private var retryTime: Int
  private var timer: Timer?

  private var errorMessage: String!
  
  // MARK: Info Section
  private lazy var titleDescription: UILabel = {
    let label = UILabel()
    label.font = UIFont.systemFont(ofSize: 16.0, weight: .light)
    label.text = "Please check your inbox and enter the OTP (One Time PIN) you received"
    label.numberOfLines = 2
    label.lineBreakMode = .byTruncatingMiddle
    label.textColor = UIColor(hexString: "#20202F")
    return label
  }()

  private lazy var titleStackView: UIStackView = {
    let stackView = UIStackView(arrangedSubviews: [
      titleDescription,
    ])
    stackView.axis = .vertical
    stackView.alignment = .leading
    stackView.distribution = .equalSpacing
    stackView.spacing = 16.0
    return stackView
  }()

  // MARK: Form Area

  private lazy var otpLegend: UILabel = {
    let label = UILabel()
    label.text = "OTP (One Time PIN)"
    label.font = UIFont.systemFont(ofSize: 14.0, weight: .regular)
    label.textColor = UIColor(hexString: "#20202F")   
    return label
  }()
  
  private lazy var otpLegendRow: UIStackView = {
    let stackView = UIStackView(arrangedSubviews: [otpLegend])
    return stackView
  }()

  private lazy var otpInput: RoundedTextInput = {
    let input = RoundedTextInput(
      placeholderText: "",
      borderColor: UIColor(hexString: "#515166"),
      placeholderColor: UIColor(hexString: "#C0C0C0"),
      isPasswordToggleEnabled: false,
      keyboardType: .numberPad
    )
    return input
  }()

  // MARK: OTP Timer

  private lazy var timerButton: UIButton = {
    let button = UIButton()
    button.isEnabled = false
    return button
  }()

  private lazy var timerLabel: UILabel = {
    let label = UILabel()
    label.text = "in 03:00"
    label.font = .systemFont(ofSize: 15.0, weight: .regular)
    return label
  }()

  private lazy var timerRow: UIStackView = {
    let stackView = UIStackView(arrangedSubviews: [timerButton, timerLabel])
    stackView.axis = .horizontal
    stackView.alignment = .center
    stackView.distribution = .fillEqually
    stackView.spacing = 6.0
    return stackView
  }()

  private lazy var formStackView: UIStackView = {
    let stackView = UIStackView(arrangedSubviews: [
      otpLegendRow,
      otpInput,
      timerRow,
    ])

    stackView.axis = .vertical
    stackView.spacing = 6.0
    stackView.setCustomSpacing(32.0, after: otpInput)
    return stackView
  }()

  // MARK: Form Buttons

  let submitButton: RoundedButton = {
    let button = RoundedButton(
      withTitle: "Verify Email",
      withColor: UIColor(hexString: "#EA3365")
    )
    return button
  }()

  private lazy var mainStackView: UIStackView = {
    let stackView = UIStackView(arrangedSubviews: [
      titleStackView,
      formStackView,
      submitButton,
    ])
    stackView.axis = .vertical
    stackView.spacing = 0.0
    stackView.distribution = .fill
    stackView.setCustomSpacing(80.0, after: titleStackView)
    stackView.setCustomSpacing(84.0, after: formStackView)
    return stackView
  }()

  // MARK: Initializers
  override init(frame: CGRect) {
    retryTime = retrySeconds
    super.init(frame: frame)
    setupUI()
    startRetryTimer()
    setupErrorHandling()
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
  
  // MARK: Setup UI
  func setupUI() {
    addSubview(mainStackView)
    mainStackView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      mainStackView.topAnchor.constraint(equalTo: topAnchor),
      mainStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
      mainStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
      mainStackView.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])
    setTimerButtonDefaultStylings()
  }
  
  func startRetryTimer() {
    timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
  }

  @objc func updateTimer() {
    retryTime -= 1

    if retryTime < 0 {
      timer?.invalidate()
      retryTime = retrySeconds
      timerButton.isEnabled = true
      let attr: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 15.0, weight: .bold),
        .foregroundColor: UIColor(hexString: "#20202F"),
        .underlineStyle: NSUnderlineStyle.single.rawValue,
        .underlineColor: UIColor(hexString: "#20202F"),
      ]
      timerButton.setAttributedTitle(
        NSAttributedString(string: "Resend OTP", attributes: attr), for: .normal)
      timerButton.contentHorizontalAlignment = .center

      timerLabel.isHidden = true
    }

    let minutes = (retryTime / 60)
    let seconds = (retryTime % 60)

    timerLabel.text = String(format: "in %02d:%02d", minutes, seconds)
  }

  func bind(withViewModel viewModel: CheckMailViewModel,
            withDocument document: DocumentVersion?,
            rejectedMessage message: String = "Unable to verify profile information"
  ) {
    otpInput.setDelegate(delegate: self)

    otpInput.textPublisher
      .assign(to: \.otp, on: viewModel)
      .store(in: &cancellables)

    viewModel.isOTPValidPublisher.sink(receiveValue: { [weak self] isValidOTP in
      if !isValidOTP && (self?.shouldShowError != false) {
        self?.shouldShowError = true
        self?.otpInput.showError(message: "OTP Code is not valid")
      } else {
        self?.otpInput.hideError()
      }
    }).store(in: &cancellables)

    viewModel.$state
      .sink { [weak self] state in
        switch state {
        case .loading:
          self?.submitButton.showActivityIndicator()
        case .success:
          DispatchQueue.main.async {
            self?.completionHandler()
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
      viewModel.submitOTP()
    }
    
    timerButton.addTarget(self, action: #selector(didTapRetryButton), for: .touchUpInside)

    self.viewModel = viewModel
    
    if let doc = document {
      self.setTextsFrom(document: doc)
    }
    
    self.errorMessage = message
  }
  
  func setTimerButtonDefaultStylings(text: String? = "Resend OTP") {
    timerButton.isEnabled = false
    
    let attributes: [NSAttributedString.Key: Any] = [
      .font: UIFont.systemFont(ofSize: 15.0),
      .foregroundColor: UIColor(hexString: "#20202F", alpha: 0.5),
    ]
    
    timerButton.setAttributedTitle(
      NSAttributedString(
        string: text!,
        attributes: attributes),
      for: .normal)
    
    timerButton.contentHorizontalAlignment = .right
    timerLabel.isHidden = false
  }
  
  @objc func didTapRetryButton() {
    self.viewModel.resendOTP()
    setTimerButtonDefaultStylings()
    startRetryTimer()
  }

  func setCompletionHandler(_ handler: @escaping (() -> Void)) {
    completionHandler = handler
  }
  
  func setupErrorHandling() {
    NotificationCenter.default.addObserver(self, selector: #selector(didReceiveError(_:)), name: Notification.Name(AppConstants.AmaniDelegateNotifications.onError.rawValue), object: nil)
  }
  
  @objc func didReceiveError(_ notification: Notification) {
  //                                            type, errors
    if let errorObjc = notification.object as? [String: Any] {
      let type = errorObjc["type"] as! String
      let errors = errorObjc["errors"] as! [[String: String]]
      if (type == "OTP_error") {
        if let errorMessageJson = errors.first?["errorMessage"] {
          if let detail = try? JSONDecoder()
            .decode(
              [String: String].self,
              from: errorMessageJson.data(using: .utf8)!
            ) {
            let message = detail["detail"]
            DispatchQueue.main.async {
              self.otpInput.showError(message: message!)
            }
          }
        } else {
          DispatchQueue.main.async {
            self.otpInput.showError(message: "There is a problem with OTP Code")
          }
        }
      }
    }
  }
  
  private func setTextsFrom(document: DocumentVersion) {
    if let step = document.steps?.first {
      DispatchQueue.main.async {
        // FIXME: proper confirm button text isn't in the document version.
        self.titleDescription.text = step.confirmationDescription
        self.setTimerButtonDefaultStylings(text: document.resendOTP)
        // FIXME: Also no otp hint
//        self.otpLegend.text = document.otpHint
      }
    }
  }
  
  
}

// MARK: TextFieldDelegate

extension CheckMailView: UITextFieldDelegate {
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    viewModel.submitOTP()
    return true
  }
}
