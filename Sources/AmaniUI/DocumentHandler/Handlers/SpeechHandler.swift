//
//  SpeechHandler.swift
//  Pods
//
//  Created by Bedri Doğan on 9.07.2026.
//

import UIKit
import AmaniSDK

final class SpeechHandler: DocumentHandler {
  
  weak var topVC: UIViewController?
  var stepViewModel: KYCStepViewModel
  var docID: DocumentID
  var stepView: UIView?
  
  private let speechVerifierModule = Amani.sharedInstance.speechVerifier()
  
  private var isUploadInProgress: Bool = false
  private var cachedUploadResult: Bool?
  private var uploadCallbacks: [((Bool?, [String: Any]?) -> Void)] = []
  
  private var didFinishFlow: Bool = false
  
  required init(
    topVC: UIViewController,
    stepVM: KYCStepViewModel,
    docID: DocumentID
  ) {
    self.topVC = topVC
    self.stepViewModel = stepVM
    self.docID = docID
  }
  
  func start(
    docStep: DocumentStepModel,
    version: DocumentVersion,
    workingStepIndex: Int,
    completion: @escaping (Result<KYCStepViewModel, KYCStepError>) -> Void
  ) {
    didFinishFlow = false
    cachedUploadResult = nil
    uploadCallbacks.removeAll()
    isUploadInProgress = false
    
    do {
      speechVerifierModule
        .setVideoRecording(enabled: true)
        .setTimeout(seconds: 30)
        .onSuccess { [weak self] result in
          guard let self else { return }
          
          guard result == true else {
            self.finishWithFailure(completion: completion)
            return
          }
          
          self.handleSpeechSuccess(completion: completion)
        }
        .onFailure { [weak self] reason, currentAttempt in
          guard let self else { return }
          
          self.handleSpeechFailure(
            reason: reason,
            currentAttempt: currentAttempt,
            completion: completion
          )
        }
      
      guard let speechView = try speechVerifierModule.start() else {
        completion(.failure(.moduleError))
        return
      }
      
      self.stepView = speechView
      self.showStepView(navbarHidden: true)
      
    } catch {
      print("SpeechHandler start error:", error)
      completion(.failure(.moduleError))
    }
  }
  
  func upload(
    completion: @escaping ((Bool?, [String: Any]?) -> Void)
  ) {
    if let cachedUploadResult {
      completion(cachedUploadResult, nil)
      return
    }
    
    uploadCallbacks.append(completion)
    
    guard !isUploadInProgress else {
      return
    }
    
    isUploadInProgress = true
    
    speechVerifierModule.upload(
      location: AmaniUI.sharedInstance.location
    ) { [weak self] result in
      guard let self else { return }
      
      self.isUploadInProgress = false
      self.cachedUploadResult = result
      
      let callbacks = self.uploadCallbacks
      self.uploadCallbacks.removeAll()
      
      callbacks.forEach { callback in
        callback(result, nil)
      }
    }
  }
}

  // MARK: - Flow

private extension SpeechHandler {
  
  func handleSpeechSuccess(
    completion: @escaping (Result<KYCStepViewModel, KYCStepError>) -> Void
  ) {
    guard !didFinishFlow else { return }
    didFinishFlow = true
    
    DispatchQueue.main.async {
      self.stepView?.removeFromSuperview()
      self.stepView = nil
      self.topVC?.navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    /*
     Core tarafında video writer finishWriting async çalıştığı için
     upload'ı çok erken çağırmamak daha güvenli.
     İdeal çözüm: Core RecordVideo.stopRecording(completion:) ile upload'ı
     video finalize olduktan sonra tetiklemek.
     */
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
      guard let self else { return }
      
      self.upload { [weak self] result, _ in
        guard let self else { return }
        
        DispatchQueue.main.async {
          if result == true {
            self.topVC?.navigationController?.popToViewController(
              ofClass: HomeViewController.self
            )
            
            completion(.success(self.stepViewModel))
          } else {
            completion(.failure(.moduleError))
          }
        }
      }
    }
  }
  
  func handleSpeechFailure(
    reason: SpeechVerifierFailureReason,
    currentAttempt: Int,
    completion: @escaping (Result<KYCStepViewModel, KYCStepError>) -> Void
  ) {
    print("SpeechHandler failure:", reason.rawValue, "attempt:", currentAttempt)
    
    switch reason {
    case .verificationFailed:
        // Kullanıcı aynı timeout penceresi içinde tekrar doğru okuyabilir.
        // Flow burada bitirilmez.
      return
      
    case .timeout:
        // Core UI retry button gösteriyor.
        // Kullanıcı tekrar deneyebilir, flow burada bitirilmez.
      return
      
    case .cameraPermissionDenied,
        .microphonePermissionDenied,
        .speechRecognitionPermissionDenied,
        .cameraUnavailable,
        .microphoneUnavailable,
        .speechRecognitionUnavailable,
        .cameraInputFailed,
        .microphoneInputFailed,
        .audioSessionFailed,
        .unknown:
      finishWithFailure(completion: completion)
    }
  }
  
  func finishWithFailure(
    completion: @escaping (Result<KYCStepViewModel, KYCStepError>) -> Void
  ) {
    guard !didFinishFlow else { return }
    didFinishFlow = true
    
    DispatchQueue.main.async {
      self.stepView?.removeFromSuperview()
      self.stepView = nil
      self.topVC?.navigationController?.setNavigationBarHidden(false, animated: false)
      
      completion(.failure(.moduleError))
    }
  }
}
