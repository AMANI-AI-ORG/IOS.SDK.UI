//
//  ProfileInfoView.swift
//  AmaniUI
//
//  Created by Deniz Can on 22.01.2024.
//

import AmaniSDK
import Combine
import Foundation
import UIKit
#if canImport(AmaniLocalization)
import AmaniLocalization
#endif

class ProfileInfoView: UIView {
  private var cancellables = Set<AnyCancellable>()
  private var viewModel: ProfileInfoViewModel!
  private var completionHandler: (() -> Void)?
  private let nameValidationString: String = "Name should not exceed 64 characters"
  private let surnameValidationString: String = "Surname should not exceed 32 characters"
  var appConfig: AppConfigModel? {
        didSet {
            guard let config = appConfig else { return }
            setupUI()
            setupErrorHandling()
        }
    }

  // MARK: Form Area

  private lazy var nameLegend: UILabel = {
    let label = UILabel()
    label.text = "Name"
    label.textColor = UIColor(hexString: "#2020F")
    label.font = UIFont.systemFont(ofSize: 14.0, weight: .regular)
    label.numberOfLines = 1
    label.setContentCompressionResistancePriority(.required, for: .vertical)
    return label
  }()

  private lazy var nameInput: RoundedTextInput = {
    let input = RoundedTextInput(
      placeholderText: "Enter your name",
      borderColor: UIColor(hexString: "#515166"),
      placeholderColor: UIColor(hexString: "#C0C0C0"),
      isPasswordToggleEnabled: false,
      keyboardType: .default
    )
    return input
  }()

  private lazy var surnameLegend: UILabel = {
    let label = UILabel()
    label.text = "Surname"
    label.textColor = UIColor(hexString: "#2020F")
    label.font = UIFont.systemFont(ofSize: 14.0, weight: .regular)
    label.numberOfLines = 1
    label.setContentCompressionResistancePriority(.required, for: .vertical)
    return label
  }()

  private lazy var surnameInput: RoundedTextInput = {
    let input = RoundedTextInput(
      placeholderText: "Enter your surname",
      borderColor: UIColor(hexString: "#515166"),
      placeholderColor: UIColor(hexString: "#C0C0C0"),
      isPasswordToggleEnabled: false,
      keyboardType: .default
    )
    return input
  }()

  private lazy var birthdateLabel: UILabel = {
    let label = UILabel()
    label.text = "Date of Birth"
    label.textColor = UIColor(hexString: "#2020F")
    label.font = UIFont.systemFont(ofSize: 14.0, weight: .regular)
    label.numberOfLines = 1
    label.setContentCompressionResistancePriority(.required, for: .vertical)
    return label
  }()

  private lazy var birthdateInput: RoundedTextInput = {
    let input = RoundedTextInput(
      placeholderText: "",
      borderColor: UIColor(hexString: "#515166"),
      placeholderColor: UIColor(hexString: "#C0C0C0"),
      isPasswordToggleEnabled: false,
      keyboardType: .numberPad
    )
    return input
  }()
    
    private lazy var datePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.addTarget(self, action: #selector(datePickerValueChanged(_:)), for: .valueChanged)
        return picker
    }()

  private lazy var submitButton: RoundedButton = {

    let button = RoundedButton(
     withTitle: appConfig?.generalconfigs?.continueText ?? "Continue",
     withColor: UIColor(hexString: appConfig?.generalconfigs?.primaryButtonBackgroundColor ?? "#EA3365")
    )
    return button
  }()

  private lazy var formView: UIStackView = {
    let stackView = UIStackView(arrangedSubviews: [
      nameLegend, nameInput,
      surnameLegend, surnameInput,
      birthdateLabel, birthdateInput,
    ])

    stackView.axis = .vertical
    stackView.distribution = .fill
    stackView.spacing = 6.0

    return stackView
  }()

  private lazy var mainStackView: UIStackView = {
    let stackView = UIStackView(arrangedSubviews: [
      formView,
      submitButton,
    ])

    stackView.axis = .vertical
    stackView.distribution = .fill
    stackView.spacing = 0.0

    stackView.setCustomSpacing(100.0, after: formView)

    return stackView
  }()

  override init(frame: CGRect) {
    super.init(frame: frame)
 
//    setupDatePicker()
 
  }

  // MARK: Initializers

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {
    NotificationCenter.default.removeObserver(
      self,
      name: NSNotification.Name(
        AppConstants.AmaniDelegateNotifications.onError.rawValue
      ),
      object: nil
    )
  }

  // MARK: UI Setup

