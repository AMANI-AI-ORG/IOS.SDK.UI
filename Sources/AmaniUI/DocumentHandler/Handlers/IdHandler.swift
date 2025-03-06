//
//  IdRunnable.swift
//  AmaniUIv1
//
//  Created by Deniz Can on 2.11.2022.
//

import AmaniSDK
import UIKit
import CoreNFC
#if canImport(AmaniVoiceAssistant)
import AmaniVoiceAssistant
#endif

class IdHandler: DocumentHandler {
    var stepView: UIView?

    weak var topVC: UIViewController?
    var stepViewModel: KYCStepViewModel
    var docID: DocumentID
    var frontView: UIView?

    private let idCaptureModule = Amani.sharedInstance.IdCapture()

    required init(topVC: UIViewController, stepVM: KYCStepViewModel, docID: DocumentID) {
        self.topVC = topVC
        stepViewModel = stepVM
        self.docID = docID
    }

    fileprivate func goNextStep(version: DocumentVersion, completion: @escaping (Result<KYCStepViewModel, KYCStepError>) -> Void) {
        // Start the NFC Screen
        DispatchQueue.main.async {
          if version.nfc == true && NFCNDEFReaderSession.readingAvailable {
                self.startNFCCapture(docVer: version, completion: completion)
            } else {
              self.topVC?.navigationController?.popToViewController(ofClass: HomeViewController.self)
                completion(.success(self.stepViewModel))
            }
        }
    }

    func showContainerVC(version: DocumentVersion, workingStep: Int, completion: @escaping (Result<KYCStepViewModel, KYCStepError>) -> Void) {
      
        let containerVC = ContainerViewController()
        containerVC.docID = self.docID
//        let containerVC = ContainerViewController(
//            nibName: String(describing: ContainerViewController.self),
//            bundle:  AmaniUI.sharedInstance.getBundle()
//        )
        containerVC.stepConfig = stepViewModel.stepConfig
        // NOTE(ddnzcn): For future refactor consider removing this logic as this
        // leads to repetition
        containerVC.setDisappearCallback {
          self.frontView?.removeFromSuperview()
        }
       
      
      
        containerVC.bind(animationName: version.type!, docStep: version.steps![workingStep], step: steps(rawValue: workingStep) ?? steps.front) {
          
            print("Animation ended")
            self.frontView = try? self.idCaptureModule.start(stepId: workingStep)  { [weak self] image in
                DispatchQueue.main.async {
//            self?.stepView?.removeFromSuperview()
                    self?.frontView?.removeFromSuperview()
                    // Start the confirm vc for the front side
                    self?.startConfirmVC(image: image, docStep: version.steps![workingStep], docVer: version,stepId: workingStep) { [weak self] () in
                        // CONFIRM CALLBACK
                        // Add back id capture view to the subviews
//                  self?.showStepView(navbarHidden: false)
//                        self?.goNextStep(version: version, completion: completion)
                      completion(.success(self!.stepViewModel))
                    }
                }
            }
            containerVC.view.addSubview(self.frontView!)
            containerVC.view.bringSubviewToFront(self.frontView!)
            // Show the front capture view
//        self.showStepView(navbarHidden: false)
        }
      topVC?.navigationController?.pushViewController(containerVC, animated: true)
    }

    public func start(docStep: DocumentStepModel, version: DocumentVersion, workingStepIndex: Int = 0, completion: @escaping (Result<KYCStepViewModel, KYCStepError>) -> Void) {
      idCaptureModule.setType(type: version.type!)
      idCaptureModule.setVideoRecording(enabled: AmaniUI.sharedInstance.idVideoRecord)
      idCaptureModule.setIdHologramDetection(enabled:AmaniUI.sharedInstance.idHologramDetection)
      idCaptureModule.setClientSideMRZ(enabled: AmaniUI.sharedInstance.isEnabledClientSideMrz)
        var workingStep = workingStepIndex
      
      idCaptureModule.setManualCropTimeout(Timeout: 30)

      
        do {
            showContainerVC(version: version, workingStep: workingStep) { [weak self] _ in
              workingStep = workingStepIndex
                // CONFIRM CALLBACK
             
                if (version.steps!.count-1) > workingStep {
                    // Remove the current instance of capture view
                  self?.frontView?.removeFromSuperview()

                    // Run the back step
                  
                  if workingStep != workingStepIndex + 1{
                    workingStep += 1
                  }
                  
                    self?.showContainerVC(version: version, workingStep: workingStep) { [weak self] _ in
                      self?.goNextStep(version: version, completion: completion)
                    }
                } else {
                  self?.goNextStep(version: version, completion: completion)
                }
            }

        } catch let error {
            print(error)
            completion(.failure(.moduleError))
        }
    }

    func upload(completion: @escaping ((Bool?, [String : Any]?) -> Void)) {
      idCaptureModule.upload(location: AmaniUI.sharedInstance.location){ [weak self]  result in
        completion(result,nil)
      }
    }

    private func startNFCCapture(docVer: DocumentVersion, completion: @escaping (Result<KYCStepViewModel, KYCStepError>) -> Void) {
        let nfcCaptureView = NFCViewController()
        nfcCaptureView.docID = "NFC"
//        let nfcCaptureView = NFCViewController(
//            nibName: String(describing: NFCViewController.self),
//            bundle: AmaniUI.sharedInstance.getBundle()
//        )
        DispatchQueue.main.async {
            nfcCaptureView.bind(documentVersion: docVer) {
                // ID is captured return to home!
              self.topVC?.navigationController?.popToViewController(ofClass: HomeViewController.self)
                // Run the completion
                completion(.success(self.stepViewModel))
            }
            nfcCaptureView.setNavigationLeftButton()
            self.topVC?.navigationController?.pushViewController(nfcCaptureView, animated: true)
        }
    }
  
}
