//
//  CameraDocumentHandler.swift
//  AmaniUI
//

import VisionKit
import AmaniSDK

final class CameraDocumentHandler: NSObject, DocumentHandler {

  weak var topVC: UIViewController?

  var stepViewModel: KYCStepViewModel
  var docID: DocumentID
  var stepView: UIView?

  private var scannedImages: [UIImage] = []
  private var files: [FileWithType] = []

  private var callback:
  ((Result<KYCStepViewModel, KYCStepError>) -> Void)?

  private let documentModule =
  Amani.sharedInstance.document()

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
    completion: @escaping (
      Result<KYCStepViewModel, KYCStepError>
    ) -> Void
  ) {

    guard let type = version.type else {
      completion(.failure(.configError))
      return
    }

    callback = completion

    documentModule.setType(type: type)

    openDocumentScanner()
  }

  func upload(
    completion: @escaping (
      (Bool?, [String: Any]?) -> Void
    )
  ) {

    guard !files.isEmpty else {
      completion(false, nil)
      return
    }

    documentModule.upload(
      location: AmaniUI.sharedInstance.location,
      files: files
    ) { result, args in

      completion(result, args)
    }
  }
}

private extension CameraDocumentHandler {

  func openDocumentScanner() {

    DispatchQueue.main.async { [weak self] in

      guard
        let self,
        let topVC = self.topVC
      else {
        return
      }

      guard VNDocumentCameraViewController.isSupported else {
        self.callback?(.failure(.moduleError))
        return
      }

      let documentCameraViewController =
      VNDocumentCameraViewController()

      documentCameraViewController.delegate = self

      topVC.present(
        documentCameraViewController,
        animated: true
      )
    }
  }
}

extension CameraDocumentHandler: VNDocumentCameraViewControllerDelegate {

  func documentCameraViewController(
    _ controller: VNDocumentCameraViewController,
    didFinishWith scan: VNDocumentCameraScan
  ) {

    for pageNumber in 0..<scan.pageCount {
      scannedImages.append(
        scan.imageOfPage(at: pageNumber)
      )
    }

    for image in scannedImages {
      guard let imageData = image.jpegData(
        compressionQuality: 0.95
      ) else {
        continue
      }

      files.append(
        FileWithType(
          data: imageData,
          dataType: acceptedFileTypes.jpg.rawValue
        )
      )
    }

    controller.dismiss(animated: true) { [weak self] in

      guard let self else {
        return
      }

      self.callback?(.success(self.stepViewModel))

      self.topVC?
        .navigationController?
        .popToViewController(
          ofClass: HomeViewController.self
        )
    }
  }

  func documentCameraViewControllerDidCancel(
    _ controller: VNDocumentCameraViewController
  ) {

    controller.dismiss(animated: true)
  }

  func documentCameraViewController(
    _ controller: VNDocumentCameraViewController,
    didFailWithError error: Error
  ) {

    controller.dismiss(animated: true)
  }
}
