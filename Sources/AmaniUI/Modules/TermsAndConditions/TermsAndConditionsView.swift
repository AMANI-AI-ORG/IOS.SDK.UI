
import Foundation
import UIKit
import AmaniSDK
import WebKit

final class TermsAndConditionsView: UIView {
  
  private let webView: WKWebView
  private let acceptButton: UIButton
  private let declineButton: UIButton
  
  private var completion: (() -> Void)?
  private var declineCompletion: (() -> Void)?
  
  private var appConfig: AppConfigModel?
  private var hasEnabledActionButtons = false
  
  override init(frame: CGRect) {
    let configuration = WKWebViewConfiguration()
    configuration.allowsInlineMediaPlayback = true
    
    self.webView = WKWebView(frame: .zero, configuration: configuration)
    self.acceptButton = UIButton(type: .system)
    self.declineButton = UIButton(type: .system)
    
    super.init(frame: frame)
    
    setupUI()
  }
  
  required init?(coder: NSCoder) {
    let configuration = WKWebViewConfiguration()
    configuration.allowsInlineMediaPlayback = true
    
    self.webView = WKWebView(frame: .zero, configuration: configuration)
    self.acceptButton = UIButton(type: .system)
    self.declineButton = UIButton(type: .system)
    
    super.init(coder: coder)
    
    setupUI()
  }
  
  func configure(with appConfig: AppConfigModel) {
    self.appConfig = appConfig
  }
  
