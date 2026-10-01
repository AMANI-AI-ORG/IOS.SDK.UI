//
//  EmailOTPScreenViewController.swift
//  AmaniStudio
//
//  Created by Deniz Can on 10.12.2023.
//

import Foundation
import UIKit
import AmaniSDK

class EmailOTPScreenViewController: KeyboardAvoidanceViewController {
  
  let emailOTPView = EmailOTPView()
  let emailOTPViewModel = EmailOTPViewModel()
  
  private var handler: (() -> Void)?
  private var docVersion: DocumentVersion?
  private var stepVM: KYCStepViewModel?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    guard let appConfig = try? Amani.sharedInstance
      .appConfig()
      .getApplicationConfig()
    else {
      print("[EmailOTP] AppConfigError")
      return
    }
    
    title = docVersion?.steps?.first?.captureTitle
    ?? "Verify Email Address"
    
    emailOTPView.appConfig = appConfig
    
    emailOTPView.bind(
      withViewModel: emailOTPViewModel,
      withDocument: docVersion
    )
    
    emailOTPView.setCompletion { [weak self] in
      guard let self else { return }
      
      guard let stepVM = self.stepVM else {
        print("[EmailOTP] stepVM is nil")
        return
      }
      
      print("[EmailOTP] OTP mail sent - opening CheckMail")
      
      let checkMailViewController = CheckMailViewController()
      
      checkMailViewController.bind(
        with: stepVM
      )
      
      checkMailViewController.setupCompletionHandler { [weak self] in
        guard let self else { return }
        
        print("[EmailOTP] OTP verification completed")
        
         
        self.handler?()
      }
      
      self.navigationController?.pushViewController(
        checkMailViewController,
        animated: true
      )
    }
    
    view.backgroundColor = hextoUIColor(
      hexString: "#EEF4FA"
    )
    
    addPoweredByIcon()
    
    contentView.addSubview(emailOTPView)
    
    emailOTPView.translatesAutoresizingMaskIntoConstraints = false
    
    NSLayoutConstraint.activate([
      emailOTPView.centerYAnchor.constraint(
        equalTo: contentView.centerYAnchor
      ),
      emailOTPView.leadingAnchor.constraint(
        equalTo: contentView.leadingAnchor,
        constant: 20.0
      ),
      emailOTPView.trailingAnchor.constraint(
        equalTo: contentView.trailingAnchor,
        constant: -20.0
      ),
    ])
  }
  
  func setCompletionHandler(
    _ handler: @escaping () -> Void
  ) {
    self.handler = handler
  }
  
  func bind(stepVM: KYCStepViewModel?) {
    self.stepVM = stepVM
    self.docVersion = stepVM?
      .documents
      .first?
      .versions?
      .first
  }
}
