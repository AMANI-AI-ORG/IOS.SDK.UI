//
//  UILabelExtension.swift
//  AmaniUI
//
//  Created by Bedri Doğan on 20.10.2026.
//
import UIKit

extension UILabel {
  
  func setText(
    _ text: String?,
    lineSpacing: CGFloat
  ) {
    
    guard let text else {
      self.text = nil
      return
    }
    
    let paragraphStyle = NSMutableParagraphStyle()
    
    paragraphStyle.lineSpacing = lineSpacing
    paragraphStyle.alignment = textAlignment
    
    attributedText = NSAttributedString(
      string: text,
      attributes: [
        .font: font as Any,
        .foregroundColor: textColor as Any,
        .paragraphStyle: paragraphStyle
      ]
    )
  }
}
