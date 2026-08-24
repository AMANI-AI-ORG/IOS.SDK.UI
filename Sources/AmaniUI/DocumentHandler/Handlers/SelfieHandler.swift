//
//  SelfieRunnable.swift
//  AmaniUIv1
//
//  Created by Deniz Can on 3.11.2022.
//

import AmaniSDK
import UIKit

class SelfieHandler: DocumentHandler {
  weak var topVC: UIViewController?
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
  
  func start(
    docStep: AmaniSDK.DocumentStepModel,
    version: AmaniSDK.DocumentVersion,
    workingStepIndex: Int,
    completion: @escaping (Result<KYCStepViewModel, KYCStepError>) -> Void
  ) {
    guard let selfieType = version.selfieType else {
      completion(.failure(.configError))
      return
    }

    if AmaniUI.sharedInstance.uiVersion == .v2 {
      startV2(selfieType: selfieType, docStep: docStep, version: version, completion: completion)
      return
    }

     //Only for posev2 bypassing intro animation
    if selfieType == -2 {
      let containerVC = ContainerViewController()
      containerVC.docID = self.docID
      containerVC.stepConfig = stepViewModel.stepConfig
      containerVC.bypassIntroForPoseV2 = true
      containerVC.setDisappearCallback { [weak self] in
        self?.stepView?.removeFromSuperview()
      }
      
      containerVC.bind(
        animationName: nil,
        docStep: version.steps![steps.front.rawValue],
        step: .front,
        docID: docID
      ) { [weak self, weak containerVC] in
        guard let self = self, let containerVC = containerVC else { return }
        
        guard let stepView = self.runPoseEstimationV2(
          step: docStep,
          version: version,
          onUIStateChanged: { [weak containerVC] state in
            containerVC?.handlePoseEstimationV2UIState(state, selfieType: selfieType)
          },
          completion: completion
        ) else {
          completion(.failure(.moduleError))
          return
        }
        
        self.stepView = stepView
        containerVC.view.addSubview(stepView)
        containerVC.view.bringSubviewToFront(stepView)
      }
      
      self.topVC?.navigationController?.pushViewController(containerVC, animated: true)
      return
    }
    
    let animationVC = ContainerViewController()
    animationVC.docID = self.docID
    animationVC.stepConfig = stepViewModel.stepConfig
    animationVC.setDisappearCallback { [weak self] in
      self?.stepView?.removeFromSuperview()
    }
    
    animationVC.bind(
      animationName: version.type!,
      docStep: version.steps![steps.front.rawValue],
      step: steps.front,
      docID: docID
    ) { [weak self] in
      guard let self = self else { return }
      
      let producedStepView: UIView?
      
      if selfieType == -1 {
        producedStepView = self.runManualSelfie(
          step: docStep,
          version: version,
          completion: completion
        )
      } else if selfieType == 0 {
        producedStepView = self.runAutoSelfie(
          step: docStep,
          version: version,
          completion: completion
        )
      } else if selfieType >= 1 {
        producedStepView = self.runPoseEstimation(
          step: docStep,
          version: version,
          completion: completion
        )
      } else {
        producedStepView = nil
      }
      
      guard let stepView = producedStepView else {
        completion(.failure(.moduleError))
        return
      }
      
      self.stepView = stepView
      animationVC.view.addSubview(stepView)
      animationVC.view.bringSubviewToFront(stepView)
    }
    
    self.topVC?.navigationController?.pushViewController(animationVC, animated: true)
  }

