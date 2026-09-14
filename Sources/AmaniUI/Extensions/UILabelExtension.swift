//
//  UILabelExtension.swift
//  Pods
//
//  Created by Bedri Doğan on 10.09.2026.
//

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
