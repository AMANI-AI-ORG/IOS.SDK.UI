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
  
  func start(
    for docID: String,
    docStep: DocumentStepModel? = nil,
    for version: DocumentVersion? = nil
  ) {
    
    guard let completion else {
      return
    }
    
      // MARK: - Resolve version
    
    if let version {
      currentDocumentVersion = version
    } else {
      currentDocumentVersion = versionList.first
    }
    
    guard let currentDocumentVersion else {
      completion(.failure(.configError))
      return
    }
    
      // MARK: - Resolve step
    
    let step: DocumentStepModel?
    
    if let docStep {
      step = docStep
    } else {
      step = currentDocumentVersion.steps?.first
    }
    
    guard let step else {
      completion(.failure(.configError))
      return
    }
    
    let resolvedDocumentID =
    DocumentID(rawValue: docID)
    ?? .OD(docID)
    
      // MARK: - Source based handlers
    
    let documentSource = currentDocumentVersion
      .documentSource?
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .lowercased()
    
    switch documentSource {
      
    case "gallery":
      
      currentDocumentHandler = GalleryDocumentHandler(
        topVC: topViewController,
        stepVM: stepViewModel,
        docID: resolvedDocumentID
      )
      
    case "pdffile":
      
      currentDocumentHandler = PDFDocumentHandler(
        topVC: topViewController,
        stepVM: stepViewModel,
        docID: resolvedDocumentID
      )
      
    default:
      
      currentDocumentHandler = makeDefaultHandler(
        for: docID
      )
    }
    
    guard let currentDocumentHandler else {
      completion(.failure(.configError))
      return
    }
    
    currentDocumentHandler.start(
      docStep: step,
      version: currentDocumentVersion,
      workingStepIndex: 0,
      completion: completion
    )
  }

  func upload(completion: @escaping ((Bool?, [String : Any]?) -> Void)) {
    currentDocumentHandler?.upload(completion: completion)
  }
  
  private func makeDefaultHandler(
    for docID: String
  ) -> DocumentHandler {
    
    switch DocumentID(rawValue: docID) {
      
    case .ID, .DL, .PA, .VA:
      
      return IdHandler(
        topVC: topViewController,
        stepVM: stepViewModel,
        docID: DocumentID(rawValue: docID)!
      )
      
    case .NF:
      
      return NFHandler(
        topVC: topViewController,
        stepVM: stepViewModel,
        docID: .NF
      )
      
    case .SE:
      
      return SelfieHandler(
        topVC: topViewController,
        stepVM: stepViewModel,
        docID: .SE
      )
      
    case .ST:
      
      return SpeechHandler(
        topVC: topViewController,
        stepVM: stepViewModel,
        docID: .ST
      )
      
    case .IB:
      
      return AddressHandler(
        topVC: topViewController,
        stepVM: stepViewModel,
        docID: .IB
      )
      
    case .SG:
      
      return SignatureHandler(
        topVC: topViewController,
        stepVM: stepViewModel,
        docID: .SG
      )
      
    default:
      
      return DocumentsHandler(
        topVC: topViewController,
        stepVM: stepViewModel,
        docID: .OD(docID)
      )
    }
  }
}
