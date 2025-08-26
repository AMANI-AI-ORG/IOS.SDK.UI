//
//  QuestionTextInputView.swift
//  AmaniUI
//
//  Created by Münir Ketizmen on 26.08.2025.
//
import Foundation
import UIKit

class QuestionTextInputView: UIView {
  private var textChangedCallback: ((String) -> Void)?
  var answerTypeIsNumber: Bool = false {
    didSet {
      setKeyboardType()
    }
  }
  
  private lazy var textField: UITextField = {
    let field = UITextField()
    field.borderStyle = .roundedRect
    field.placeholder = "Enter your answer"
    field.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
    field.delegate = self
    return field
  }()
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    setupUI()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setupUI() {
    addSubview(textField)
    textField.translatesAutoresizingMaskIntoConstraints = false
    
    NSLayoutConstraint.activate([
      textField.topAnchor.constraint(equalTo: topAnchor),
      textField.leadingAnchor.constraint(equalTo: leadingAnchor),
      textField.trailingAnchor.constraint(equalTo: trailingAnchor),
      textField.bottomAnchor.constraint(equalTo: bottomAnchor),
      textField.heightAnchor.constraint(equalToConstant: 44)
    ])
    enableDoneButton()
  }
  private func setKeyboardType() {
    textField.keyboardType = answerTypeIsNumber ? .numberPad : .default
    if textField.isFirstResponder {
      textField.reloadInputViews()
    }
  }

  
  func bind(_ callback: @escaping (String) -> Void) {
    textChangedCallback = callback
  }
  
  func setText(_ text: String) {
    textField.text = text
  }
  
  @objc private func textFieldDidChange() {
    textChangedCallback?(textField.text ?? "")
  }
  
  private func enableDoneButton() {
    let tb = UIToolbar()
    tb.sizeToFit()
    tb.items = [
      UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
      UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneTapped))
    ]
    textField.inputAccessoryView = tb
  }
  
  @objc private func doneTapped() {
    textField.resignFirstResponder()
  }
}

extension QuestionTextInputView: UITextFieldDelegate{
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    textField.resignFirstResponder()
    return true
  }
}
