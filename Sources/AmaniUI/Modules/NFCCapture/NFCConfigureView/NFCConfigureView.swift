//
//  NFCConfigureView.swift
//  Pods
//
//  Created by Bedri Doğan on 12.12.2024.
//

import Foundation
import UIKit
import AmaniSDK

class NFCConfigureView: UIView {
    // MARK: Form Area
  private var descriptionLabel = UILabel()
  private var documentNumbers = UILabel()
  private var documentNoInput = RoundedTextInput()
  private var dateOfExpiryDate = UILabel()
  private var expirydateInput = RoundedTextInput()
  private var birthdateLabel = UILabel()
  private var birthdateInput = RoundedTextInput()
  private var submitButton = RoundedButton()
  private var formView = UIStackView()
  private var mainStackView = UIStackView()
  private var amaniLogo = UIImageView()
  var setButtonCb: ((NviModel) async -> Void)?
  weak var delegate: AlertDelegate?
  private var newDocumentNo: String?
  private var newbirthDate: String?
  private var newExpiryDate: String?
  
  private lazy var expiryDataPicker: UIDatePicker = {
    let picker = UIDatePicker()
    picker.datePickerMode = .date
    return picker
  }()
  
  private lazy var birthDatePicker: UIDatePicker = {
    let picker = UIDatePicker()
    picker.datePickerMode = .date
    return picker
  }()
  
  var newNviData: NviModel?
  var appConfig: AppConfigModel? {
    didSet {
      guard let config = appConfig else { return }
      setNFCFormUI()
      setupDatePicker()
    }
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
   
   
  }
  
