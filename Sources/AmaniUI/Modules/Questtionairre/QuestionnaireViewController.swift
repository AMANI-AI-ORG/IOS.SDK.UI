//
//  QuestionnaireViewController.swift
//  AmaniUI
//
//  Created by Deniz Can on 25.01.2024.
//

import Foundation
import UIKit
import AmaniSDK
#if canImport(AmaniLocalization)
import AmaniLocalization
#endif

class QuestionnaireViewController: BaseViewController {
  private var questionnaireView: QuestionnaireView!
  private var handler: (() -> Void)? = nil
  
  let questionnaireViewModel = QuestionnaireViewModel()
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
//    if isMovingFromParent {
//      AmaniUI.sharedInstance.popViewController()
//    }
  }
  
  override func viewDidLoad() {
    self.setPopButton()
      guard let appConfig = try? Amani.sharedInstance.appConfig().getApplicationConfig() else {
          print("AppConfigError")
          return
      }
    
    questionnaireView = QuestionnaireView()
    questionnaireView.appConfig = appConfig
    view.addSubview(questionnaireView)
    questionnaireView.translatesAutoresizingMaskIntoConstraints = false
      view.backgroundColor = UIColor(hexString: appConfig.generalconfigs?.appBackground ?? "#EEF4FA")
    questionnaireView.bind(with: questionnaireViewModel, completionHandler: handler!)
    NSLayoutConstraint.activate([
      questionnaireView.topAnchor.constraint(equalTo: view.topAnchor),
      questionnaireView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      questionnaireView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      questionnaireView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
    ])
    self.navigationItem.titleView?.tintColor = UIColor(hexString: "#20202F")
  }
  
  func setCompletionHandler(_ handler: @escaping (() -> Void)) {
    self.handler = handler
  }
  
  func bind(with stepVM: KYCStepViewModel) {
    self.questionnaireViewModel.setRuleID(stepVM.getRuleModel().id!)
    DispatchQueue.main.async {
      #if canImport(AmaniLocalization)
      self.title = AmaniLocalization.localizedString(forKey: "QUESTIONNAIRE_CAPTURETITLE")
      #else
      self.title = stepVM.documents.first?.versions?.first?.steps?.first?.captureTitle ?? "Questionnaire"
      #endif
    }
  }
  
  
}
