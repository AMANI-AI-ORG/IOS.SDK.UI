//
//  CheckMailViewController.swift
//  AmaniStudio
//
//  Created by Deniz Can on 11.12.2023.
//

import Foundation
import UIKit
import AmaniSDK
#if canImport(AmaniLocalization)
import AmaniLocalization
#endif

class CheckMailViewController: KeyboardAvoidanceViewController {
  private var checkMailView: CheckMailView!
  private var checkMailViewModel: CheckMailViewModel!
  private var docVersion: DocumentVersion?
  
  override init() {
    super.init()
    
      guard let appConfig = try? Amani.sharedInstance.appConfig().getApplicationConfig() else {
          print("AppConfigError")
          return
      }
      
    checkMailView = CheckMailView()
    checkMailView.appConfig = appConfig
    checkMailViewModel = CheckMailViewModel()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
  }
  
  override func viewDidLoad() {
  #if canImport(AmaniLocalization)
    self.title = AmaniLocalization.localizedString(forKey: "EMAIL_CONFIRMATIONTITLE")
  #else
    self.title = docVersion?.steps?.first?.confirmationTitle ?? "Check Your Email"
  #endif
    checkMailView.bind(
      withViewModel: self.checkMailViewModel,
      withDocument: self.docVersion
    )
    addPoweredByIcon()
    view.backgroundColor = UIColor(hexString: "#EEF4FA")
    contentView.addSubview(checkMailView)
    checkMailView.translatesAutoresizingMaskIntoConstraints = false
    
    NSLayoutConstraint.activate([
      checkMailView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      checkMailView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20.0),
      checkMailView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20.0),
    ])
  }
  
  func setupCompletionHandler(_ handler: @escaping (() -> Void)) {
    checkMailView.setCompletionHandler(handler)
  }
  
  func bind(with stepModel: KYCStepViewModel) {
    self.docVersion = stepModel.documents.first?.versions?.first
    self.checkMailViewModel.setRuleID(stepModel.getRuleModel().id!)
  }
  
}
