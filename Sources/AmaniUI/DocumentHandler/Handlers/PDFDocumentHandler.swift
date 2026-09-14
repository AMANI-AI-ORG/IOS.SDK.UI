//
//  PDFDocumentHandler.swift
//  Pods
//
//  Created by Bedri Doğan on 14.09.2026.
//


import UIKit
import AmaniSDK
import MobileCoreServices

final class PDFDocumentHandler: NSObject, DocumentHandler {

    weak var topVC: UIViewController?

    var stepViewModel: KYCStepViewModel
    var docID: DocumentID
    var stepView: UIView?

    private var files: [FileWithType] = []

    private var callback:
        ((Result<KYCStepViewModel, KYCStepError>) -> Void)?

    private let documentModule = Amani.sharedInstance.document()

    required init(
        topVC: UIViewController,
        stepVM: KYCStepViewModel,
        docID: DocumentID
    ) {
        self.topVC = topVC
        self.stepViewModel = stepVM
        self.docID = docID

        super.init()
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

        openDocumentPicker()
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

private extension PDFDocumentHandler {
  
  func openDocumentPicker() {
    
    DispatchQueue.main.async { [weak self] in
      
      guard
        let self,
        let topVC = self.topVC
      else {
        return
      }
      
      let picker = UIDocumentPickerViewController(
        documentTypes: [kUTTypePDF as String],
        in: .import
      )
      
      picker.delegate = self
      picker.allowsMultipleSelection = false
      
      topVC.present(
        picker,
        animated: true
      )
    }
  }
}

extension PDFDocumentHandler: UIDocumentPickerDelegate {
  
  func documentPicker(
    _ controller: UIDocumentPickerViewController,
    didPickDocumentsAt urls: [URL]
  ) {
    
    guard let fileURL = urls.first else {
      return
    }
    
    let hasAccess =
    fileURL.startAccessingSecurityScopedResource()
    
    defer {
      if hasAccess {
        fileURL.stopAccessingSecurityScopedResource()
      }
    }
    
    do {
      
      let fileData = try Data(
        contentsOf: fileURL
      )
      
      files = [
        FileWithType(
          data: fileData,
          dataType: acceptedFileTypes.pdf.rawValue
        )
      ]
      
      callback?(
        .success(stepViewModel)
      )
      
      topVC?
        .navigationController?
        .popToViewController(
          ofClass: HomeViewController.self
        )
      
    } catch {
      
      print(
        "PDF read error:",
        error
      )
    }
  }
  
  func documentPickerWasCancelled(
    _ controller: UIDocumentPickerViewController
  ) {
    controller.dismiss(animated: true)
  }
}
