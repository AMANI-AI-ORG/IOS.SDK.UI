//
//  CheckSMSView.swift
//  AmaniUI
//
//  Created by Deniz Can on 26.12.2023.
//

import Foundation
import UIKit
import Combine
import AmaniSDK

class CheckSMSView: UIView {
  
    // MARK: Info Section
  private var titleDescription = UILabel()
  private var titleStackView = UIStackView()
  
    // MARK: Form Area
  private var otpLegend = UILabel()
  private var otpLegendRow = UIStackView()
  private var otpInput = RoundedTextInput()
  
    // MARK: OTP Timer
  private var timerButton = UIButton()
  private var timerLabel = UILabel()
  private var timerRow = UIStackView()
  private var formStackView = UIStackView()
  
    // MARK: Form Buttons
  private var submitButton = RoundedButton()
  private var mainStackView = UIStackView()
  
  private var viewModel: CheckSMSViewModel!
  private var cancellables = Set<AnyCancellable>()
  private var completionHandler: (() -> Void)!
  private var shouldShowError: Bool?
  
  private let retrySeconds = 120 // 2 minutes
  private var retryTime: Int
  private var timer: Timer?
  var appConfig: AppConfigModel? {
          didSet {
              guard let config = appConfig else { return }
              setupUI()
              startRetryTimer()
              setupErrorHandling()
          }
      }
  
  override init(frame: CGRect) {
    retryTime = retrySeconds
    
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
    self.titleDescription.font = UIFont.systemFont(ofSize: 16.0, weight: .light)
    self.titleDescription.text = "Please check your SMS messages and enter the OTP (One Time PIN) you received"
    self.titleDescription.numberOfLines = 2
    self.titleDescription.lineBreakMode = .byTruncatingMiddle
    self.titleDescription.textColor = hextoUIColor(hexString: "#20202F")
    
    self.titleStackView = UIStackView(arrangedSubviews: [
      titleDescription,
    ])
    self.titleStackView.axis = .vertical
    self.titleStackView.alignment = .leading
    self.titleStackView.distribution = .equalSpacing
    self.titleStackView.spacing = 16.0
    
    if appConfig?.generalconfigs?.language != "ar" {
      let captureDescriptionText = appConfig?.stepConfig?[1].documents?[0].versions?[0].steps?[0].captureDescription
      let otpLangauge = captureDescriptionText?.extractTextWithinSingleQuotes()
      self.otpLegend.text = "OTP (\(otpLangauge ?? "One time PIN"))"
    } else {
      self.otpLegend.text = "OTP (دبوس مرة واحدة)"
    }
    
    self.otpLegend.font = UIFont.systemFont(ofSize: 14.0, weight: .regular)
    self.otpLegend.textColor = hextoUIColor(hexString: "#20202F")
    
    self.otpLegendRow = UIStackView(arrangedSubviews: [otpLegend])
    
    self.otpInput = RoundedTextInput(
      placeholderText: "OTP Code",
      borderColor: hextoUIColor(hexString: "#515166"),
      placeholderColor: hextoUIColor(hexString: "#C0C0C0"),
      isPasswordToggleEnabled: false,
      keyboardType: .numberPad
    )
    
    self.timerButton.isEnabled = false
    
    self.timerLabel.text = "03:00"
    self.timerLabel.font = .systemFont(ofSize: 15.0, weight: .regular)
    
    self.timerRow = UIStackView(arrangedSubviews: [timerButton, timerLabel])
    self.timerRow.axis = .horizontal
    self.timerRow.alignment = .center
    self.timerRow.distribution = .fillProportionally
    self.timerRow.spacing = 6.0
    
    self.formStackView = UIStackView(arrangedSubviews: [
      otpLegendRow,
      otpInput,
      timerRow,
    ])
    
    self.formStackView.axis = .vertical
    self.formStackView.alignment = .center
    self.formStackView.spacing = 6.0
    self.formStackView.setCustomSpacing(32.0, after: otpInput)
    
    self.submitButton = RoundedButton(
      withTitle:  appConfig?.stepConfig?[2].documents?[0].versions?[0].steps?[0].captureTitle ?? "Verify Phone",
            withColor: hextoUIColor(hexString: appConfig?.generalconfigs?.primaryButtonBackgroundColor ?? "#EA3365")
    )
    
    self.mainStackView = UIStackView(arrangedSubviews: [
      titleStackView,
      formStackView,
      submitButton,
    ])
    self.mainStackView.axis = .vertical
    self.mainStackView.spacing = 0.0
    self.mainStackView.distribution = .fill
    self.mainStackView.setCustomSpacing(80.0, after: titleStackView)
    self.mainStackView.setCustomSpacing(84.0, after: formStackView)
    
   setConsraints()
  }
  
