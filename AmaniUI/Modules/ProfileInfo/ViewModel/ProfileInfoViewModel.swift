//
//  ProfileInfoViewModel.swift
//  AmaniUI
//
//  Created by Deniz Can on 22.01.2024.
//

import Foundation
import AmaniSDK
import Combine

class ProfileInfoViewModel {
  private let customerInfo = Amani.sharedInstance.customerInfo()
  enum ViewState {
    case loading
    case success
    case failed
    case none
  }
  
  @Published var name = ""
  @Published var surname = ""
  @Published var birthDay = ""
  @Published var state: ViewState = .none
  
  var isNameValidPublisher: AnyPublisher<Bool, Never> {
    $name.debounce(for: 0.5, scheduler: RunLoop.main)
    // Arbitary number. Check with backend
      .map { newName in newName.count <= 100 }
      .eraseToAnyPublisher()
  }
  
  var isSurnameValidPublisher: AnyPublisher<Bool, Never> {
    $name.debounce(for: 0.5, scheduler: RunLoop.main)
    // Arbitary number. Check with backend
      .map { newName in newName.count <= 100 }
      .eraseToAnyPublisher()
  }
  
  var isBdayValidPublisher: AnyPublisher<Bool, Never> {
    $birthDay.debounce(for: 0.5, scheduler: RunLoop.main)
      .map { newBday in
        self.isBdayValid(input: newBday)
      }.eraseToAnyPublisher()
  }
  
  func submitForm() {
    
    guard !name.isEmpty && !surname.isEmpty && !birthDay.isEmpty else {
      self.state = .failed
      return
    }
    
    guard isBdayValid(input: birthDay) else {
      self.state = .failed
      return
    }
    
    let replacedBday = birthDay.replacingOccurrences(of: "/", with: "-")
    state = .loading
    customerInfo.setName(name: name + " " + surname)
    customerInfo.setBirthDate(date: replacedBday.convertDateFormat()!)
    customerInfo.upload(location: AmaniUI.sharedInstance.location) {[weak self] uploadSuccess in
      if uploadSuccess == false {
        self?.state = .failed
        return
      } else {
        self?.state = .success
      }
    }
  }
  
  private func isBdayValid(input: String) -> Bool {
    if input == "" { return true }
    let replacedBday = input.replacingOccurrences(of: "/", with: "-")
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "dd-MM-yyyy"
    
    if let _ = dateFormatter.date(from: replacedBday) {
      return true
    } else {
      return false
    }
  }
  
}