//
//  SelfieRunnable.swift
//  AmaniUIv1
//
//  Created by Deniz Can on 3.11.2022.
//

import AmaniSDK
import UIKit

class SelfieHandler: DocumentHandler {
  var topVC: UIViewController
  var stepViewModel: KYCStepViewModel
  var docID: DocumentID
  var stepView: UIView?
  
  // Might be Selfie, AutoSelfie or PoseEstimation.
  private var selfieModule: Any!
  
  required init(topVC: UIViewController, stepVM: KYCStepViewModel, docID: DocumentID) {
    self.topVC = topVC
    self.stepViewModel = stepVM
    self.docID = docID
  }
  
  func start(docStep: AmaniSDK.DocumentStepModel, version: AmaniSDK.DocumentVersion, workingStepIndex: Int,completion: @escaping StepCompletionCallback) {
    guard let selfieType = version.selfieType else {
      completion(.failure(.configError))
      return
    }
    let animationVC = ContainerViewController(
      nibName: String(describing: ContainerViewController.self),
      bundle: Bundle(for: ContainerViewController.self)
    )
    self.topVC.navigationController?.pushViewController(animationVC, animated: true)
    animationVC.bind(animationName: version.type!, docStep: version.steps![steps.front.rawValue], step:steps.front) {
      var selfieView:UIView = UIView()
      // Manual Selfie
      if selfieType == -1 {
        selfieView = self.runManualSelfie(
          step: docStep,
          version: version,
          completion: completion
        )!
      }
      else if selfieType == 0 {
        selfieView = self.runAutoSelfie(
          step: docStep,
          version: version,
          completion: completion
        )!
      } else if selfieType >= 1 {
        selfieView = self.runPoseEstimation(
          step: docStep,
          version: version,
          completion: completion
        )!
      }
      animationVC.view.addSubview(selfieView)
      animationVC.view.bringSubviewToFront(selfieView)
    }
  }
  
  func upload(completion: @escaping StepUploadCallback) {
    guard let selfieModule = selfieModule else { return }
    
    if (selfieModule is Selfie) {
      (selfieModule as! Selfie).upload( location: AmaniUI.sharedInstance.location) { result in
        completion(result,nil)
      }
    } else if (selfieModule is AutoSelfie){
      (selfieModule as! AutoSelfie).upload(location: AmaniUI.sharedInstance.location) { result in
        completion(result,nil)
      }
    } else if (selfieModule is PoseEstimation) {
      (selfieModule as! PoseEstimation).upload(location: AmaniUI.sharedInstance.location){ result in
        completion(result,nil)
      }
    }
    
  }
  