  private func setConsraints() {
    addSubview(mainStackView)
    mainStackView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      otpLegend.leadingAnchor.constraint(equalTo: otpInput.leadingAnchor),
      otpInput.leadingAnchor.constraint(equalTo: formStackView.leadingAnchor, constant: 4),
      otpInput.trailingAnchor.constraint(equalTo: formStackView.trailingAnchor, constant: -4),
      
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
        .foregroundColor: hextoUIColor(hexString: "#20202F"),
        .underlineStyle: NSUnderlineStyle.single.rawValue,
        .underlineColor: hextoUIColor(hexString: "#20202F"),
      ]
      timerButton.setAttributedTitle(
        NSAttributedString(string: "Resend OTP", attributes: attr), for: .normal)
      timerButton.contentHorizontalAlignment = .center
      
      timerLabel.isHidden = true
    }
    
    let minutes = (retryTime / 60)
    let seconds = (retryTime % 60)
    
    timerLabel.text = String(format: "%02d:%02d", minutes, seconds)
  }
  
  func bind(
    withViewModel viewModel: CheckSMSViewModel,
    withDocument document: DocumentVersion?
  ) {
    otpInput.setDelegate(delegate: self)
    
    otpInput.textPublisher
      .assign(to: \.otp, on: viewModel)
      .store(in: &cancellables)
    
    viewModel.isOTPValidPublisher.sink(receiveValue: { [weak self] isValidOTP in
      if !isValidOTP && (self?.shouldShowError != nil) {
        self?.shouldShowError = true
        self?.otpInput.showError(message: self?.invalidOtpMessage() ?? "OTP Code is not valid")
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
    
    
  }
  
  func setTimerButtonDefaultStylings(text: String? = "Resend OTP") {
    timerButton.isEnabled = false
    
    let attributes: [NSAttributedString.Key: Any] = [
      .font: UIFont.systemFont(ofSize: 15.0),
      .foregroundColor: hextoUIColor(hexString: "#20202F", alpha: 0.5),
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
//    NotificationCenter.default.addObserver(self, selector: #selector(didReceiveError(_:)), name: Notification.Name("ai.amani.onError"), object: nil)
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
            self.otpInput.showError(message: self.invalidOtpMessage() ?? "There is a problem with OTP Code")
          }
        }
      }
    }
  }

  private func invalidOtpMessage() -> String? {
    guard AmaniUI.sharedInstance.uiVersion == .v2 else { return nil }
    return appConfig?.generalconfigs?.v2InvalidOtpText
  }

  private func setTextsFrom(document: DocumentVersion) {
    if let step = document.steps?.first {
      DispatchQueue.main.async {
        self.titleDescription.text = step.confirmationDescription
        self.setTimerButtonDefaultStylings(text: document.resendOTP)
        // FIXME: Another one
//        self.otpLegend.text = step.otpHint
      }
    }
  }
  
}

// MARK: TextFieldDelegate
extension CheckSMSView: UITextFieldDelegate {
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    viewModel.submitOTP()
    return true
  }

}
