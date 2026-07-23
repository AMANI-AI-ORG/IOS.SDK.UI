//
//  SpeechHandler.swift
//  Pods
//
//  Created by Bedri Doğan on 23.07.2026.
//

import UIKit
import CoreLocation
import AmaniSDK

final class SpeechHandler: DocumentHandler {
  
  weak var topVC: UIViewController?
  var stepViewModel: KYCStepViewModel
  var docID: DocumentID
  var stepView: UIView?
  private var containerVC: ContainerViewController?
  private var speechVerifierModule: SpeechVerifier?
  
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
    resetFlowState()
    
    let containerVC = ContainerViewController()
    self.containerVC = containerVC
    
    containerVC.docID = self.docID
    containerVC.stepConfig = stepViewModel.stepConfig
    containerVC.isSpeechFlow = true
    containerVC.setDisappearCallback { [weak self] in
      self?.stepView?.removeFromSuperview()
      self?.stepView = nil
      self?.speechVerifierModule = nil
    }
    
    let containerStep = version.steps?[workingStepIndex] ?? docStep
    
    containerVC.bind(
      animationName: nil,
      docStep: containerStep,
      step: steps.front,
      docID: docID
    ) { [weak self, weak containerVC] in
      guard let self else { return }
      guard let containerVC else { return }
      
      guard let speechView = self.runSpeechVerifier(
        step: docStep,
        version: version,
        completion: completion
      ) else {
        completion(.failure(.moduleError))
        return
      }
      
      self.stepView = speechView
      
      containerVC.view.addSubview(speechView)
      containerVC.view.bringSubviewToFront(speechView)
      
      speechView.translatesAutoresizingMaskIntoConstraints = false
      
      NSLayoutConstraint.activate([
        speechView.leadingAnchor.constraint(equalTo: containerVC.view.leadingAnchor),
        speechView.trailingAnchor.constraint(equalTo: containerVC.view.trailingAnchor),
        speechView.topAnchor.constraint(equalTo: containerVC.view.safeAreaLayoutGuide.topAnchor),
        speechView.bottomAnchor.constraint(equalTo: containerVC.view.bottomAnchor)
      ])
    }
    
    topVC?.navigationController?.setNavigationBarHidden(false, animated: false)
    topVC?.navigationController?.pushViewController(containerVC, animated: true)
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
    
    guard let speechVerifierModule else {
      flushUploadCallbacks(result: false, extras: nil)
      return
    }
    
    isUploadInProgress = true
    
    speechVerifierModule.upload(
      location: AmaniUI.sharedInstance.location
    ) { [weak self] result in
      guard let self else { return }
      
      self.isUploadInProgress = false
      self.cachedUploadResult = result
      
      self.flushUploadCallbacks(
        result: result,
        extras: nil
      )
    }
  }
}

  // MARK: - Speech Verifier

private extension SpeechHandler {
  
  private func runSpeechVerifier(
    step: DocumentStepModel,
    version: DocumentVersion,
    completion: @escaping (Result<KYCStepViewModel, KYCStepError>) -> Void
  ) -> UIView? {
    speechVerifierModule = Amani.sharedInstance.speechVerifier()
    
    guard let verifier = speechVerifierModule else {
      return nil
    }
    
    configureSpeechVerifier(
      verifier,
      step: step,
      version: version
    )
    
    verifier
      .setVideoRecording(enabled: true)
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
    
    do {
      return try verifier.start()
    } catch {
      print("SpeechHandler start error:", error)
      return nil
    }
  }
  
  func configureSpeechVerifier(
    _ verifier: SpeechVerifier,
    step: DocumentStepModel,
    version: DocumentVersion
  ) {
    let type = normalizedSpeechType(from: version)
    
    verifier.setType(type: type)
    verifier.setTimeout(seconds: version.timeoutSeconds ?? 30)
     
    applySpeechVerifierAppearance(
      verifier,
      version: version
    )
    
    switch speechPhase(from: type) {
    case .identityAnswers:
      configureIdentityAnswersFlow(
        verifier,
        version: version
      )
      
    case .spokenText:
      configureSpokenTextFlow(
        verifier,
        version: version
      )
    }
  }
}

  // MARK: - Phase

private extension SpeechHandler {
  
  enum SpeechPhase {
    case identityAnswers
    case spokenText
  }
  
  func normalizedSpeechType(
    from version: DocumentVersion
  ) -> String {
    let type = version.type?
      .trimmingCharacters(in: .whitespacesAndNewlines)
    
    guard let type, !type.isEmpty else {
      return "XXX_ST_0"
    }
    
    return type
  }
  
  func speechPhase(
    from type: String
  ) -> SpeechPhase {
    let normalizedType = type
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .uppercased()
    
    if normalizedType == "XXX_SV_0" || normalizedType.contains("_SV_") {
      return .spokenText
    }
    
    return .identityAnswers
  }
}

  // MARK: - Identity Answers Flow

private extension SpeechHandler {
  
