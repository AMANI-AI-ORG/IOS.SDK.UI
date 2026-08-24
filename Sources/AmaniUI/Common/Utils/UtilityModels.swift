//
//  UtilityModels.swift
//  AmaniUIv1
//
//  Created by Deniz Can on 7.09.2022.
//

struct LocalErrorModel {
  var value: Bool
  var docType: String
}

enum DocumentID: Equatable {
    
    case ID  // Id card
    case NF  // NFC as a document
    case SE  // Selfie
    case DL  // Driver's licence
    case PA  // Passport
    case CO  // Contract
    case UB  // Utility Bill
    case IB  // Proof of address
    case SG  // Signature
    case VA  // Visa
    case ST //Speech to text
    case OD(String)  // Other document types.

    init?(rawValue: String) {
           switch rawValue {
           case "ID": self = .ID
           case "NF": self = .NF
           case "SE": self = .SE
           case "DL": self = .DL
           case "PA": self = .PA
           case "CO": self = .CO
           case "UB": self = .UB
           case "IB": self = .IB
           case "SG": self = .SG
           case "VA": self = .VA
           case "ST": self = .ST
           default: self = .OD(rawValue)
           }
       }
    
    func getDocumentType() -> String {
        switch self {
        case .ID: return "ID"
        case .NF: return "NF"
        case .SE: return "SE"
        case .DL: return "DL"
        case .PA: return "PA"
        case .CO: return "CO"
        case .UB: return "UB"
        case .IB: return "IB"
        case .SG: return "SG"
        case .VA: return "VA"
        case .ST: return "ST"
        case .OD(let customType): return customType
        }
    }
}



//enum DocumentID: String {
//
//  case ID = "ID"
//
//  case NF = "NF"
//
//  case SE = "SE"
//
//  case DL = "DL"
//
//  case PA = "PA"
//
//  case CO = "CO"
//
//  case UB = "UB"
//
//  case IB = "IB"
//
//  case SG = "SG"
//
//  case VA = "VA"
//}