  private func startV2(
    selfieType: Int,
    docStep: AmaniSDK.DocumentStepModel,
    version: AmaniSDK.DocumentVersion,
    completion: @escaping (Result<KYCStepViewModel, KYCStepError>) -> Void
  ) {
    //Only for posev2 bypassing intro animation
    if selfieType == -2 {
      let containerVC = ContainerV2ViewController()
      containerVC.setDisappearCallback { [weak self] in
        self?.stepView?.removeFromSuperview()
      }

      // Re-invoked directly on "Try Again" so retaking reopens the camera immediately instead
      // of leaving the user on the (bypassed) preparation screen.
      var startCapture: (() -> Void)!
      startCapture = { [weak self, weak containerVC] in
        guard let self = self, let containerVC = containerVC else { return }

        guard let stepView = self.runPoseEstimationV2(
          step: docStep,
          version: version,
          retake: { [weak self] in
            self?.stepView?.removeFromSuperview()
            startCapture()
          },
          completion: completion
        ) else {
          completion(.failure(.moduleError))
          return
        }

        self.stepView = stepView
        containerVC.view.addSubview(stepView)
        containerVC.view.bringSubviewToFront(stepView)
      }

      containerVC.bind(
        animationName: nil,
        docStep: version.steps![steps.front.rawValue],
        documentVersion: version,
        step: .front,
        totalSteps: 1,
        isSelfie: true,
        bypassIntro: true
      ) {
        startCapture()
      }

      self.topVC?.navigationController?.pushViewController(containerVC, animated: true)
      return
    }

    // Pose estimation (selfieType >= 1) gets a two-screen guide (primary then secondary),
    // matching V1's existing 2-step pose-estimation instruction sequence. Manual/auto
    // selfie (selfieType -1 / 0) only ever had one instruction step, so they keep one screen.
    let showsSecondaryGuide = selfieType >= 1
    let totalGuideSteps = showsSecondaryGuide ? 2 : 1

    let primaryVC = ContainerV2ViewController()
    primaryVC.setDisappearCallback { [weak self] in
      self?.stepView?.removeFromSuperview()
    }
    primaryVC.bind(
      animationName: version.type,
      docStep: version.steps![steps.front.rawValue],
      documentVersion: version,
      step: .front,
      totalSteps: totalGuideSteps,
      isSelfie: true,
      bypassIntro: false
    ) { [weak self, weak primaryVC] in
      guard let self = self else { return }

      if showsSecondaryGuide {
        self.showSecondarySelfieGuide(
          selfieType: selfieType,
          docStep: docStep,
          version: version,
          completion: completion
        )
      } else if let primaryVC = primaryVC {
        self.startSelfieCapture(
          selfieType: selfieType,
          docStep: docStep,
          version: version,
          hostVC: primaryVC,
          completion: completion
        )
      }
    }

    self.topVC?.navigationController?.pushViewController(primaryVC, animated: true)
  }

  private func showSecondarySelfieGuide(
    selfieType: Int,
    docStep: AmaniSDK.DocumentStepModel,
    version: AmaniSDK.DocumentVersion,
    completion: @escaping (Result<KYCStepViewModel, KYCStepError>) -> Void
  ) {
    let secondaryVC = ContainerV2ViewController()
    secondaryVC.setDisappearCallback { [weak self] in
      self?.stepView?.removeFromSuperview()
    }
    secondaryVC.bind(
      animationName: version.type,
      docStep: version.steps![steps.front.rawValue],
      documentVersion: version,
      step: .back,
      totalSteps: 2,
      isSelfie: true,
      bypassIntro: false
    ) { [weak self, weak secondaryVC] in
      guard let self = self, let secondaryVC = secondaryVC else { return }
      self.startSelfieCapture(
        selfieType: selfieType,
        docStep: docStep,
        version: version,
        hostVC: secondaryVC,
        completion: completion
      )
    }
    self.topVC?.navigationController?.pushViewController(secondaryVC, animated: true)
  }

  private func startSelfieCapture(
    selfieType: Int,
    docStep: AmaniSDK.DocumentStepModel,
    version: AmaniSDK.DocumentVersion,
    hostVC: UIViewController,
    completion: @escaping (Result<KYCStepViewModel, KYCStepError>) -> Void
  ) {
    // Re-invoked directly on "Try Again" so retaking a selfie reopens the camera immediately
    // instead of leaving the user on the preparation/animation screen.
    let retake: () -> Void = { [weak self] in
      self?.stepView?.removeFromSuperview()
      self?.startSelfieCapture(selfieType: selfieType, docStep: docStep, version: version, hostVC: hostVC, completion: completion)
    }

    let producedStepView: UIView?

    if selfieType == -1 {
      producedStepView = runManualSelfie(step: docStep, version: version, retake: retake, completion: completion)
    } else if selfieType == 0 {
      producedStepView = runAutoSelfie(step: docStep, version: version, retake: retake, completion: completion)
    } else if selfieType >= 1 {
      producedStepView = runPoseEstimation(step: docStep, version: version, retake: retake, completion: completion)
    } else {
      producedStepView = nil
    }

    guard let stepView = producedStepView else {
      completion(.failure(.moduleError))
      return
    }

    self.stepView = stepView
    hostVC.view.addSubview(stepView)
    hostVC.view.bringSubviewToFront(stepView)
  }

