//
//  QuestionnaireView.swift
//  AmaniUI
//
//  Created by Deniz Can on 25.01.2024.
//

import AmaniSDK
import Combine
import Foundation
import UIKit

class QuestionnaireView: UIView {
  private var viewModel: QuestionnaireViewModel?
  private var step: KYCStepViewModel?
  private var cancellables: Set<AnyCancellable> = []
  private var completionHandler: (() -> Void)?
  
  private lazy var tableView: UITableView = {
    let tableView = UITableView(frame: .zero, style: .grouped)
    tableView.dataSource = self
    tableView.delegate = self
    tableView.register(QuestionViewCell.self, forCellReuseIdentifier: String(describing: QuestionViewCell.self))
    return tableView
  }()

  override init(frame: CGRect) {
    super.init(frame: frame)
    setupUI()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func setupUI() {
    tableView.backgroundColor = UIColor(hexString: "#EEF4FA")
    backgroundColor = UIColor(hexString: "#EEF4FA")
    addSubview(tableView)
    tableView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: topAnchor),
      tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
      tableView.bottomAnchor.constraint(equalTo: bottomAnchor),
      tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
    ])
  }

  func bind(with viewModel: QuestionnaireViewModel, step: KYCStepViewModel? = nil, completionHandler: @escaping () -> Void) {
    self.viewModel = viewModel
    self.step = step
    self.completionHandler = completionHandler

    viewModel.$questions.sink { [weak self] newQuestions in
      print(newQuestions)
      DispatchQueue.main.async {
        self?.tableView.reloadData()
      }
    }.store(in: &cancellables)

    viewModel.$state
      .sink { [weak self] state in
        switch state {
        case .loading:
          break
        case .success:
          // call completion
          print("Success")
          if let completionHandler = self?.completionHandler {
            completionHandler()
          }
          break
        case .failed:
          if let nextRequiredIdx = viewModel.getNextEmptyRequiredIndex() {
            DispatchQueue.main.async {
              self?.tableView.scrollToRow(at: IndexPath(row: nextRequiredIdx, section: 0), at: .top, animated: true)
            }
          }
        case .none:
          break
        }
      }.store(in: &cancellables)
  }
}

extension QuestionnaireView: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return viewModel?.questions.count ?? 0
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let questionForCell = viewModel?.questions[indexPath.item] else {
      return UITableViewCell()
    }

    let selectedAnswerForQuestion = viewModel?.answers.first(where: {
      $0.question == questionForCell.id
    })

    let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: QuestionViewCell.self), for: indexPath) as! QuestionViewCell
    cell.isConfigured = false
    cell.question = questionForCell
    cell.configure(delegate: self, selectedAnswers: selectedAnswerForQuestion)

    return cell
  }
}

extension QuestionnaireView: UITableViewDelegate {
  func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    let questionnaireHeader = QuestionnaireHeaderView()
    return questionnaireHeader
  }

  func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
    let footerView = QuestionSubmitButton()
    footerView.bind {
      self.viewModel?.submitAnswers()
    }
    return footerView
  }
}

extension QuestionnaireView: QuestionDelegate {
  func didTapAnswer(questionID: String, answerID: String, questionType: String) {
    guard let viewModel = viewModel else { return }

    if questionType == "multiple_choice" {
      viewModel.addMultipleAnswer(for: questionID, answerID: answerID)
    } else if questionType == "single_choice" {
      viewModel.addSingleAnswer(for: questionID, answerID: answerID)
    }
  }
}
