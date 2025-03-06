//
//  AdressHandler.swift
//  AmaniUI
//
//  Created by Münir Ketizmen on 5.03.2025.
//
import Foundation
import UIKit
import AmaniSDK
import MobileCoreServices


class AddressHandler: NSObject, DocumentHandler {
  
  var stepView: UIView? = nil
  weak var topVC: UIViewController?
  var stepViewModel: KYCStepViewModel
  var docID: DocumentID
  var files: [FileWithType] = []
  var callback:((Result<KYCStepViewModel, KYCStepError>) -> Void)?
  private let ibModule = Amani.sharedInstance.document()
  
  required init(topVC: UIViewController, stepVM: KYCStepViewModel, docID: DocumentID) {
    self.topVC = topVC
    self.stepViewModel = stepVM
    self.docID = docID
  }
  
  func start(docStep: AmaniSDK.DocumentStepModel, version: AmaniSDK.DocumentVersion, workingStepIndex: Int, completion: @escaping (Result<KYCStepViewModel, KYCStepError>) -> Void) {
    ibModule.setType(type: version.type!)
    callback = completion
      // Specify only PDF type
    DispatchQueue.main.async{
      let documentPicker = UIDocumentPickerViewController(documentTypes: [kUTTypePDF as String], in: .import)
      documentPicker.delegate = self
      documentPicker.allowsMultipleSelection = false
      self.topVC?.present(documentPicker, animated: true)
      
    }

  }
  
  func upload(completion: @escaping ((Bool?, [String : Any]?) -> Void)) {
    if !(files.isEmpty){
      ibModule.upload(location:  AmaniUI.sharedInstance.location, files: files){[weak self] result,arg    in
        completion(result,nil)
      }
    }

  }
  
  
}
extension AddressHandler: UIDocumentPickerDelegate{
  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
    guard let filePath = urls.first else { return }
    let shouldStopAccessing = filePath.startAccessingSecurityScopedResource()
    if shouldStopAccessing {
      filePath.stopAccessingSecurityScopedResource()
    }
    do {
      let fileData = try Data.init(contentsOf: filePath)
      self.files = [FileWithType(data: fileData, dataType: acceptedFileTypes.pdf.rawValue )]
      guard let callback = self.callback else {
        return
      }
      callback(.success(self.stepViewModel))
      self.topVC?.navigationController?.popToViewController(ofClass: HomeViewController.self)
        //          self.uploadFile(completion: <#T##StepUploadCallback##StepUploadCallback##(Bool?, [AmaniError]?) -> Void#>)
    }catch {
      print(error)
    }
  }
  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    controller.dismiss(animated: true )
  }
}
