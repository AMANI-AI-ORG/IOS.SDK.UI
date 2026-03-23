//
//  Constants.swift
//  AmaniUIv1
//
//  Created by Deniz Can on 6.09.2022.
//

enum AppConstants {
  
  enum CameraFacing: String {
    case user
    case environment
  }
  
  enum AmaniError: Error {
    case ConfigError
    case StepFetchError
  }
  
  enum AmaniDelegateNotifications: String {
    case onError = "ai.amani.ui.onError"
    case onProfileStatus = "ai.amani.ui.onProfileStatus"
    case onStepModel = "ai.amani.ui.onStepModel"
  }
  
  enum StepsBeforeKYC: String, CaseIterable {
    case phoneOTP = "phone_otp"
    case emailOTP = "email_otp"
    case profileInfo = "profile_info"
    case questionnaire = "questionnaire"
    case termsAndConditions = "terms_and_conditions"
  }
  
}