  deinit {
    selfieModule = nil
  }

  func upload(completion: @escaping ((Bool?, [String : Any]?) -> Void)) {
    guard let selfieModule = selfieModule else { return }
    
    if (selfieModule is Selfie) {
      (selfieModule as! Selfie).upload( location: AmaniUI.sharedInstance.location) { [weak self] result in
        completion(result,nil)
      }
    } else if (selfieModule is AutoSelfie){
      (selfieModule as! AutoSelfie).upload(location: AmaniUI.sharedInstance.location) { [weak self]  result in
        completion(result,nil)
      }
    } else if (selfieModule is PoseEstimation) {
      (selfieModule as! PoseEstimation).upload(location: AmaniUI.sharedInstance.location){ [weak self] result in
        completion(result,nil)
      }
    }
    
  }
  
  func goNextStep( completion: @escaping (Result<KYCStepViewModel, KYCStepError>) -> Void) {
    DispatchQueue.main.async {
      completion(.success(self.stepViewModel))
      self.topVC?.navigationController?.popToViewController(ofClass: HomeViewController.self)
    }
  }
  
  private func runManualSelfie(step: DocumentStepModel, version: DocumentVersion, retake: (() -> Void)? = nil, completion: @escaping (Result<KYCStepViewModel, KYCStepError>) -> Void) -> UIView?{
    selfieModule = Amani.sharedInstance.selfie()
    guard let currentSelfieModule = selfieModule as? Selfie else {
      print("cant return")
      return nil
    }

    do {

      stepView = try currentSelfieModule.start { [weak self] image in
        self?.stepView?.removeFromSuperview()
        DispatchQueue.main.async {
          self?.startConfirmVC(image: image, docStep: step, docVer: version, retake: retake) { [weak self] () in
            self?.goNextStep(completion: completion)
          }
        }
      }
      return stepView
    } catch let err {
      print(err)
      completion(.failure(.moduleError))
      return nil
    }
  }
  
  
  private func runAutoSelfie(step: DocumentStepModel, version: DocumentVersion, retake: (() -> Void)? = nil, completion: @escaping (Result<KYCStepViewModel, KYCStepError>) -> Void)-> UIView? {
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
      infoMessages[.completed] = version.completedText
      infoMessages[.faceIsOk] = version.faceIsOkText

      screenConfig[.ovalBorderColor] = version.ovalViewStartColor
      screenConfig[.ovalBorderSuccessColor] = version.ovalViewSuccessColor

      currentSelfieModule.setScreenConfigs(screenConfig: screenConfig)
      currentSelfieModule.setInfoMessages(infoMessages: infoMessages)
      
      stepView = try currentSelfieModule.start { [weak self]  image in
        self?.stepView?.removeFromSuperview()
        DispatchQueue.main.async {
          self?.startConfirmVC(image: image, docStep: step, docVer: version, retake: retake) { [weak self] () in
            self?.goNextStep(completion: completion)
          }
        }
      }
      return stepView
    } catch let err {
      print(err)
      completion(.failure(.moduleError))
      return nil
    }
  }


  private func runPoseEstimation(
    step: DocumentStepModel,
    version: DocumentVersion,
    retake: (() -> Void)? = nil,
    completion: @escaping (Result<KYCStepViewModel, KYCStepError>) -> Void
  ) -> UIView? {
    let poseCount = version.selfieType ?? 1
    
    do {
      var infoMessages: [poseState: String] = [:]
      var screenConfig: [poseConfigState: String] = [:]
      
      if let generalConfig = try Amani.sharedInstance.appConfig().getApplicationConfig().generalconfigs {
        infoMessages[.next] = generalConfig.continueText
        infoMessages[.confirm] = generalConfig.confirmText
        infoMessages[.tryAgain] = generalConfig.tryAgainText
        screenConfig[.buttonRadius] = String(generalConfig.buttonRadius ?? 10)
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
      infoMessages[.closedEyes] = version.closedEyesText
      infoMessages[.completed] = version.completedText
      infoMessages[.faceIsOk] = version.faceIsOkText

      screenConfig[.ovalBorderColor] = version.ovalViewStartColor
      screenConfig[.ovalBorderSuccessColor] = version.ovalViewSuccessColor
      screenConfig[.poseCount] = String(poseCount)
      screenConfig[.secondaryGuideVisibility] = "\(version.showOnlyArrow ?? true)"
      
      let poseModule = Amani.sharedInstance.poseEstimation()
      self.selfieModule = poseModule
      
      let builder = poseModule.v1
        .setInfoMessages(infoMessages: infoMessages)
        .setScreenConfig(screenConfig: screenConfig)
        .setVideoRecording(enabled: version.recordVideo ?? false)
      
      stepView = try builder.start { [weak self] image in
        self?.stepView?.removeFromSuperview()
        DispatchQueue.main.async {
          self?.startConfirmVC(image: image, docStep: step, docVer: version, retake: retake) { [weak self] in
            self?.goNextStep(completion: completion)
          }
        }
      }

      return stepView
    } catch {
      print("runPoseEstimation error:", error)
      completion(.failure(.moduleError))
      return nil
    }
  }

  private func runPoseEstimationV2(
    step: DocumentStepModel,
    version: DocumentVersion,
    onUIStateChanged: ((PoseEstimationV2UIState) -> Void)? = nil,
    retake: (() -> Void)? = nil,
    completion: @escaping (Result<KYCStepViewModel, KYCStepError>) -> Void
  ) -> UIView? {
    do {
      var infoMessages: [PoseEstimationV2TextKey: String] = [:]
      var screenConfig: [PoseEstimationV2ColorKey: String] = [:]
      
      if let generalConfig = try Amani.sharedInstance.appConfig().getApplicationConfig().generalconfigs {
        screenConfig[.appBackgroundColor] = generalConfig.appBackground
        screenConfig[.appFontColor] = generalConfig.appFontColor
      }
      
      infoMessages[.lookStraight] = version.keepStraightText
      infoMessages[.turnLeft] = version.turnLeftText
      infoMessages[.turnRight] = version.turnRightText
      infoMessages[.notInArea] = version.faceNotInsideText
      infoMessages[.faceTooFar] = version.faceIsTooFarText
      infoMessages[.holdPhoneVertically] = version.holdStable
      infoMessages[.keepRotating] = step.captureDescription
      infoMessages[.completed] = ""
      
      screenConfig[.progressRingColor] = version.ovalViewStartColor
      screenConfig[.progressRingTrackColor] = version.ovalViewSuccessColor
      
      let poseModule = Amani.sharedInstance.poseEstimation()
      self.selfieModule = poseModule
      
      let builder = poseModule.v2
        .setSelfiePreparationVideoURL(AmaniUI.sharedInstance.preparationVideoURL)
        .setInfoMessages(infoMessages: infoMessages)
        .setScreenConfig(screenConfig: screenConfig)
        .setVideoRecording(enabled: version.recordVideo ?? false)
      
      if let onUIStateChanged {
        builder.setOnUIStateChanged(onUIStateChanged)
      }
      
      stepView = try builder.start { [weak self] image in
        self?.stepView?.removeFromSuperview()

        DispatchQueue.main.async {
          self?.startConfirmVC(image: image, docStep: step, docVer: version, retake: retake) { [weak self] in
            self?.goNextStep(completion: completion)
          }
        }
      }

      return stepView
    } catch {
      print("runPoseEstimationV2 error:", error)
      completion(.failure(.moduleError))
      return nil
    }
  }
  
}