  private func setupUI() {
    backgroundColor = .clear
    
    webView.navigationDelegate = self
    webView.scrollView.delegate = self
    webView.backgroundColor = .clear
    webView.isOpaque = false
    webView.scrollView.backgroundColor = .clear
    webView.scrollView.showsVerticalScrollIndicator = false
    
    acceptButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
    acceptButton.addTarget(self, action: #selector(acceptPressed), for: .touchUpInside)
    
    declineButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
    declineButton.addTarget(self, action: #selector(declinePressed), for: .touchUpInside)
    declineButton.layer.borderWidth = 1
    
    let buttonStackView = UIStackView(arrangedSubviews: [declineButton, acceptButton])
    buttonStackView.axis = .horizontal
    buttonStackView.spacing = 16
    buttonStackView.distribution = .fillEqually
    buttonStackView.translatesAutoresizingMaskIntoConstraints = false
    
    let mainStackView = UIStackView(arrangedSubviews: [webView, buttonStackView])
    mainStackView.axis = .vertical
    mainStackView.spacing = 24
    mainStackView.alignment = .fill
    mainStackView.distribution = .fill
    mainStackView.translatesAutoresizingMaskIntoConstraints = false
    
    webView.setContentHuggingPriority(.defaultLow, for: .vertical)
    buttonStackView.setContentHuggingPriority(.defaultHigh, for: .vertical)
    
    addSubview(mainStackView)
    
    NSLayoutConstraint.activate([
      mainStackView.topAnchor.constraint(equalTo: topAnchor),
      mainStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
      mainStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
      mainStackView.bottomAnchor.constraint(equalTo: bottomAnchor),
      
      acceptButton.heightAnchor.constraint(equalToConstant: 56),
      declineButton.heightAnchor.constraint(equalToConstant: 56)
    ])
  }
  
  func bind(
    completion: @escaping () -> Void,
    declineCompletion: @escaping () -> Void
  ) {
    self.completion = completion
    self.declineCompletion = declineCompletion
    
    applyConfigStyle()
    disableActionButtons()
    loadTermsAndConditionsURL()
  }
  
  private func loadTermsAndConditionsURL() {
    guard let urlString = appConfig?.generalconfigs?.termsConditionsURL,
          let url = URL(string: urlString) else {
      print("Warning: termsConditionsURL is missing or invalid")
      completion?()
      return
    }
    
    let request = URLRequest(url: url)
    webView.load(request)
  }
  
  private func applyConfigStyle() {
    guard let generalConfig = appConfig?.generalconfigs else {
      acceptButton.setTitle("Accept", for: .normal)
      declineButton.setTitle("Decline", for: .normal)
      return
    }
    
    let tc = generalConfig.termsAndConditions
    let buttonRadius = CGFloat(generalConfig.buttonRadius ?? 10)
    
    acceptButton.setTitle(
      tc?.acceptButtonText ?? generalConfig.continueText ?? "Accept",
      for: .normal
    )
    
    declineButton.setTitle(
      tc?.declineButtonText ?? "Decline",
      for: .normal
    )
    
    acceptButton.backgroundColor = hextoUIColor(
      hexString: generalConfig.primaryButtonBackgroundColor ?? ThemeColor.primaryColor.toHexString()
    )
    acceptButton.setTitleColor(
      hextoUIColor(hexString: generalConfig.primaryButtonTextColor ?? "#FFFFFF"),
      for: .normal
    )
    acceptButton.layer.cornerRadius = buttonRadius
    acceptButton.clipsToBounds = true
    
    declineButton.backgroundColor = .clear
    
    let declineColor = hextoUIColor(
      hexString: generalConfig.secondaryButtonTextColor
      ?? generalConfig.primaryButtonBackgroundColor
      ?? "#EA3365"
    )
    
    declineButton.setTitleColor(declineColor, for: .normal)
    declineButton.layer.borderColor = declineColor.cgColor
    declineButton.layer.cornerRadius = buttonRadius
    declineButton.clipsToBounds = true
  }
  
  private func disableActionButtons() {
    hasEnabledActionButtons = false
    
    acceptButton.isEnabled = false
    acceptButton.alpha = 0.5
    
    declineButton.isEnabled = false
    declineButton.alpha = 0.5
  }
  
  private func enableActionButtons() {
    guard !hasEnabledActionButtons else { return }
    
    hasEnabledActionButtons = true
    
    acceptButton.isEnabled = true
    acceptButton.alpha = 1.0
    
    declineButton.isEnabled = true
    declineButton.alpha = 1.0
  }
  
  private func checkIfScrollIsNeeded() {
    let contentHeight = webView.scrollView.contentSize.height
    let visibleHeight = webView.scrollView.bounds.height
    
    guard contentHeight > 0, visibleHeight > 0 else { return }
    
    if contentHeight <= visibleHeight + 1.0 {
      enableActionButtons()
    }
  }
  
  private func checkIfScrolledToBottom(_ scrollView: UIScrollView) {
    let visibleHeight = scrollView.bounds.height
    let contentHeight = scrollView.contentSize.height
    let offsetY = scrollView.contentOffset.y
    
    let distanceFromBottom = contentHeight - offsetY
    
    if distanceFromBottom <= visibleHeight + 1.0 {
      enableActionButtons()
    }
  }
  
  @objc private func acceptPressed() {
    Amani.sharedInstance.customerInfo().acceptTermsConditions { [weak self] success in
      DispatchQueue.main.async {
        if success {
          self?.completion?()
        } else {
          print("Failed to accept T&C")
          self?.completion?()
        }
      }
    }
  }
  
  @objc private func declinePressed() {
    print("User declined Terms and Conditions")
    declineCompletion?()
  }
}


extension TermsAndConditionsView: WKNavigationDelegate {
  
  func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
      self?.checkIfScrollIsNeeded()
    }
  }
  
  func webView(
    _ webView: WKWebView,
    didFail navigation: WKNavigation!,
    withError error: Error
  ) {
    print("Failed to load T&C URL: \(error.localizedDescription)")
    
    
    enableActionButtons()
  }
  
  func webView(
    _ webView: WKWebView,
    didFailProvisionalNavigation navigation: WKNavigation!,
    withError error: Error
  ) {
    print("Failed to start loading T&C URL: \(error.localizedDescription)")
    enableActionButtons()
  }
}

extension TermsAndConditionsView: UIScrollViewDelegate {
  
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    checkIfScrolledToBottom(scrollView)
  }
}


