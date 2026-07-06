//
//  QuestionSubmitButton.swift
//  AmaniUI
//
//  Created by Deniz Can on 6.02.2024.
//

import Foundation
import UIKit
import AmaniSDK

class QuestionSubmitButton: UIStackView {
  public var nextCallback: (() -> Void)?
    
    var genConfig: GeneralConfig? {
        didSet {
            guard let config = genConfig else { return }
            setupUI()
        }
    }
    
  private lazy var submitButton: UIButton = {
    let submit = UIButton()
    let nextButtonTitle = genConfig?.continueText ?? "Contunie"
    submit.setTitle(nextButtonTitle, for: .normal)
    submit.setTitleColor(.white, for: .normal)
    submit.backgroundColor = hextoUIColor(hexString: genConfig?.primaryButtonBackgroundColor ?? "#EA3365")
    submit.addTarget(self, action: #selector(didTapNext), for: .touchUpInside)
      submit.addCornerRadiousWith(radious: AmaniUI.sharedInstance.style.ctaButtonCornerRadius)
    return submit
  }()
  
  @objc
  func didTapNext() {
    if let nextCallback = nextCallback {
      nextCallback()
    }
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
 
  }
  
  required init(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  func bind(_ nextCb: @escaping (() -> Void)) {
    self.nextCallback = nextCb
  }
  
    func setupUI() {
        self.backgroundColor = hextoUIColor(hexString: genConfig?.appBackground ?? "#EEF4FA")
        self.addArrangedSubview(submitButton)
        self.axis = .vertical
        self.layoutMargins = UIEdgeInsets(top: 10, left: 20, bottom: -10, right: 20)
        self.isLayoutMarginsRelativeArrangement = true
        self.heightAnchor.constraint(equalToConstant: 50).isActive = true

    }
}