  func configureIdentityAnswersFlow(
    _ verifier: SpeechVerifier,
    version: DocumentVersion
  ) {
    let questions = identityQuestionTypes(from: version)
    
    verifier.setIdentityQuestions(
      questions.isEmpty ? defaultIdentityQuestions() : questions
    )
    
    let threshold = identityMatchThresholdPercent(from: version)
    
    verifier.matchThresholdPercent(
      threshold
    )
    
    /*
     Burada identityAnswers(...) çağırma.
     
     Bu sayede Core SDK:
     - getDocuments request'e çıkar
     - API'den idNumber / motherName / fatherName / documentNumber değerlerini alır
     - ekranda sadece question prompt gösterir
     - expected answer'ı hiçbir zaman ekrana basmaz
     */
  }
  
  func identityQuestionTypes(
    from version: DocumentVersion
  ) -> [SpeechVerifierIdentityQuestionType] {
    guard let speechVerification = version.speechVerification,
          let steps = speechVerification.steps else {
      return []
    }
    
    var result: [SpeechVerifierIdentityQuestionType] = []
    
    for step in steps {
      let type = step.type?
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .uppercased()
      
      guard type == "IDENTITY_QUESTION" else {
        continue
      }
      
      let questions = step.questions ?? []
      
      for question in questions {
        guard let mappedType = mapIdentityQuestionType(
          question.type
        ) else {
          continue
        }
        
        if !result.contains(where: { $0 == mappedType }) {
          result.append(mappedType)
        }
      }
    }
    
    return result
  }
  
  func identityMatchThresholdPercent(
    from version: DocumentVersion
  ) -> Int {
    guard let speechVerification = version.speechVerification else {
      return 100
    }
    
    let defaultThreshold = speechVerification.defaultMatchThresholdPercent ?? 100
    
    let thresholds = speechVerification.steps?
      .flatMap { step -> [Int] in
        guard step.type?.uppercased() == "IDENTITY_QUESTION" else {
          return []
        }
        
        let stepThreshold = step.matchThresholdPercent
        
        return step.questions?.compactMap {
          $0.matchThresholdPercent ?? stepThreshold
        } ?? []
      } ?? []
    
    /*
     Core tarafında şu an question bazlı threshold setter yok.
     Bu yüzden identity questions için en toleranslı değeri kullanıyoruz.
     
     Config örneğinde:
     ID_NUMBER: 90
     MOTHER_NAME: 80
     FATHER_NAME: 80
     DOCUMENT_NUMBER: 80
     
     Global olarak 80 set edilir.
     */
    return thresholds.min() ?? defaultThreshold
  }
  
  func mapIdentityQuestionType(
    _ rawType: String?
  ) -> SpeechVerifierIdentityQuestionType? {
    let type = rawType?
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .uppercased()
    
    switch type {
    case "ID_NUMBER":
      return .idNumber
      
    case "MOTHER_NAME":
      return .motherName
      
    case "FATHER_NAME":
      return .fatherName
      
    case "DOCUMENT_NUMBER":
      return .documentNumber
      
    default:
      return nil
    }
  }
  
  func defaultIdentityQuestions() -> [SpeechVerifierIdentityQuestionType] {
    [
      .documentNumber,
      .motherName
    ]
  }
}

  // MARK: - Spoken Text Flow

private extension SpeechHandler {
  
  func configureSpokenTextFlow(
    _ verifier: SpeechVerifier,
    version: DocumentVersion
  ) {
    let configuredTexts = spokenTextItems(from: version)
    
    guard !configuredTexts.isEmpty else {
      verifier
        .setText(defaultSpokenText())
        .matchThresholdPercent(
          version.speechVerification?.defaultMatchThresholdPercent ?? 90
        )
      return
    }
    
    /*
     Core tarafındaki mevcut public API'de text bazlı threshold yok.
     Bu yüzden text'i UI tarafında seçiyoruz ve threshold'unu beraber set ediyoruz.
     Böylece birden fazla text varsa bile seçilen text'in threshold'u doğru çalışır.
     */
    let selectedItem = configuredTexts.randomElement()!
    
    verifier
      .setText(selectedItem.text)
      .matchThresholdPercent(selectedItem.threshold)
  }
  
  func spokenTextItems(
    from version: DocumentVersion
  ) -> [(text: String, threshold: Int)] {
    guard let speechVerification = version.speechVerification,
          let steps = speechVerification.steps else {
      return []
    }
    
    let defaultThreshold = speechVerification.defaultMatchThresholdPercent ?? 90
    
    var result: [(text: String, threshold: Int)] = []
    
    for step in steps {
      let type = step.type?
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .uppercased()
      
      guard type == "SPOKEN_TEXT" else {
        continue
      }
      
      let stepThreshold = step.matchThresholdPercent ?? defaultThreshold
      let texts = step.texts ?? []
      
      for textItem in texts {
        guard let text = textItem.text?
          .trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty else {
          continue
        }
        
        let threshold = textItem.matchThresholdPercent ?? stepThreshold
        
        result.append(
          (
            text: text,
            threshold: threshold
          )
        )
      }
    }
    
    return result
  }
  