    func setupUI() {
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(mainStackView)
        NSLayoutConstraint.activate([
            mainStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            mainStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            mainStackView.topAnchor.constraint(equalTo: topAnchor),
            mainStackView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        
        birthdateInput.field.addSubview(datePicker)
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        datePicker.contentHorizontalAlignment = .center
        NSLayoutConstraint.activate([
            datePicker.leadingAnchor.constraint(equalTo: birthdateInput.field.leadingAnchor),
//            datePicker.trailingAnchor.constraint(equalTo: birthdateInput.field.trailingAnchor),
            datePicker.centerYAnchor.constraint(equalTo: birthdateInput.field.centerYAnchor),
        ])
        
        // Initially set the input view of the birthdate input field to nil
//        birthdateInput.field.inputView = nil
//        self.birthdateInput.field.setInputViewDatePicker(target: self, selector: #selector(doneTapped))
        // Add tap gesture recognizer to the birthdate input field
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(birthdateInputTapped))
        birthdateInput.field.addGestureRecognizer(tapGesture)
//        addSubviews()
    }
    
//    @objc func doneTapped(){
//        if let datePicker = self.birthdateInput.field.inputView as? UIDatePicker{
//            let dateFormatter = DateFormatter()
//            dateFormatter.dateFormat = "dd/MM/yyyy"
//            let selectedDate = dateFormatter.string(from: datePicker.date)
//    //        birthdateInput.field.text = selectedDate
//            
//            viewModel.birthDay = selectedDate
//        }
//        self.birthdateInput.field.resignFirstResponder()
//    }

    @objc private func birthdateInputTapped() {
        datePicker.becomeFirstResponder()
//        // Set the input view of the birthdate input field to the date picker
//        birthdateInput.field.inputView = datePicker
//        
//        // Calculate the center point of the screen
//        let screenCenter = CGPoint(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2)
//        
//        // Set the frame of the date picker to ensure it's centered
//        datePicker.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 200)
//        datePicker.center = screenCenter
//        
//        // Force the birthdate input field to become first responder to show the date picker
//        birthdateInput.field.becomeFirstResponder()
    }

  func setupErrorHandling() {
    NotificationCenter.default
      .addObserver(
        self,
        selector: #selector(didReceiveError(_:)),
        name: Notification.Name(
          AppConstants.AmaniDelegateNotifications.onError.rawValue
        ),
        object: nil)
  }
    
    private func setupDatePicker() {
        // Create the date picker
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        datePicker.locale = .current
        // Set the inputView of the birthday input field to the date picker
        birthdateInput.field.inputView = datePicker

        // Handle date picker value changes
        datePicker.addTarget(self, action: #selector(datePickerValueChanged(_:)), for: .valueChanged)
    }
 
    @objc private func datePickerValueChanged(_ sender: UIDatePicker) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        let selectedDate = dateFormatter.string(from: sender.date)
//        birthdateInput.field.text = selectedDate
        
        viewModel.birthDay = selectedDate
    }

    @objc private func dismissDatePicker() {
        birthdateInput.field.resignFirstResponder()
    }


  @objc func didReceiveError(_ notification: Notification) {
    if let errorObjc = notification.object as? [String: Any] {
      let type = errorObjc["type"] as! String
      let errors = errorObjc["errors"] as! [[String: String]]
      if type == "customer_error" {
        print(errors)
      }
    }
  }

  func bind(
    withViewModel viewModel: ProfileInfoViewModel,
    withDocument document: DocumentVersion?
    
  ) {
    nameInput.setDelegate(delegate: self)
    surnameInput.setDelegate(delegate: self)
    birthdateInput.setDelegate(delegate: self)

    nameInput.textPublisher
      .compactMap { $0 }
      .assign(to: \.name, on: viewModel)
      .store(in: &cancellables)

    surnameInput.textPublisher
      .compactMap { $0 }
      .assign(to: \.surname, on: viewModel)
      .store(in: &cancellables)

    birthdateInput.textPublisher
      .compactMap { $0 }
      .assign(to: \.birthDay, on: viewModel)
      .store(in: &cancellables)

    submitButton.bind {
      viewModel.submitForm()
    }

    viewModel.isNameValidPublisher
      .sink(receiveValue: { [weak self] isNameValid in
        if !isNameValid {
          self?.nameInput.showError(message: "Given name is too long")
        } else {
          self?.nameInput.hideError()
        }
      }).store(in: &cancellables)

    viewModel.isSurnameValidPublisher
      .sink(receiveValue: { [weak self] isNameValid in
        if !isNameValid {
          self?.nameInput.showError(message: "Given surname is too long")
        } else {
          self?.nameInput.hideError()
        }
      }).store(in: &cancellables)

    viewModel.isNameValidPublisher
      .sink(receiveValue: { [weak self] isNameValid in
        if !isNameValid {
          self?.nameInput.showError(message: "Given name is too long")
        } else {
          self?.nameInput.hideError()
        }
      }).store(in: &cancellables)

    viewModel.isBdayValidPublisher
      .sink(receiveValue: { [weak self] isBdayValid in
        if !isBdayValid {
          self?.birthdateInput.showError(message: "Invalid date of birth")
        } else {
          self?.birthdateInput.hideError()
        }
      }).store(in: &cancellables)
    
    viewModel.$state
      .sink { [weak self] state in
        switch state {
        case .loading:
          self?.toggleTextInputs(isEnabled: false)
          self?.submitButton.showActivityIndicator()
        case .success:
          DispatchQueue.main.async {
            if let completionHandler = self?.completionHandler {
              completionHandler()
            }
          }
        case .failed:
          self?.toggleTextInputs(isEnabled: true)
          self?.submitButton.hideActivityIndicator()
        case .none:
          break
        }
      }.store(in: &cancellables)
    
    viewModel.$currentErrorToShow.sink {[weak self] error in
      guard let error = error else {return}
      // FIXME: Also update the message in here
      self?.showMsgAlertWithHandler(alertTitle: "Profile Error", message: error, successTitle: "Ok")
      self?.clearTextInputs()
    }.store(in: &cancellables)

    self.viewModel = viewModel
    
    if let doc = document {
      setTextsFrom(document: doc)
    }
  }

  func setCompletion(handler: @escaping () -> Void) {
    completionHandler = handler
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
  
  private func setTextsFrom(document: DocumentVersion) {
      DispatchQueue.main.async {
        #if canImport(AmaniLocalization)
        self.nameLegend.text = AmaniLocalization.localizedString(forKey: "profileInfo_nameTitle")
        self.nameInput.updatePlaceHolder(text: AmaniLocalization.localizedString(forKey: "profileInfo_nameHint"))
        self.surnameLegend.text = AmaniLocalization.localizedString(forKey: "profileInfo_surnameTitle")
        self.surnameInput.updatePlaceHolder(text: AmaniLocalization.localizedString(forKey: "profileInfo_surnameHint"))
        self.birthdateLabel.text = AmaniLocalization.localizedString(forKey: "profileInfo_birthDateTitle")
        #else
        self.nameLegend.text = document.nameTitle!
        self.nameInput.updatePlaceHolder(text: document.nameHint!)
        self.surnameLegend.text = document.surnameTitle!
        self.surnameInput.updatePlaceHolder(text: document.surnameHint!)
        self.birthdateLabel.text = document.birthDateTitle!
//        self.birthdateInput.updatePlaceHolder(text: document.birthDateHint!)
        #endif
    }
  }
  
  private func toggleTextInputs(isEnabled: Bool = true) {
    DispatchQueue.main.async {
      self.nameInput.field.isEnabled = isEnabled
      self.surnameInput.field.isEnabled = isEnabled
      self.birthdateInput.field.isEnabled = isEnabled
    }
  }
  
  private func clearTextInputs() {
    DispatchQueue.main.async {
      self.nameInput.field.text = ""
      self.surnameInput.field.text = ""
      self.birthdateInput.field.text = ""
    }
  }
}

extension ProfileInfoView: UITextFieldDelegate {
//    func textFieldDidBeginEditing(_ textField: UITextField) {
//        if textField == birthdateInput.field {
//            // Open the date picker when the birthdate input field is tapped
//            textField.inputView = datePicker
//        }
//    }
    
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    if textField == nameInput {
      surnameInput.becomeFirstResponder()
    } else if textField == surnameInput {
      birthdateInput.becomeFirstResponder()
    } else if textField == birthdateInput {
      viewModel.submitForm()
      return true
    }
    return true
  }

  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    guard textField == birthdateInput.field else {
      return true
    }

    guard let text = textField.text else {
      return true
    }

    let cleanedText = text.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
    let rangeOfTextToReplace = Range(range, in: cleanedText) ?? cleanedText.endIndex ..< cleanedText.endIndex

    // Check if it's a backspace press
    if string.isEmpty {
      var newText = cleanedText
      if text.count == 1 {
        newText = ""
        textField.text = newText
        viewModel.birthDay = newText
        return false
      }

      newText.remove(at: newText.index(before: rangeOfTextToReplace.lowerBound))
      newText = formatAsDate(for: newText)
      textField.text = newText

      return false
    }

    var newText = cleanedText
    newText.replaceSubrange(rangeOfTextToReplace, with: string)
    newText = formatAsDate(for: newText)
    textField.text = newText
    viewModel.birthDay = newText
    return false
  }
}

//extension UITextField{
//    func setInputViewDatePicker(target: Any, selector: Selector){
//        let screenWidth = UIScreen.main.bounds.width
//        let datePicker = UIDatePicker(frame: CGRect(x: 0, y: 0, width: screenWidth, height: 500))
//        datePicker.datePickerMode = .date
//        if #available(iOS 13.4, *) {
//            datePicker.preferredDatePickerStyle = .wheels
//        } else {
//            // Fallback on earlier versions
//        }
//        self.inputView = datePicker
//        
//        let toolbar = UIToolbar(frame: CGRect(x: 0.0, y: 0.0, width: screenWidth, height: 44.0))
//        let flexible = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
//        let barButton = UIBarButtonItem(title: "Done", style: .plain, target: target, action: selector)
//        toolbar.setItems([flexible, barButton], animated: true)
//        self.inputAccessoryView = toolbar
//    }
//}
