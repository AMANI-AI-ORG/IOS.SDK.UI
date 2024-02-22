//
//  PhoneOTPViewController.swift
//  AmaniUI
//
//  Created by Deniz Can on 26.12.2023.
//

import Foundation
import UIKit
import AmaniSDK

class PhoneOTPScreenViewController: KeyboardAvoidanceViewController {
  private var phoneOTPView: PhoneOTPView!
  private var phoneOTPViewModel: PhoneOTPViewModel!
  
  private var handler: (() -> Void)? = nil
  private var docVersion: DocumentVersion? = nil
  private var stepVM: KYCStepViewModel?
  
  override init() {
    super.init()
    phoneOTPView = PhoneOTPView()
    phoneOTPViewModel = PhoneOTPViewModel()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
//    if isMovingFromParent {
//      AmaniUI.sharedInstance.popViewController()
//    }
  }
  
  override func viewDidLoad() {
    phoneOTPView.bind(withViewModel: phoneOTPViewModel, withDocument: self.docVersion)
    
    phoneOTPView.setCompletion {[weak self] in
      let checkSMSViewController = CheckSMSViewController()
      checkSMSViewController.bind(with: (self?.stepVM)!)
      checkSMSViewController.setupCompletionHandler {
        if let handler = self?.handler {
          handler()
        }
      }
      
      self?.navigationController?.pushViewController(
        checkSMSViewController,
        animated: true
      )
    }
    
    view.backgroundColor = UIColor(hexString: "#EEF4FA")
    addPoweredByIcon()
    
    contentView.addSubview(phoneOTPView)
    phoneOTPView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      phoneOTPView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      phoneOTPView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20.0),
      phoneOTPView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20.0),
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
