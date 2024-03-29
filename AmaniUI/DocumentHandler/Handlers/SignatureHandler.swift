//
//  SelfieRunnable.swift
//  AmaniUIv1
//
//  Created by Deniz Can on 3.11.2022.
//

import AmaniSDK
import UIKit

class SignatureHandler: DocumentHandler {
  var topVC: UIViewController
  var stepViewModel: KYCStepViewModel
  var docID: DocumentID
  var stepView: UIView?
  
  private var SignatureModule = Amani.sharedInstance.signature()
  
  required init(topVC: UIViewController, stepVM: KYCStepViewModel, docID: DocumentID) {
    self.topVC = topVC
    self.stepViewModel = stepVM
    self.docID = docID
  }
  
  func start(docStep: AmaniSDK.DocumentStepModel, version: AmaniSDK.DocumentVersion, workingStepIndex: Int, completion: @escaping StepCompletionCallback) {
    DispatchQueue.main.async {
      
      let SignatureVC = SignatureViewController(
        nibName: String(describing: SignatureViewController.self),
        bundle: Bundle(for: SignatureViewController.self)
      )
      
      SignatureVC.start( docStep: version.steps![steps.front.rawValue], version: version) { [weak self] previewImage in
        self?.startConfirmVC(image: previewImage, docStep: docStep, docVer: version) { [weak self] () in
          completion(.success(self!.stepViewModel))
          self?.topVC.navigationController?.popToViewController(ofClass: HomeViewController.self)
        }
        //      var selfieView:UIView = UIView()
        //      // Manual Selfie
        //      if selfieType == -1 {
        //        selfieView = self.runManualSelfie(
        //          step: docStep,
        //          version: version,
        //          completion: completion
        //        )!
        //      }
        //      else if selfieType == 0 {
        //        selfieView = self.runAutoSelfie(
        //          step: docStep,
        //          version: version,
        //          completion: completion
        //        )!
        //      } else if selfieType >= 1 {
        //        selfieView = self.runPoseEstimation(
        //          step: docStep,
        //          version: version,
        //          completion: completion
        //        )!
        //      }
        //      SignatureVC.view.addSubview(selfieView)
        //      SignatureVC.view.bringSubviewToFront(selfieView)
      }
      self.topVC.navigationController?.pushViewController(SignatureVC, animated: true)

    }
  }
  
  func upload(completion: @escaping StepUploadCallback) {
    SignatureModule.upload(location: AmaniUI.sharedInstance.location){ [weak self] result in
      completion(result,nil)
    }
  }
  
  private func startSignature(
    step: DocumentStepModel,
    version: DocumentVersion,
    workingStepIndex:Int = 0,
    completion: @escaping StepCompletionCallback) -> UIView?{
      
    SignatureModule = Amani.sharedInstance.signature()
    var workingStep = workingStepIndex

    do {
      let allStepsDone = (version.steps?.count)! > workingStep
      stepView = try SignatureModule.start { [weak self] image in
        self?.stepView?.removeFromSuperview()
        
        self?.startConfirmVC(image: image, docStep: step, docVer: version) { [weak self] () in
          if allStepsDone {
            workingStep += 1
            
            completion(.success(self!.stepViewModel))
            self?.topVC.navigationController?.popToViewController(ofClass: HomeViewController.self)
          } else {
            
          }

        }
      }
      return stepView
//      self.showStepView(navbarHidden: false)
    } catch let err {
      print(err)
      
      completion(.failure(.moduleError))
      return nil
    }
  }
  
}
