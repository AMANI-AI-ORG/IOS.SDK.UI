//
//  GalleryDocumentHandler.swift
//  Pods
//
//  Created by Bedri Doğan on 10.09.2026.
//



import PhotosUI
import AmaniSDK

final class GalleryDocumentHandler: NSObject, DocumentHandler {
  
  weak var topVC: UIViewController?
  
  var stepViewModel: KYCStepViewModel
  var docID: DocumentID
  var stepView: UIView?
  
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
    
    let infoVC = DocumentUploadInfoViewController()
    
    infoVC.bind(
      documentVersion: version
    ) { [weak self, weak infoVC] in
      
      guard let self, let infoVC else {
        return
      }
      
      self.openGallery(from: infoVC)
    }
    
    topVC?.navigationController?.pushViewController(
      infoVC,
      animated: true
    )
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

@available(iOS 14.0, *)
extension GalleryDocumentHandler: PHPickerViewControllerDelegate {
  
  func picker(
    _ picker: PHPickerViewController,
    didFinishPicking results: [PHPickerResult]
  ) {
    
    guard let result = results.first else {
      picker.dismiss(animated: true)
      return
    }
    
    guard result.itemProvider.canLoadObject(
      ofClass: UIImage.self
    ) else {
      
      picker.dismiss(animated: true)
      return
    }
    
    result.itemProvider.loadObject(
      ofClass: UIImage.self
    ) { [weak self, weak picker] object, error in
      
      guard
        let self,
        let image = object as? UIImage
      else {
        
        DispatchQueue.main.async {
          picker?.dismiss(animated: true)
        }
        
        return
      }
      
      self.handleSelectedImage(
        image,
        picker: picker
      )
    }
  }
}
private extension GalleryDocumentHandler {
  
  func handleSelectedImage(
    _ image: UIImage,
    picker: UIViewController?
  ) {
    
    guard let imageData = image.jpegData(
      compressionQuality: 0.95
    ) else {
      return
    }
    
    files = [
      FileWithType(
        data: imageData,
        dataType: acceptedFileTypes.jpg.rawValue
      )
    ]
    
    DispatchQueue.main.async { [weak self] in
      
      guard let self else {
        return
      }
      
      picker?.dismiss(
        animated: true
      ) { [weak self] in
        
        self?.finishSelection()
      }
    }
  }
  
  func finishSelection() {
    
    guard let callback else {
      return
    }
    
    callback(
      .success(stepViewModel)
    )
    
    topVC?
      .navigationController?
      .popToViewController(
        ofClass: HomeViewController.self
      )
  }
}

extension GalleryDocumentHandler:
  UIImagePickerControllerDelegate,
  UINavigationControllerDelegate {
  
  func imagePickerController(
    _ picker: UIImagePickerController,
    didFinishPickingMediaWithInfo info: [
      UIImagePickerController.InfoKey: Any
    ]
  ) {
    
    guard let image = info[.originalImage] as? UIImage else {
      picker.dismiss(animated: true)
      return
    }
    
    handleSelectedImage(
      image,
      picker: picker
    )
  }
  
  func imagePickerControllerDidCancel(
    _ picker: UIImagePickerController
  ) {
    
    picker.dismiss(animated: true)
  }
}

private extension GalleryDocumentHandler {
  
  func openGallery(from viewController: UIViewController) {
    
    if #available(iOS 14.0, *) {
      
      var configuration = PHPickerConfiguration()
      configuration.filter = .images
      configuration.selectionLimit = 1
      
      let picker = PHPickerViewController(
        configuration: configuration
      )
      
      picker.delegate = self
      
      viewController.present(
        picker,
        animated: true
      )
      
    } else {
      
      let picker = UIImagePickerController()
      
      picker.sourceType = .photoLibrary
      picker.delegate = self
      
      viewController.present(
        picker,
        animated: true
      )
    }
  }
}
