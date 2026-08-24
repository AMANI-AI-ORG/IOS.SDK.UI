//
//  QuestionDropdownView.swift
//  AmaniUI
//
//  Created by Deniz Can on 25.01.2024.
//

import AmaniSDK
import Foundation
import UIKit

// TODO: Update the name
class QuestionDropdownView: UIView {
  var question: QuestionModel?
  var didTapAnswerCallback: ((String) -> Void)?

  private lazy var answerStackView: UIStackView = {
    let stackView = UIStackView()
    stackView.axis = .vertical
    return stackView
  }()

  convenience init(with question: QuestionModel, answers: QuestionAnswerRequestModel? = nil) {
    self.init()
    self.question = question
    setupUI(with: answers)
  }

  func setupUI(with answers: QuestionAnswerRequestModel? = nil) {
    guard let question = question else {
      return
    }

    let buttonType: AnswerButtonType = question.answerType == "multiple_choice" ? .multiple : .single

    let selectedAnswerIDs = answers?.multipleOptionAnswer
    let singleAnswerID = answers?.singleOptionAnswer
    question.answers.forEach { answer in
      let answerButton = AnswerButton(with: answer, type: buttonType)

      if let answerIDs = selectedAnswerIDs, buttonType == .multiple {
        if answerIDs.contains(answer.id) {
          answerButton.setChecked(true)
        }
      } else if let answerID = singleAnswerID, buttonType == .single {
        if answer.id == answerID {
          answerButton.setChecked(true)
        }
      }

      self.answerStackView.addArrangedSubview(answerButton)
    }

    answerStackView.translatesAutoresizingMaskIntoConstraints = false

    addSubview(answerStackView)
    NSLayoutConstraint.activate([
      answerStackView.topAnchor.constraint(equalTo: topAnchor),
      answerStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
      answerStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
      answerStackView.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])
  }

  func bind(didTapAnswerFunc: @escaping (String) -> Void) {
    didTapAnswerCallback = didTapAnswerFunc

    let answerButtons: [AnswerButton] = answerStackView.arrangedSubviews as! [AnswerButton]
    answerButtons.forEach { button in
      button.bind(didPressAnswerFN: { answerID in
        guard let question = self.question else { return }
        if question.answerType == "single_choice" {
          answerButtons.forEach { $0.setChecked($0.answerID == answerID) }
        }
        didTapAnswerFunc(answerID)
      })
    }
  }
}
