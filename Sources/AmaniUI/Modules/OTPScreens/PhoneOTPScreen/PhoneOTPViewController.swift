//
//  PhoneOTPViewController.swift
//  AmaniUI
//
//  Created by Deniz Can on 26.12.2023.
//

import Foundation
import UIKit
import AmaniSDK
#if canImport(AmaniLocalization)
import AmaniLocalization
#endif

class PhoneOTPScreenViewController: KeyboardAvoidanceViewController {
  private var phoneOTPView: PhoneOTPView!
  private var phoneOTPViewModel: PhoneOTPViewModel!
  
  private var handler: (() -> Void)? = nil
  private var docVersion: DocumentVersion? = nil
  private var stepVM: KYCStepViewModel?
  
  override init() {
    super.init()
      guard let appConfig = try? Amani.sharedInstance.appConfig().getApplicationConfig() else {
          print("AppConfigError")
          return
      }
    
    phoneOTPView = PhoneOTPView()
    phoneOTPView.appConfig = appConfig
    phoneOTPViewModel = PhoneOTPViewModel()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    #if canImport(AmaniLocalization)
    self.title = AmaniLocalization.localizedString(forKey: "phone_phone_captureTitle")
    #else
    self.title = docVersion?.steps?.first?.captureTitle ?? "Verify Phone Number"
    #endif
    phoneOTPView.bind(withViewModel: phoneOTPViewModel, withDocument: self.docVersion)
    phoneOTPView.setCompletion {[weak self] in
      let checkSMSViewController = CheckSMSViewController()
      checkSMSViewController.bind(with: (self?.stepVM)!)
      checkSMSViewController.setupCompletionHandler {
        if let handler = self?.handler {
          handler()
        }
      }
      
      self?.navigationController?.pushViewController(
        checkSMSViewController,
        animated: true
      )
    }
    
    view.backgroundColor = UIColor(hexString: "#EEF4FA")
    addPoweredByIcon()
    
    contentView.addSubview(phoneOTPView)
    phoneOTPView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      phoneOTPView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      phoneOTPView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20.0),
      phoneOTPView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20.0),
    ])
      
      phoneOTPView.selectCountryButtonAction = { [weak self] in
                  self?.presentCountryPicker()
              }
  }
  
  func setCompletionHandler(_ handler: @escaping (() -> Void)) {
    self.handler = handler
  }
  
  func bind(stepVM: KYCStepViewModel?) {
    self.docVersion = stepVM?.documents.first?.versions?.first
    self.stepVM = stepVM
  }
    
    func presentCountryPicker() {
            let countryPicker = CountryPickerViewController()
            countryPicker.selectedCountry = "TR"
            countryPicker.delegate = self
            present(countryPicker, animated: true)
        }
  
}

extension PhoneOTPScreenViewController: CountryPickerDelegate {
    func countryPicker(didSelect country: Country) {
        // Update the phone input field with the selected country code
        phoneOTPView.phoneInput.field.text = "\(("+" + country.phoneCode))"
        phoneOTPView.dialCodeDecimal = country.phoneCode.count
        guard let countryFlagLabel = phoneOTPView.selectCountryView.subviews.compactMap({ $0 as? UILabel }).first else {
                   return
               }
        countryFlagLabel.text = "\(country.isoCode.getFlag())"
//        phoneOTPView.selectCountryButton.setTitle("\(country.isoCode.getFlag())", for: .normal)
    }
}
