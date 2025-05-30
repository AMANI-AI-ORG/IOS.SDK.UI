//
//  Untitled.swift
//  AmaniUI
//
//  Created by Münir Ketizmen on 21.02.2025.
//

import UIKit

func hextoUIColor(hexString: String, alpha: CGFloat = 1.0) -> UIColor {
  let hexString: String = hexString.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
  let scanner = Scanner(string: hexString)
  if (hexString.hasPrefix("#")) {
    scanner.scanLocation = 1
  }
  var color: UInt32 = 0
  scanner.scanHexInt32(&color)
  let mask = 0x0000FF
  let r = Int(color >> 16) & mask
  let g = Int(color >> 8) & mask
  let b = Int(color) & mask
  let red   = CGFloat(r) / 255.0
  let green = CGFloat(g) / 255.0
  let blue  = CGFloat(b) / 255.0

  return UIColor(red:red, green:green, blue:blue, alpha:alpha)
}
