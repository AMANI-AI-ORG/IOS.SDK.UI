import Foundation

struct AmaniUIResumeState: Codable {
  let stepID: String
  let customerID: String
  let serverURL: String
  let createdAt: TimeInterval
}

final class AmaniUIResumeStore {
  static let shared = AmaniUIResumeStore()
  
  private let defaults: UserDefaults
  private let storageKey = "com.amani.ui.pendingAmaniVerifierResume"
  private let maxAge: TimeInterval = 60 * 60
  
  private init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
  }
  
  var hasPendingResume: Bool {
    load() != nil
  }
  
  func save(
    stepID: String,
    customerID: String,
    serverURL: String
  ) {
    let cleanedStepID = stepID.trimmingCharacters(
      in: .whitespacesAndNewlines
    )
    let cleanedCustomerID = customerID.trimmingCharacters(
      in: .whitespacesAndNewlines
    )
    let cleanedServerURL = serverURL.trimmingCharacters(
      in: .whitespacesAndNewlines
    )
    
    guard
      !cleanedStepID.isEmpty,
      !cleanedCustomerID.isEmpty,
      !cleanedServerURL.isEmpty
    else {
      return
    }
    
    let state = AmaniUIResumeState(
      stepID: cleanedStepID,
      customerID: cleanedCustomerID,
      serverURL: cleanedServerURL,
      createdAt: Date().timeIntervalSince1970
    )
    
    guard let data = try? JSONEncoder().encode(state) else {
      return
    }
    
    defaults.set(
      data,
      forKey: storageKey
    )
  }
  
  func load() -> AmaniUIResumeState? {
    guard let data = defaults.data(forKey: storageKey) else {
      return nil
    }
    
    guard
      let state = try? JSONDecoder().decode(
        AmaniUIResumeState.self,
        from: data
      )
    else {
      clear()
      return nil
    }
    
    let age = Date().timeIntervalSince1970 - state.createdAt
    
    guard age >= 0, age <= maxAge else {
      clear()
      return nil
    }
    
    return state
  }
  
  func clear() {
    defaults.removeObject(
      forKey: storageKey
    )
  }
}
