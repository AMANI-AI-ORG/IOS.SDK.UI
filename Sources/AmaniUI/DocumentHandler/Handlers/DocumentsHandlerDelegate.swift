//
//  DocumentsPickerDelegate.swift
//  AmaniUIv1
//
//  Created by Münir Ketizmen on 4.04.2023.
//

import UIKit
import AmaniSDK

/// **UIDocumentPickerDelegate** methods.
extension DocumentsHandler: UIDocumentPickerDelegate{
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
      
        guard let filePath = urls.first else { return }
        do {
            let fileData = try Data.init(contentsOf: filePath)
          self.files = [FileWithType(data: fileData, dataType: acceptedFileTypes.pdf.rawValue )]
          self.stepView?.removeFromSuperview()
          self.callback!(.success(self.stepViewModel))
          self.topVC?.navigationController?.popToViewController(ofClass: HomeViewController.self)
//          self.uploadFile(completion: <#T##StepUploadCallback##StepUploadCallback##(Bool?, [AmaniError]?) -> Void#>)
        } catch (let error) {
            print(error)
        }
    }
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
      controller.dismiss(animated: true )
    }
}