  func defaultSpokenText() -> String {
    "Bugün kimliğimi doğrulamak için bu metni okuyorum."
  }
}


  // MARK: - Colors

  private extension SpeechHandler {
    
    func applySpeechVerifierAppearance(
      _ verifier: SpeechVerifier,
      version: DocumentVersion
    ) {
      verifier.setAppearance(
        makeSpeechVerifierAppearance(from: version)
      )
    }
    
    func makeSpeechVerifierAppearance(
      from version: DocumentVersion
    ) -> SpeechVerifierAppearance {
      let colors = version.speechVerifierUiColors
      
      let defaultTextColor = stepViewModel.textColor
      let defaultButtonColor = stepViewModel.buttonColor
      
      let instructionTextColor = UIColor(hexString: colors?.instructionTextColor ?? "")
      
      
      let visibleTextColor = UIColor(hexString: colors?.speechTextColor ?? "")
     
      
      let statusTextColor = UIColor(hexString: colors?.statusTextColor ?? "")
    
      
      let highlightColor = UIColor(hexString: colors?.speechTextHighlightColor ?? "")
     
      
      let overlayBackgroundColor = UIColor(hexString: colors?.overlayBackgroundColor ?? "\(UIColor.black.withAlphaComponent(0.80))")
      
      
      let retryButtonTextColor = UIColor(hexString: colors?.retryButtonTextColor ?? "ffffff")
      
      
      let retryButtonBackgroundColor = UIColor(hexString: colors?.retryButtonBackgroundColor ?? "")
     
      
      let listeningIconColor = UIColor(hexString: colors?.micActiveColor ?? "\(highlightColor)")
      
      
      let successIconColor = UIColor(hexString: colors?.resultSuccessColor ?? "\(highlightColor)")
      
      
      let failureIconColor = UIColor(hexString: colors?.resultErrorColor ?? "")
      
      
      return SpeechVerifierAppearance(
        instructionTextColor: instructionTextColor,
        visibleTextColor: visibleTextColor,
        highlightedTextColor: highlightColor,
        statusTextColor: statusTextColor,
        progressTintColor: highlightColor,
        progressTrackTintColor: visibleTextColor.withAlphaComponent(0.25),
        overlayBackgroundColor: overlayBackgroundColor,
        retryButtonTextColor: retryButtonTextColor,
        retryButtonBackgroundColor: retryButtonBackgroundColor,
        listeningIconColor: listeningIconColor,
        successIconColor: successIconColor,
        failureIconColor: failureIconColor
      )
    }
  }

  // MARK: - State

private extension SpeechHandler {
  
  func resetFlowState() {
    didFinishFlow = false
    cachedUploadResult = nil
    uploadCallbacks.removeAll()
    isUploadInProgress = false
    stepView = nil
    speechVerifierModule = nil
    containerVC = nil
  }
  
  func flushUploadCallbacks(
    result: Bool?,
    extras: [String: Any]?
  ) {
    let callbacks = uploadCallbacks
    uploadCallbacks.removeAll()
    
    callbacks.forEach { callback in
      callback(result, extras)
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
    }
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
      guard let self else { return }
      
      self.upload { [weak self] result, _ in
        guard let self else { return }
        
        DispatchQueue.main.async {
          guard self.isOwnContainerOnTop() else {
            print("SpeechHandler success ignored: stale handler callback.")
            return
          }
          
          if result == true {
            self.popOwnContainerIfNeeded()
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
      /*
       Core UI aynı timeout penceresi içinde tekrar dinlemeye devam ediyor.
       Flow burada bitirilmez.
       */
      return
      
    case .timeout:
      /*
       Core UI retry button gösteriyor.
       Kullanıcı tekrar deneyebilir.
       */
      return
      
    case .speechRecognitionUnavailable:
      /*
       Art arda SV -> ST veya ST -> SV geçişinde SFSpeech tarafı
       transient error döndürebiliyor. Bu durumda flow'u pop'lama.
       Core UI retry / failure state'i yönetsin.
       */
      return
      
    case .cameraPermissionDenied,
        .microphonePermissionDenied,
        .speechRecognitionPermissionDenied,
        .cameraUnavailable,
        .microphoneUnavailable,
        .cameraInputFailed,
        .microphoneInputFailed,
        .audioSessionFailed,
        .identityAnswerNotFound,
        .identityAnswerMismatch,
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
      
      guard self.isOwnContainerOnTop() else {
        print("SpeechHandler failure ignored: stale handler callback.")
        return
      }
      
      self.popOwnContainerIfNeeded()
      completion(.failure(.moduleError))
    }
  }
}


private extension SpeechHandler {
  
  func isOwnContainerOnTop() -> Bool {
    guard let containerVC else {
      return false
    }
    
    return topVC?.navigationController?.topViewController === containerVC
  }
  
  func popOwnContainerIfNeeded() {
    guard isOwnContainerOnTop() else {
      print("SpeechHandler skip pop: this handler's container is not on top anymore.")
      return
    }
    
    topVC?.navigationController?.popToViewController(
      ofClass: HomeViewController.self
    )
  }
}
