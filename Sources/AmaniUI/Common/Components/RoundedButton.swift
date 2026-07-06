//
//  RoundedButton.swift
//  AmaniDemoApp
//
//  Created by Deniz Can on 6.12.2023.
//

import Foundation
import UIKit

import UIKit

class RoundedButton: UIButton {
  private var buttonAction: (() -> Void)?
  private var activityIndicator: UIActivityIndicatorView?
  
  convenience init(withTitle title: String = "Login", withColor color: UIColor = UIColor.systemPink) {
    self.init()
    
    setTitle(title, for: .normal)
    setTitleColor(.white, for: .normal)
    backgroundColor = color
    
    layer.borderColor = color.cgColor
    layer.cornerRadius = AmaniUI.sharedInstance.style.ctaButtonCornerRadius
    
    titleLabel?.font = UIFont.systemFont(ofSize: 16.0, weight: .bold)
    contentEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
    
    // Create and configure the activity indicator
    activityIndicator = UIActivityIndicatorView(style: .medium)
    activityIndicator?.hidesWhenStopped = true
    activityIndicator?.color = .white
    
    // Add the activity indicator as a subview
    if let indicator = activityIndicator {
      addSubview(indicator)
      indicator.translatesAutoresizingMaskIntoConstraints = false
      NSLayoutConstraint.activate([
        indicator.centerYAnchor.constraint(equalTo: centerYAnchor),
        indicator.leadingAnchor.constraint(equalTo: titleLabel!.trailingAnchor, constant: 8)
      ])
    }
    
    NSLayoutConstraint.activate([
      heightAnchor.constraint(equalToConstant: 50.0)
    ])
    
  }
  
  func bind(buttonAction: @escaping () -> Void) {
    self.buttonAction = buttonAction
    addTarget(self, action: #selector(didTapButton), for: .touchUpInside)
  }
  
  func showActivityIndicator() {
    DispatchQueue.main.async {
      self.activityIndicator?.startAnimating()
      self.isEnabled = false
    }
  }
  
  func hideActivityIndicator() {
    DispatchQueue.main.async {
      self.activityIndicator?.stopAnimating()
      self.isEnabled = true
    }
  }
  
  @objc
  func didTapButton() {
    guard let action = buttonAction else { return }
    action()
  }
}
