//
//  BaseRunner.swift
//  AmaniUIv1
//
//  Created by Deniz Can on 2.11.2022.
//

import UIKit
import AmaniSDK

protocol DocumentHandler {
  var topVC: UIViewController? { get set }
  var stepViewModel: KYCStepViewModel { get set }
  var docID: DocumentID { get set }
  var stepView: UIView? { get set }
  
  init(topVC: UIViewController, stepVM: KYCStepViewModel, docID: DocumentID)
  
  func start(docStep: DocumentStepModel, version: DocumentVersion, workingStepIndex:Int, completion: @escaping (Result<KYCStepViewModel, KYCStepError>) -> Void)
  
  func upload(completion: @escaping ((Bool?, [String : Any]?) -> Void))
 
  
}

extension DocumentHandler {
  func startConfirmVC(image: UIImage, docStep: DocumentStepModel, docVer: DocumentVersion,stepId:Int = 0, retake: (() -> Void)? = nil, completion: @escaping () -> Void) {
    if AmaniUI.sharedInstance.uiVersion == .v2 {
      let confirmVC = DocConfirmationV2ViewController()
      confirmVC.bind(image: image, documentID: docID, docVer: docVer, docStep: docStep, stepid: stepId, retake: retake, callback: completion)
      self.topVC?.navigationController?.pushViewController(confirmVC, animated: true)
    } else {
      let confirmVC = DocConfirmationViewController()
      confirmVC.bind(image: image, documentID: docID, docVer: docVer, docStep: docStep,stepid: stepId, callback: completion)
      self.topVC?.navigationController?.pushViewController(confirmVC, animated: true)
    }
  }
  
  func showStepView(navbarHidden: Bool) {
    guard let stepView = stepView else { return }
    DispatchQueue.main.async {
      self.topVC?.view.addSubview(stepView)
      self.topVC?.view.bringSubviewToFront(stepView)
      self.topVC?.navigationController?.setNavigationBarHidden(navbarHidden, animated: false)
    }
  }
  
}
