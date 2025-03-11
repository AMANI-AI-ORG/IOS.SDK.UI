//
//  DocumentVersionViewModel.swift
//  AmaniUIv1
//
//  Created by Deniz Can on 11.10.2022.
//

import AmaniSDK
import Foundation
import UIKit

class DocumentHandlerHelper {
  var versionList: [DocumentVersion] = []

  private var topViewController: UIViewController!
  private var stepViewModel: KYCStepViewModel!
  private var currentDocumentVersion: DocumentVersion?

  private var currentDocumentHandler: DocumentHandler?
  private var completion: ((Result<KYCStepViewModel, KYCStepError>) -> Void)?

  init(for documents: [DocumentModel], of stepVM: KYCStepViewModel) {
    stepViewModel = stepVM
    versionList = []
    for eachDoc in documents {
      if var docVersions = eachDoc.versions, !docVersions.isEmpty {
        docVersions = docVersions.compactMap { model in
          var obj = model
          obj.docID = eachDoc.id ?? ""
          if obj.isHidden == true {
            return nil
          }
          return obj
        }

        versionList.append(contentsOf: docVersions)
      }
    }
  }

  func bind(topVC: UIViewController, callback: @escaping (Result<KYCStepViewModel, KYCStepError>) -> Void) {
    completion = callback
    topViewController = topVC
  }

  func onVersionPressed(version: DocumentVersion) {
    start(for: version.docID, docStep: (version.steps?.first)!, for: version)
  }

  func start(for docID: String, docStep: DocumentStepModel? = nil, for version: DocumentVersion? = nil) {
    guard let completion = completion else { return }

    // Determining version to use
    if let docVersion = version {
      currentDocumentVersion = docVersion
    } else {
      // If no version is given, it is safe to assume it's single version.
      currentDocumentVersion = versionList.first
    }

    guard let currentDocumentVersion = currentDocumentVersion else {
      completion(.failure(.configError))
      return
    }

    var step: DocumentStepModel?
    // Determining step to use
    if let stepToRun = docStep {
      step = stepToRun
    } else {
      // If no step is given, it is safe to assume it's single step.
      step = currentDocumentVersion.steps?.first
    }

    guard let step = step else {
      completion(.failure(.configError))
      return
    }
    
    switch DocumentID(rawValue: docID) {
    case .ID, .DL, .PA, .VA:
      currentDocumentHandler = IdHandler(topVC: topViewController, stepVM: stepViewModel, docID: DocumentID(rawValue: docID)!)
      currentDocumentHandler?.start(docStep: step, version: currentDocumentVersion, workingStepIndex: 0, completion: completion)
    case .NF:
      currentDocumentHandler = NFHandler(topVC: topViewController, stepVM: stepViewModel, docID: DocumentID(rawValue: docID)!)
      currentDocumentHandler?.start(docStep: step, version: currentDocumentVersion, workingStepIndex: 0, completion: completion)
    case .SE:
      currentDocumentHandler = SelfieHandler(topVC: topViewController, stepVM: stepViewModel, docID: DocumentID(rawValue: docID)!)
      currentDocumentHandler?.start(docStep: step, version: currentDocumentVersion, workingStepIndex: 0, completion: completion)
//    case .CO, .IB, .UB:
//      currentDocumentHandler = DocumentsHandler(topVC: topViewController, stepVM: stepViewModel, docID: DocumentID(rawValue: docID)!)
//      currentDocumentHandler?.start(docStep: step, version: currentDocumentVersion, workingStepIndex: 1, completion: completion)
    case .IB:
      currentDocumentHandler = AddressHandler(topVC: topViewController, stepVM: stepViewModel, docID: DocumentID(rawValue: docID)!)
      currentDocumentHandler?.start(docStep: step, version: currentDocumentVersion, workingStepIndex: 0, completion: completion)
    case .SG:
      currentDocumentHandler = SignatureHandler(topVC: topViewController, stepVM: stepViewModel, docID: DocumentID(rawValue: docID)!)
      currentDocumentHandler?.start(docStep: step, version: currentDocumentVersion, workingStepIndex: 0, completion: completion)
    default:
      currentDocumentHandler = DocumentsHandler(topVC: topViewController, stepVM: stepViewModel, docID: .OD(docID))
      currentDocumentHandler?.start(docStep: step, version: currentDocumentVersion, workingStepIndex: 1, completion: completion)

      return
    }
            
  }

  func upload(completion: @escaping ((Bool?, [String : Any]?) -> Void)) {
    currentDocumentHandler?.upload(completion: completion)
  }
}
