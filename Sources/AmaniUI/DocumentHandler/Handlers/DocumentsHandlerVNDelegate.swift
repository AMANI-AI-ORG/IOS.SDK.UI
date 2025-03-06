//
//  DocumentsHandlerVNDelegate.swift
//  AmaniUI
//
//  Created by Bedri Doğan on 27.09.2024.
//

import Foundation
import VisionKit
import AmaniSDK

//MARK: All process relate with visionkit document capture controller.
extension DocumentsHandler: VNDocumentCameraViewControllerDelegate {
   
    func startUploadSession(_ image: [UIImage]?) {
        guard let images = image, !images.isEmpty else {
               print("No images to upload.")
               return
           }
        
        for image in images {
            if let imageData = image.jpegData(compressionQuality: 1) {
                self.files?.append(FileWithType(data: imageData, dataType: acceptedFileTypes.jpg.rawValue))
            }
        }
        
        self.stepView?.removeFromSuperview()
        self.callback!(.success(self.stepViewModel))
      self.topVC?.navigationController?.popToViewController(ofClass: HomeViewController.self)
        
//        if let pdfURL = toPDF(images: images, withFilename: "TUR_IB_0.pdf") {
//               do {
//                   let fileData = try Data(contentsOf: pdfURL)
//                   self.files = [FileWithType(data: fileData, dataType: acceptedFileTypes.pdf.rawValue)]
//                  
//               } catch {
//                   print(error)
//               }
//           }
    }
    
    func startDocumentScanning()  {
        if VNDocumentCameraViewController.isSupported {
            let documentCameraViewController = VNDocumentCameraViewController()
          documentCameraViewController.navigationItem.backBarButtonItem = .none
          
            documentCameraViewController.navigationItem.setHidesBackButton(true, animated: true)
            documentCameraViewController.delegate = self
            addDocumentCameraView(documentCameraViewController)
            
        } else {
            print("Bu cihaz VisionKit taramasını desteklemiyor.")
        }
    }
    
    func setupCameraContainerView() {
        cameraContainerView.translatesAutoresizingMaskIntoConstraints = false
        ContainerVC.view.addSubview(cameraContainerView)
//        view.addSubview(cameraContainerView)
        
        NSLayoutConstraint.activate([
            cameraContainerView.leadingAnchor.constraint(equalTo: ContainerVC.view.safeAreaLayoutGuide.leadingAnchor),
            cameraContainerView.trailingAnchor.constraint(equalTo: ContainerVC.view.safeAreaLayoutGuide.trailingAnchor),
            cameraContainerView.topAnchor.constraint(equalTo: ContainerVC.view.safeAreaLayoutGuide.topAnchor),
            cameraContainerView.bottomAnchor.constraint(equalTo: ContainerVC.view.bottomAnchor)
        ])
    }
    
    func addDocumentCameraView(_ documentCameraVC: VNDocumentCameraViewController) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            ContainerVC.addChild(documentCameraVC)
            documentCameraVC.view.frame = cameraContainerView.bounds
            cameraContainerView.addSubview(documentCameraVC.view)
            documentCameraVC.didMove(toParent: ContainerVC)
        }
//        DispatchQueue.main.async { [weak self] in
//                guard let self = self else { return }
//                self.ContainerVC.addChild(documentCameraVC)
//                documentCameraVC.view.translatesAutoresizingMaskIntoConstraints = false
//                self.cameraContainerView.addSubview(documentCameraVC.view)
//                NSLayoutConstraint.activate([
//                    documentCameraVC.view.leadingAnchor.constraint(equalTo: self.cameraContainerView.leadingAnchor),
//                    documentCameraVC.view.trailingAnchor.constraint(equalTo: self.cameraContainerView.trailingAnchor),
//                    documentCameraVC.view.topAnchor.constraint(equalTo: self.cameraContainerView.topAnchor),
//                    documentCameraVC.view.bottomAnchor.constraint(equalTo: self.cameraContainerView.bottomAnchor)
//                ])
//                documentCameraVC.didMove(toParent: self.ContainerVC)
//            }
       
    }
    
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
        // Process the scanned pages
        
        for pageNumber in 0..<scan.pageCount {
            print("pageNumber değeri \(pageNumber)")
            let image = scan.imageOfPage(at: pageNumber)
            scannedImages.append(image)
//            if scannedImages.count <= 3 {
//                scannedImages.append(image)
//            }
            
        }
        startUploadSession(scannedImages)
      
    }
    
    func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
     
//      self.ContainerVC.dismiss(animated: true)
        ContainerVC.navigationController?.popViewController(animated: true)

    }
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
      
        print(error)
        ContainerVC.navigationController?.popViewController(animated: true)
    }
    
  
}
