
import Foundation
import UIKit
import AmaniSDK
import WebKit

final class TermsAndConditionsViewController: BaseViewController {
  private let tcView = TermsAndConditionsView()
  private var handler: (() -> Void)?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    setNavigationLeftButton()
  }
  
  private func setupUI() {
    guard let appConfig = try? Amani.sharedInstance.appConfig().getApplicationConfig() else {
      print("AppConfigError")
      return
    }
    
    view.backgroundColor = hextoUIColor(
      hexString: appConfig.generalconfigs?.appBackground ?? "#EEF4FA"
    )
    
    title = appConfig.generalconfigs?.termsAndConditions?.title ?? "Terms and Conditions"
    
    tcView.configure(with: appConfig)
    tcView.bind(
      completion: { [weak self] in
        self?.handler?()
      },
      declineCompletion: { [weak self] in
        self?.handler?()
      }
    )
    
    view.addSubview(tcView)
    tcView.translatesAutoresizingMaskIntoConstraints = false
    
    NSLayoutConstraint.activate([
      tcView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
      tcView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
      tcView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
      tcView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
    ])
    
    addPoweredByIcon()
  }
  
  func setCompletionHandler(_ handler: @escaping (() -> Void)) {
    self.handler = handler
  }
  
  func bind(stepVM: KYCStepViewModel?) {
      // T&C might not need a full stepVM if it's purely config driven,
      // but we keep it for consistency with NonKYCStepManager
  }
}