  private func runManualSelfie(step: DocumentStepModel, version: DocumentVersion, completion: @escaping StepCompletionCallback) -> UIView?{
    selfieModule = Amani.sharedInstance.selfie()
    guard let currentSelfieModule = selfieModule as? Selfie else {
      print("cant return")
      return nil
    }
    
    do {
      
      stepView = try currentSelfieModule.start { image in
        self.stepView?.removeFromSuperview()
        self.startConfirmVC(image: image, docStep: step, docVer: version) { [weak self] () in
          completion(.success(self!.stepViewModel))
          self?.topVC.navigationController?.popToViewController(ofClass: HomeViewController.self)
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
  
  
  private func runAutoSelfie(step: DocumentStepModel, version: DocumentVersion, completion: @escaping StepCompletionCallback)-> UIView? {
    selfieModule = Amani.sharedInstance.autoSelfie()
    
    guard let currentSelfieModule = selfieModule as? AutoSelfie else {
      print("cant return")
      return nil
    }
    do {
      var infoMessages:[autoSelfieInfoState:String] = [:]
      var screenConfig:[autoSelfieConfigState:String] = [:]
      if let generalConfig =  try Amani.sharedInstance.appConfig().getApplicationConfig().generalconfigs{

        screenConfig[.primaryButtonBackgroundColor] = generalConfig.primaryButtonBackgroundColor
        screenConfig[.appBackgroundColor] = generalConfig.appBackground
        screenConfig[.appFontColor] = generalConfig.appFontColor
      }
      infoMessages[.faceTooSmall] = version.faceIsTooFarText
      infoMessages[.notInArea] = version.faceNotInsideText
      infoMessages[.captureDescription] = step.captureDescription
      infoMessages[.completed] = ""
      infoMessages[.faceIsOk] = ""

      screenConfig[.ovalBorderColor] = version.ovalViewStartColor
      screenConfig[.ovalBorderSuccessColor] = version.ovalViewSuccessColor
      
      currentSelfieModule.setScreenConfigs(screenConfig: screenConfig)
      currentSelfieModule.setInfoMessages(infoMessages: infoMessages)
      stepView = try currentSelfieModule.start { image in
        self.stepView?.removeFromSuperview()
        self.startConfirmVC(image: image, docStep: step, docVer: version) { [weak self] () in
          completion(.success(self!.stepViewModel))
          self?.topVC.navigationController?.popToViewController(ofClass: HomeViewController.self)
        }
      }
      return stepView
    } catch let err {
      print(err)
      completion(.failure(.moduleError))
      return nil
    }
  }
  
  private func runPoseEstimation(step: DocumentStepModel, version: DocumentVersion, completion: @escaping StepCompletionCallback)->UIView? {
    let poseCount = version.selfieType! + 1
    
    selfieModule = Amani.sharedInstance.poseEstimation()
    guard let currentSelfieModule = selfieModule as? PoseEstimation else {
      print("cant return")
      return nil
    }
    do {
      var infoMessages:[poseState:String] = [:]
      var screenConfig:[poseConfigState:String] = [:]
      if let generalConfig =  try Amani.sharedInstance.appConfig().getApplicationConfig().generalconfigs{
        infoMessages[.next] = generalConfig.continueText
        infoMessages[.confirm] = generalConfig.confirmText
        infoMessages[.tryAgain] = generalConfig.tryAgainText
        screenConfig[.buttonRadius] = String(generalConfig.buttonRadius!)
        screenConfig[.primaryButtonBackgroundColor] = generalConfig.primaryButtonBackgroundColor
        screenConfig[.primaryButtonTextColor] = generalConfig.primaryButtonTextColor
        screenConfig[.appBackgroundColor] = generalConfig.appBackground
        screenConfig[.appFontColor] = generalConfig.appFontColor
      }
     
      infoMessages[.lookStraight] = version.keepStraightText
      infoMessages[.wrongPose] = version.faceNotStraightText
      infoMessages[.faceTooSmall] = version.faceIsTooFarText
      infoMessages[.turnDown] = version.turnDownText
      infoMessages[.turnUp] = version.turnUpText
      infoMessages[.turnLeft] = version.turnLeftText
      infoMessages[.turnRight] = version.turnRightText
      infoMessages[.notInArea] = version.faceNotInsideText
      infoMessages[.holdPhoneVertically] = version.holdStable
      infoMessages[.informationScreenDesc1] = version.informationScreenDesc1
      infoMessages[.informationScreenDesc2] = version.informationScreenDesc2
      infoMessages[.informationScreenTitle] = version.informationScreenTitle
      infoMessages[.captureDescription] = step.captureDescription
      infoMessages[.descriptionHeader] = step.captureTitle
      infoMessages[.errorTitle] = version.selfieAlertTitle
      infoMessages[.errorMessage] = version.selfieAlertDescription
      infoMessages[.closedEyes] = ""
      infoMessages[.completed] = ""
      infoMessages[.faceIsOk] = ""

      screenConfig[.ovalBorderColor] = version.ovalViewStartColor
      screenConfig[.ovalBorderSuccessColor] = version.ovalViewSuccessColor
      screenConfig[.poseCount] = String(poseCount)
      screenConfig[.secondaryGuideVisibility] = "\(version.showOnlyArrow ?? true)"
      
      currentSelfieModule.setInfoMessages(infoMessages: infoMessages)
      currentSelfieModule.setScreenConfig(screenConfig: screenConfig)
      stepView = try currentSelfieModule.start{ image in
        self.stepView?.removeFromSuperview()
        self.startConfirmVC(image: image, docStep: step, docVer: version) { [weak self] () in
          completion(.success(self!.stepViewModel))
          self?.topVC.navigationController?.popToViewController(ofClass: HomeViewController.self)
        }
      }
//      self.showStepView(navbarHidden: false)
      return stepView
    } catch let err {
      print(err)
      completion(.failure(.moduleError))
      return nil
    }
    
  }
  
}
