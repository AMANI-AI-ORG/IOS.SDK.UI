//
//  UIColorExtensions.swift
//  AmaniUIv1
//
//  Created by Deniz Can on 6.09.2022.
//

import Foundation
import UIKit
/**
 This file consists all the extended features of a UIColor
 */
extension UIColor {
  /**
   This method used to get hexa decimal code of UIColor
   - returns: String
   */
  func toHexString() -> String {
    var r:CGFloat = 0
    var g:CGFloat = 0
    var b:CGFloat = 0
    var a:CGFloat = 0
    getRed(&r, green: &g, blue: &b, alpha: &a)
    let rgb:Int = (Int)(r*255)<<16 | (Int)(g*255)<<8 | (Int)(b*255)<<0
    return String(format:"#%06x", rgb)
  }
}

extension UIColor {
  convenience init(hexString: String) {
    let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    var int: UInt64 = 0
    Scanner(string: hex).scanHexInt64(&int)
    
    let a, r, g, b: UInt64
    switch hex.count {
    case 8:
      (a, r, g, b) = (int >> 24, int >> 16 & 0xff, int >> 8 & 0xff, int & 0xff)
    default:
      (a, r, g, b) = (255, int >> 16, int >> 8 & 0xff, int & 0xff)
    }
    
    self.init(
      red: CGFloat(r) / 255,
      green: CGFloat(g) / 255,
      blue: CGFloat(b) / 255,
      alpha: CGFloat(a) / 255
    )
  }
}