  deinit {
    
  }

  
  required init?(coder: NSCoder) {
  
    fatalError("init(coder:) has not been implemented")
  }
  
  
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    endEditing(true)
  }
 
  
  private func setupDatePicker() {
      // Create the date picker
    expiryDataPicker.datePickerMode = .date
    expiryDataPicker.locale = .current

    birthDatePicker.datePickerMode = .date
    birthDatePicker.locale = .current

    expirydateInput.field.inputView = expiryDataPicker
    birthdateInput.field.inputView = birthDatePicker
      // Handle date picker value changes
    expiryDataPicker.addTarget(self, action: #selector(expiryDataPickerValueChanged(_:)), for: .valueChanged)
    birthDatePicker.addTarget(self, action: #selector(birthDatePickerValueChanged(_:)), for: .valueChanged)
    
  }
  
  @objc private func birthDatePickerValueChanged(_ sender: UIDatePicker) {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyMMdd"
    let selectedDate = dateFormatter.string(from: sender.date)
    self.newbirthDate = selectedDate
  }
  
  @objc private func expiryDataPickerValueChanged(_ sender: UIDatePicker) {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyMMdd"
    let selectedDate = dateFormatter.string(from: sender.date)
    self.newExpiryDate = selectedDate
  }
  
  @objc private func birthdateInputTapped() {
   
    birthdateInput.field.resignFirstResponder()
  }
  
  @objc private func expiryDateInputTapped() {
    expirydateInput.field.resignFirstResponder()
  }
  
  @objc private func dismissBirthDatePicker() {
    birthdateInput.field.resignFirstResponder()
  }
  
  @objc private func dissmissExpiryDatePicker() {
    expirydateInput.field.resignFirstResponder()
  }
  
  @objc private func tapSubmitButton(_ sender: UIButton) {
    debugPrint("submit button basıldı")
//    var docNo = ""
    var birthDate = ""
    var expiryDate = ""
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyMMdd"
    expiryDate = dateFormatter.string(from: expiryDataPicker.date)
    birthDate = dateFormatter.string(from: birthDatePicker.date)
    
    guard let docNo = documentNoInput.field.text else { return }
    
    self.newNviData = NviModel(documentNo: docNo, dateOfBirth: birthDate, dateOfExpire: expiryDate)
    
    Task {
      if let nviData = self.newNviData {
        guard let setButtonCb = self.setButtonCb else { return }
        await setButtonCb(nviData)
      }
     
    }
  }
      
  private func formatAsDate(for input: String) -> String {
      // Assuming the date format is MM / DD / YYYY
    var formattedText = ""
    
    for (index, character) in input.enumerated() {
      if index == 2 || index == 4 {
        formattedText += "/\(character)"
      } else {
        formattedText.append(character)
      }
      
      if formattedText.count > 10 {
        formattedText = String(formattedText.prefix(10))
      }
    }
    
    return formattedText
  }
  
  func setTextsFrom(nvi: NviModel?) {
    
    DispatchQueue.main.async {
      self.documentNoInput.field.text = nvi?.documentNo ?? ""
      
      if let dateOfBirth = nvi?.dateOfBirth,
         let birthDate = self.dateFormatter(dateString: dateOfBirth) {
        self.birthDatePicker.date = birthDate
      }
      
      if let dateOfExpire = nvi?.dateOfExpire,
         let expiryDate = self.dateFormatter(dateString: dateOfExpire) {
        self.expiryDataPicker.date = expiryDate
      }
    }
  }
 
  func triggerAlert() {
    delegate?.showAlert(
      title: "Caution!",
      message: "The dates are not valid. Please set correct dates format",
      actions: [("Ok", .default)]
    ) { index in
    
    }
  }
  
  private func dateFormatter(dateString: String?) -> Date? {
    guard let dateString = dateString, isValidDateFormat(dateString) else {
      print("Invalid date format: \(dateString ?? "nil")")
      self.triggerAlert()
      return nil
    }
    
    let formats = ["yyMMdd", "yyyyMMdd"]
    let dateFormatter = DateFormatter()
    dateFormatter.locale = Locale(identifier: "en_US_POSIX")
    
    for format in formats {
      dateFormatter.dateFormat = format
      if let date = dateFormatter.date(from: dateString) {
        return date
      }
    }
    self.triggerAlert()
    return nil
  }
  
  private func isValidDateFormat(_ dateString: String) -> Bool {
    let validLengths = [6, 8]
    return validLengths.contains(dateString.count) && dateString.range(of: "^[0-9]+$", options: .regularExpression) != nil
  }

  
}

extension NFCConfigureView {
  private func setNFCFormUI() {
    guard let stepConfig = self.appConfig?.stepConfig else { return }
    backgroundColor =  hextoUIColor(hexString: appConfig?.generalconfigs?.appBackground ?? "#EEF4FA")
    self.submitButton.addTarget(self, action: #selector(tapSubmitButton(_:)), for: .touchUpInside)
    var nfcConfigStep = stepConfig.first(where: { $0.title == "Identification"})
    self.descriptionLabel.text = nfcConfigStep?.documents?[0].versions?[0].nfcConfigureTitle ?? "Please check your informations."
    self.descriptionLabel.font = UIFont.systemFont(ofSize: 14.0, weight: .regular)
    self.descriptionLabel.numberOfLines = 1
    self.descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
    self.descriptionLabel.textAlignment = .center
    
    
    self.documentNumbers.text = nfcConfigStep?.documents?[0].versions?[0].documentNoTitle ?? "Document Numbers"
    self.documentNumbers.textColor = hextoUIColor(hexString: "#2020F")
    self.documentNumbers.font = UIFont.systemFont(ofSize: 14.0, weight: .regular)
    self.documentNumbers.numberOfLines = 1
    self.documentNumbers.setContentCompressionResistancePriority(.required, for: .vertical)
    
    self.documentNoInput = RoundedTextInput(
      placeholderText: "",
      borderColor: hextoUIColor(hexString: "#515166"),
      placeholderColor: hextoUIColor(hexString: "#C0C0C0"),
      isPasswordToggleEnabled: false,
      keyboardType: .default
    )
    
    self.dateOfExpiryDate.text = nfcConfigStep?.documents?[0].versions?[0].documentDateOfExpiry ?? "Date of Expiry"
    self.dateOfExpiryDate.textColor = hextoUIColor(hexString: "#2020F")
    self.dateOfExpiryDate.font = UIFont.systemFont(ofSize: 14.0, weight: .regular)
    self.dateOfExpiryDate.numberOfLines = 1
    self.dateOfExpiryDate.setContentCompressionResistancePriority(.required, for: .vertical)
    
    self.expirydateInput = RoundedTextInput(
      placeholderText: "",
      borderColor: hextoUIColor(hexString: "#515166"),
      placeholderColor: hextoUIColor(hexString: "#C0C0C0"),
      isPasswordToggleEnabled: false,
      keyboardType: .numberPad
    )
    
    self.birthdateLabel.text = nfcConfigStep?.documents?[0].versions?[0].documentDateOfBirth ?? "Date of Birth"
    self.birthdateLabel.textColor = hextoUIColor(hexString: "#2020F")
    self.birthdateLabel.font = UIFont.systemFont(ofSize: 14.0, weight: .regular)
    self.birthdateLabel.numberOfLines = 1
    self.birthdateLabel.setContentCompressionResistancePriority(.required, for: .vertical)
    
    self.birthdateInput = RoundedTextInput(
      placeholderText: "",
      borderColor: hextoUIColor(hexString: "#515166"),
      placeholderColor: hextoUIColor(hexString: "#C0C0C0"),
      isPasswordToggleEnabled: false,
      keyboardType: .numberPad
    )
    self.submitButton.translatesAutoresizingMaskIntoConstraints = false
    
    submitButton.setTitleColor(hextoUIColor(hexString: appConfig?.generalconfigs?.primaryButtonTextColor ?? ThemeColor.whiteColor.toHexString()), for: .normal)
    submitButton.backgroundColor = hextoUIColor(hexString: appConfig?.generalconfigs?.primaryButtonBackgroundColor ?? ThemeColor.whiteColor.toHexString())
    submitButton.addCornerRadiousWith(radious: CGFloat(appConfig?.generalconfigs?.buttonRadius ?? 10))
    submitButton.setTitle(appConfig?.generalconfigs?.continueText ?? "Devam", for: .normal)
//    let color = hextoUIColor(hexString: appConfig?.generalconfigs?.primaryButtonBackgroundColor ?? "#EA3365")
  
//    
//    self.submitButton.setTitle(appConfig?.generalconfigs?.continueText ?? "Continue", for: .normal)
//    self.submitButton.setTitleColor(.white, for: .normal)
//    self.submitButton.backgroundColor = color
//    
//    self.submitButton.layer.borderColor = color.cgColor
//    self.submitButton.layer.cornerRadius = 24.0
//    
//    self.submitButton.titleLabel?.font = UIFont.systemFont(ofSize: 16.0, weight: .medium)
//    self.submitButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
    let textColor = appConfig?.generalconfigs?.appFontColor ?? "ffffff"
    self.amaniLogo = UIImageView(image: UIImage(named: "ic_poweredBy", in: AmaniUI.sharedInstance.getBundle(), with: nil)?.withRenderingMode(.alwaysTemplate))
    self.amaniLogo.translatesAutoresizingMaskIntoConstraints = false
    self.amaniLogo.contentMode = .scaleAspectFit
    self.amaniLogo.clipsToBounds = true
    self.amaniLogo.tintAdjustmentMode = .normal
    self.amaniLogo.tintColor = hextoUIColor(hexString: textColor)
    
    
    self.formView = UIStackView(arrangedSubviews: [
      descriptionLabel, documentNumbers, documentNoInput,
      birthdateLabel, birthdateInput,
      dateOfExpiryDate, expirydateInput,
    ])
    
    self.formView.axis = .vertical
    self.formView.distribution = .fillProportionally
    self.formView.spacing = 6.0
    
    self.formView.setCustomSpacing(100, after: descriptionLabel)
    
    
    self.mainStackView = UIStackView(arrangedSubviews: [
      
      formView,
    ])
    
    self.mainStackView.axis = .vertical
    self.mainStackView.distribution = .fill
      //    self.mainStackView.isLayoutMarginsRelativeArrangement = true
    self.mainStackView.spacing = 0.0
    
    
//    self.mainStackView.setCustomSpacing(230.0, after: formView)
//    self.mainStackView.setCustomSpacing(8.0, after: submitButton)
    
    self.mainStackView.translatesAutoresizingMaskIntoConstraints = false
    
    let birthDateGesture = UITapGestureRecognizer(target: self, action: #selector(birthdateInputTapped))
    let expiryDateGesture = UITapGestureRecognizer(target: self, action: #selector(expiryDateInputTapped))
    
    birthdateInput.field.addGestureRecognizer(birthDateGesture)
    expirydateInput.field.addGestureRecognizer(expiryDateGesture)
      //        addSubviews()
    setNFCFormUIConstraints()
  }
  private func setNFCFormUIConstraints() {
    addSubview(mainStackView)
    addSubview(submitButton)
    addSubview(amaniLogo)
    NSLayoutConstraint.activate([
  
      descriptionLabel.heightAnchor.constraint(equalToConstant: 20),
      mainStackView.topAnchor.constraint(equalTo: topAnchor, constant: 32),
      mainStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
      mainStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
//      mainStackView.centerYAnchor.constraint(equalTo: centerYAnchor),
//      mainStackView.topAnchor.constraint(equalTo: topAnchor, constant: 32),
      
//      mainStackView.bottomAnchor.constraint(equalTo: submitButton.topAnchor, constant: -5),
      
      submitButton.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 16),
      submitButton.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -16),
      submitButton.bottomAnchor.constraint(equalTo: amaniLogo.topAnchor, constant: -20),
      submitButton.heightAnchor.constraint(equalToConstant: 50.0),
      
      amaniLogo.widthAnchor.constraint(equalToConstant: 114),
      amaniLogo.heightAnchor.constraint(equalToConstant: 13),
      amaniLogo.centerXAnchor.constraint(equalTo: centerXAnchor),
      amaniLogo.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -30)
    ])
  
    expirydateInput.field.addSubview(expiryDataPicker)
    expiryDataPicker.translatesAutoresizingMaskIntoConstraints = false
    expiryDataPicker.contentHorizontalAlignment = .center
    
    birthdateInput.field.addSubview(birthDatePicker)
    birthDatePicker.translatesAutoresizingMaskIntoConstraints = false
    birthDatePicker.contentHorizontalAlignment = .center
    
    NSLayoutConstraint.activate([
      expiryDataPicker.leadingAnchor.constraint(equalTo: expirydateInput.field.leadingAnchor),
      expiryDataPicker.centerYAnchor.constraint(equalTo: expirydateInput.field.centerYAnchor),
      birthDatePicker.leadingAnchor.constraint(equalTo: birthdateInput.field.leadingAnchor),
      birthDatePicker.centerYAnchor.constraint(equalTo: birthdateInput.field.centerYAnchor),
    ])
    documentNoInput.setDelegate(delegate: self)
    birthdateInput.setDelegate(delegate: self)
    expirydateInput.setDelegate(delegate: self)
  }
}

extension NFCConfigureView: UITextFieldDelegate {

  func textFieldDidChangeSelection(_ textField: UITextField) {
    if textField == documentNoInput.field {
      documentNoInput.field.text = textField.text
      if let text = documentNoInput.field.text {
        self.newDocumentNo = text
      }
     
    }
  }

  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    if textField == documentNoInput {
      expirydateInput.becomeFirstResponder()
    } else if textField == expirydateInput {
      birthdateInput.becomeFirstResponder()
    } else if textField == birthdateInput {
      return true
    }
    return true
  }
  
//  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
//    guard textField == birthdateInput.field else {
//      return true
//    }
//    
//    guard let text = textField.text else {
//      return true
//    }
//    
//    let cleanedText = text.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
//    let rangeOfTextToReplace = Range(range, in: cleanedText) ?? cleanedText.endIndex ..< cleanedText.endIndex
//    
//      // Check if it's a backspace press
//    if string.isEmpty {
//      var newText = cleanedText
//      if text.count == 1 {
//        newText = ""
//        textField.text = newText
////        viewModel.birthDay = newText
//        return false
//      }
//      
//      newText.remove(at: newText.index(before: rangeOfTextToReplace.lowerBound))
//      newText = formatAsDate(for: newText)
//      textField.text = newText
//      
//      return false
//    }
//    
//    var newText = cleanedText
//    newText.replaceSubrange(rangeOfTextToReplace, with: string)
//    newText = formatAsDate(for: newText)
//    textField.text = newText
////    viewModel.birthDay = newText
//    return false
//  }
}

