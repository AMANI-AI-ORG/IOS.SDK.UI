//
//  CheckMailViewController.swift
//  AmaniStudio
//
//  Created by Deniz Can on 11.12.2023.
//

import Foundation
import UIKit
import AmaniSDK

class CheckMailViewController: KeyboardAvoidanceViewController {
  
  private let checkMailView = CheckMailView()
  private let checkMailViewModel = CheckMailViewModel()
  
  private var docVersion: DocumentVersion?
  private var completionHandler: (() -> Void)?
  
  override init() {
    super.init()
    
    if let appConfig = try? Amani.sharedInstance
      .appConfig()
      .getApplicationConfig() {
      
      checkMailView.appConfig = appConfig
      
    } else {
      print("[CheckMail] AppConfigError")
    }
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    title = docVersion?
      .steps?
      .first?
      .confirmationTitle
    ?? "Verify Email"
    
    checkMailView.bind(
      withViewModel: checkMailViewModel,
      withDocument: docVersion
    )
    
    /*
     OTP doğrulaması başarılı olduğunda CheckMailView
     buradaki callback'i çağırmalı.
     
     Controller ise bunu üst flow'a forward ediyor.
     */
    checkMailView.setCompletionHandler { [weak self] in
      guard let self else { return }
      
      print("[CheckMail] OTP verification completed")
      
      DispatchQueue.main.async {
        self.completionHandler?()
      }
    }
    
    setupUI()
  }
  
  private func setupUI() {
    
    view.backgroundColor = hextoUIColor(
      hexString: "#EEF4FA"
    )
    
    addPoweredByIcon()
    
    contentView.addSubview(checkMailView)
    
    checkMailView.translatesAutoresizingMaskIntoConstraints = false
    
    NSLayoutConstraint.activate([
      checkMailView.centerYAnchor.constraint(
        equalTo: contentView.centerYAnchor
      ),
      
      checkMailView.leadingAnchor.constraint(
        equalTo: contentView.leadingAnchor,
        constant: 20.0
      ),
      
      checkMailView.trailingAnchor.constraint(
        equalTo: contentView.trailingAnchor,
        constant: -20.0
      )
    ])
  }
  
  func setupCompletionHandler(
    _ handler: @escaping () -> Void
  ) {
    completionHandler = handler
  }
  
  func bind(
    with stepModel: KYCStepViewModel
  ) {
    
    docVersion = stepModel
      .documents
      .first?
      .versions?
      .first
    
    guard let ruleID = stepModel.getRuleModel().id else {
      print("[CheckMail] Rule ID is nil")
      return
    }
    
    checkMailViewModel.setRuleID(
      ruleID
    )
  }
}
