//
//  QuestionView.swift
//  AmaniUI
//
//  Created by Deniz Can on 1.02.2024.
//

import AmaniSDK
import Foundation
import UIKit

protocol QuestionDelegate {
  func didTapAnswer(questionID: String, answerID: String, questionType: String)
}

class QuestionViewCell: UITableViewCell {
  
  private var questionTitle = UILabel()
  private var questionDescription = UILabel()
  private var stackView = UIStackView()
  private var textInputView: QuestionTextInputView?
  
  public var question: QuestionModel?
  private var delegate: QuestionDelegate?
  public var isConfigured = false
  
  private var dropdownView: QuestionDropdownView?
  private var singleOption: SingleAnswerButton?

    var genConfig: GeneralConfig? {
        didSet {
            applyConfigStyling()
        }
    }



  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    buildLayout()
    applyConfigStyling()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    // Reset the cell's state when preparing for reuse
    isConfigured = false
    dropdownView?.removeFromSuperview()
    dropdownView = nil
    singleOption?.removeFromSuperview()
    singleOption = nil
    textInputView?.removeFromSuperview()
    textInputView = nil
  }
  
  func configure(delegate: QuestionDelegate, selectedAnswers: QuestionAnswerRequestModel? = nil) {
    guard !isConfigured else { return }
    guard let question = question else { return }
    self.delegate = delegate
    questionTitle.text = question.title
    selectionStyle = .none
    
    if question.answerType == "text"{
      configureTextInput(question: question, selectedAnswers: selectedAnswers, answerTypeIsNumber: false)
    }else if question.answerType == "number" {
      configureTextInput(question: question, selectedAnswers: selectedAnswers, answerTypeIsNumber: true)
    } else {
      if question.answers.count > 1 {
        configureDropDown(question: question, selectedAnswers: selectedAnswers)
      } else {
        configureSingleButton(question: question, selectedAnswers: selectedAnswers)
      }
    }
  }
  
  func configureTextInput(question: QuestionModel, selectedAnswers: QuestionAnswerRequestModel? = nil, answerTypeIsNumber: Bool = false) {
    if textInputView == nil {
      textInputView = QuestionTextInputView()
      
      textInputView!.answerTypeIsNumber = answerTypeIsNumber
      textInputView!.translatesAutoresizingMaskIntoConstraints = false
      
      if let textAnswer = selectedAnswers?.typedAnswer {
        textInputView?.setText(textAnswer)
      }
      
      textInputView!.bind { [weak self] text in
        self?.delegate?.didTapAnswer(questionID: question.id, answerID: text, questionType: question.answerType)
      }
    }
    
    stackView.addArrangedSubview(textInputView!)
    isConfigured = true
    textInputView!.layoutIfNeeded()
  }
  
  func configureSingleButton(question: QuestionModel, selectedAnswers: QuestionAnswerRequestModel? = nil) {
    // Configuration for single option
    if singleOption == nil {
      let answerData = question.answers.first!
      singleOption = SingleAnswerButton(with: answerData)
      
      if selectedAnswers?.singleOptionAnswer != nil {
        singleOption?.setSelected(true)
      }
      
      singleOption?.sizeToFit()
      singleOption!.translatesAutoresizingMaskIntoConstraints = false
      singleOption!.bind { [weak self] answerID in
        self?.delegate?.didTapAnswer(questionID: question.id, answerID: answerID, questionType: question.answerType)
      }
    }
    
    stackView.addArrangedSubview(singleOption!)
    isConfigured = true
    singleOption!.layoutIfNeeded()
  }
  
  func configureDropDown(question: QuestionModel, selectedAnswers: QuestionAnswerRequestModel? = nil) {
    // Configuration for dropdown
    if dropdownView == nil {
      dropdownView = QuestionDropdownView(with: question, answers: selectedAnswers)
      dropdownView!.translatesAutoresizingMaskIntoConstraints = false
      dropdownView!.bind { [weak self] answerID in
        self?.delegate?.didTapAnswer(questionID: question.id, answerID: answerID, questionType: question.answerType)
      }
    }
    
    stackView.addArrangedSubview(dropdownView!)
    isConfigured = true
    dropdownView!.layoutIfNeeded()
  }
  
  // Builds the cell's static view hierarchy exactly once (from init). Must not run again on
  // reuse/reconfigure — doing so used to create a brand new stackView on every `genConfig`
  // assignment (i.e. every reuse) without removing the previous one, leaving stale, overlapping
  // stacks (and orphaned answer views) permanently attached to contentView.
  private func buildLayout() {
    self.questionTitle.font = UIFont.systemFont(ofSize: 16.0, weight: .regular)
    self.questionTitle.textColor = .black
    self.questionTitle.numberOfLines = 0
    self.questionTitle.text = "Temporary title, please initialize correctly"

    self.questionDescription.font = UIFont.systemFont(ofSize: 13.0, weight: .light)
    self.questionDescription.textColor = hextoUIColor(hexString: "#465364")
    self.questionDescription.text = "Temporary title, please initialize correctly"

    self.stackView = UIStackView(arrangedSubviews: [questionTitle])
    self.stackView.spacing = 8.0
    self.stackView.axis = .vertical
    self.stackView.alignment = .fill
    self.stackView.distribution = .fillProportionally
    self.stackView.layer.masksToBounds = true

    setConstraints()
  }

  // Config-dependent styling only — safe to re-run every time `genConfig` changes.
  private func applyConfigStyling() {
    self.backgroundColor = hextoUIColor(hexString: genConfig?.appBackground ?? "#EEF4FA")
  }
  
  private func setConstraints() {
    contentView.addSubview(stackView)
    stackView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 30.0),
      stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20.0),
      stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -30.0),
      stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20.0),
    ])
  }
}



