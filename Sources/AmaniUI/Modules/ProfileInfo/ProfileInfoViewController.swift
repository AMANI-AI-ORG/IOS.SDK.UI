//
//  ProfileInfoViewController.swift
//  AmaniUI
//
//  Created by Deniz Can on 22.01.2024.
//

import Foundation
import UIKit
import AmaniSDK
#if canImport(AmaniLocalization)
import AmaniLocalization
#endif

class ProfileInfoViewController: KeyboardAvoidanceViewController {
  var profileInfoView: ProfileInfoView!
  let profileInfoViewModel = ProfileInfoViewModel()
  private var handler: (() -> Void)? = nil
  private var docVersion: DocumentVersion?
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
//    if isMovingFromParent {
//      AmaniUI.sharedInstance.popViewController()
//    }
  }
  
  override func viewDidLoad() {
      guard let appConfig = try? Amani.sharedInstance.appConfig().getApplicationConfig() else {
          print("AppConfigError")
          return
      }
      #if canImport(AmaniLocalization)
          title = AmaniLocalization.localizedString(forKey: "profileInfo_captureTitle")
      #else
          title = docVersion?.steps?.first?.captureTitle
      #endif
      profileInfoView = ProfileInfoView()
      profileInfoView.appConfig = appConfig
      profileInfoView.bind(withViewModel: profileInfoViewModel, withDocument: docVersion)
    
    profileInfoView.setCompletion { [weak self] in
      if let handler = self?.handler {
        handler()
      }
    }
    
    view.backgroundColor = UIColor(hexString: "#EEF4FA")
    
    contentView.addSubview(profileInfoView)
    addPoweredByIcon()
    
    profileInfoView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      profileInfoView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      profileInfoView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20.0),
      profileInfoView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20.0),
    ])
  }
  
  func setCompletionHandler(_ handler: @escaping (() -> Void)) {
    self.handler = handler
  }
  
  func bind(with stepModel: KYCStepViewModel) {
    self.docVersion = stepModel.documents.first?.versions?.first
    self.profileInfoViewModel.setRuleID(stepModel.getRuleModel().id!)
  }

}
