//
//  EmailOTPScreenViewController.swift
//  AmaniStudio
//
//  Created by Deniz Can on 10.12.2023.
//

import Foundation
import UIKit
import AmaniSDK
#if canImport(AmaniLocalization)
import AmaniLocalization
#endif

class EmailOTPScreenViewController: KeyboardAvoidanceViewController {
  let emailOTPView = EmailOTPView()
  let emailOTPViewModel = EmailOTPViewModel()
  private var handler: (() -> Void)? = nil
  private var docVersion: DocumentVersion?
  private var stepVM: KYCStepViewModel?

  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
//    if isMovingFromParent{
//      AmaniUI.sharedInstance.popViewController()
//    }
  }
  
  override func viewDidLoad() {
      guard let appConfig = try? Amani.sharedInstance.appConfig().getApplicationConfig() else {
          print("AppConfigError")
          return
      }
      
  #if canImport(AmaniLocalization)
    self.title = AmaniLocalization.localizedString(forKey: "EMAIL_CAPTURETITLE")
  #else
    self.title = docVersion?.steps?.first?.captureTitle ?? "Verify Email Address"
  #endif
    emailOTPView.appConfig = appConfig
    emailOTPView.bind(withViewModel: emailOTPViewModel, withDocument: docVersion)
  
    
    emailOTPView.setCompletion {[weak self] in
      let checkMailViewController = CheckMailViewController()
      checkMailViewController.bind(with: (self?.stepVM)!)
      checkMailViewController.setupCompletionHandler {
        if let handler = self?.handler {
          handler()
        }
      }
      
      self?.navigationController?.pushViewController(
        checkMailViewController,
        animated: true
      )
    }
    
    view.backgroundColor = UIColor(hexString: "#EEF4FA")
    addPoweredByIcon()
    
    contentView.addSubview(emailOTPView)
    emailOTPView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      emailOTPView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      emailOTPView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20.0),
      emailOTPView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20.0),
    ])
  }
  
  func setCompletionHandler(_ handler: @escaping (() -> Void)) {
    self.handler = handler
  }
  
  func bind(stepVM: KYCStepViewModel?) {
    self.docVersion = stepVM?.documents.first?.versions?.first
    self.stepVM = stepVM
  }
  
}
