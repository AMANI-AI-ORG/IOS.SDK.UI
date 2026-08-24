//
//  AnswerButton.swift
//  AmaniUI
//
//  Created by Deniz Can on 25.01.2024.
//

import AmaniSDK
import Foundation
import UIKit

enum AnswerButtonType {
  case multiple
  case single
}

class AnswerButton: UIButton {
  public var answerID: String?
  private var answerModel: QuestionAnswerModel?
  private var type: AnswerButtonType = .single
  private var didPressCallback: ((String) -> Void)?

  private var isChecked = false {
    didSet {
      var image: UIImage?
      if type == .multiple {
        image = isChecked ? UIImage(systemName: "square.fill") : UIImage(systemName: "square")
      } else if type == .single {
        image = isChecked ? UIImage(systemName: "circle.fill") : UIImage(systemName: "circle")
      }
      setImage(image!, for: .normal)
    }
  }

  private var didInstallImageConstraints = false

  convenience init(
    with answer: QuestionAnswerModel,
    type: AnswerButtonType = .single
  ) {
    self.init()
    self.answerModel = answer
    self.answerID = answer.id
    self.type = type

    let attributes: [NSAttributedString.Key: Any] = [
      .font: UIFont.systemFont(ofSize: 15.0, weight: .light),
      .foregroundColor: hextoUIColor(hexString: "#565656"),
    ]

    let attributedString = NSAttributedString(
      string: answer.title,
      attributes: attributes
    )

    setAttributedTitle(attributedString, for: .normal)
    
    tintColor = .black
    backgroundColor = .white

    titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .light)

    layer.borderColor = hextoUIColor(hexString: "#C0C0C0").cgColor
    layer.borderWidth = 1.0

    if type == .multiple {
      setImage(UIImage(systemName: "square"),
               for: .normal)
    } else if type == .single {
      setImage(UIImage(systemName: "circle"),
               for: .normal)
    }

    if let titleLabel = titleLabel {
        NSLayoutConstraint.activate([
          titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
          titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -20),
        ])
      }
    titleLabel?.numberOfLines = 3
    contentHorizontalAlignment = .leading

    if #available(iOS 15.0, *) {
      var configuration = UIButton.Configuration.plain()
      configuration.contentInsets = NSDirectionalEdgeInsets(
        top: 16,
        leading: 20,
        bottom: 16,
        trailing: 20)
      configuration.imagePadding = 10
      self.configuration = configuration
    } else {
      contentEdgeInsets = UIEdgeInsets(
        top: 16,
        left: 20,
        bottom: 16,
        right: 20
      )
    }

    heightAnchor.constraint(greaterThanOrEqualToConstant: 50).priority = .required
  }

  override func layoutSubviews() {
    super.layoutSubviews()

    // Overriding in init doesn't work — the button's imageView isn't ready yet. Install these
    // constraints only once: re-activating a fresh set on every layoutSubviews() pass (which
    // fires repeatedly during scrolling) piled up unbounded duplicate constraints over time.
    guard !didInstallImageConstraints, let imageView = imageView, imageView.image != nil else { return }
    didInstallImageConstraints = true
    imageView.translatesAutoresizingMaskIntoConstraints = false
    let sizeConstraints = [
      imageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20.0),
      imageView.widthAnchor.constraint(equalToConstant: 18.0),
      imageView.heightAnchor.constraint(equalToConstant: 18.0),
      imageView.centerYAnchor.constraint(equalTo: centerYAnchor),
    ]
    sizeConstraints.forEach { $0.priority = .required }
    NSLayoutConstraint.activate(sizeConstraints)
    imageView.contentMode = .scaleAspectFit
  }

  func bind(didPressAnswerFN: @escaping (String) -> Void) {
    self.didPressCallback = didPressAnswerFN
    self.addTarget(self, action: #selector(didTapAnswer), for: .touchUpInside)
  }
  
  @objc
  func didTapAnswer() {
    isChecked.toggle()
    if let cb = self.didPressCallback {
      cb(self.answerModel!.id)
    }
  }
  
  func setChecked(_ isChecked: Bool) {
    self.isChecked = isChecked
  }
  
}
