import UIKit
import AmaniSDK
#if canImport(AmaniLocalization)
import AmaniLocalization
#endif
/**
 This class represents the cell class of KYC step
 */
@objc(KYCStepTableViewCell)
class KYCStepTableViewCell: UITableViewCell {
    // MARK: - Properties
    private var outerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 15.0, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 2
        label.textAlignment = .left
        return label
    }()
    
    private lazy var loaderView: UIActivityIndicatorView = {
       let loader = UIActivityIndicatorView()
        loader.translatesAutoresizingMaskIntoConstraints = false
        loader.backgroundColor = .clear
        loader.color = .white
      return loader
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
        setConstraints()
        self.selectionStyle = .none
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setConstraints()
        self.selectionStyle = .none
    
    }
    // MARK: - Helper methods
    /**
     This method bind the data with view
     - parameter model: KYCRuleModel
     */
  func bind(model: KYCStepViewModel, alpha: CGFloat = 1) {
    DispatchQueue.main.async { [weak self] in
      
      var labelTest: String = model.title
      if let loaderView = self?.loaderView {
        if model.status == DocumentStatus.PROCESSING {
          #if canImport(AmaniLocalization)
          labelTest = AmaniLocalization.localizedString(forKey: "\(model.stepConfig.documents?.first?.id ?? "ID")_PROCESSING")

//          switch model.stepConfig.documents?.first?.id{
//          case "CO":
//            labelTest = AmaniLocalization.localizedString(forKey: "ID_PROCESSING")
//          case "DL":
//            labelTest = AmaniLocalization.localizedString(forKey: "DL_PROCESSING")
//          case "IB":
//            labelTest = AmaniLocalization.localizedString(forKey: "IB_PROCESSING")
//          case "ID":
//            labelTest = AmaniLocalization.localizedString(forKey: "ID_PROCESSING")
//          case "NF":
//            labelTest = AmaniLocalization.localizedString(forKey: "NF_PROCESSING")
//          case "PA":
//            labelTest = AmaniLocalization.localizedString(forKey: "PA_PROCESSING")
//          case "SE":
//            labelTest = AmaniLocalization.localizedString(forKey: "SE_PROCESSING")
//          case "SG":
//            labelTest = AmaniLocalization.localizedString(forKey: "SG_PROCESSING")
//          case "UB":
//            labelTest = AmaniLocalization.localizedString(forKey: "ID_PROCESSING")
//          case "VA":
//            labelTest = AmaniLocalization.localizedString(forKey: "ID_PROCESSING")
//          default:
//            print("Missing case")
//          }
          
          #else
          labelTest = model.stepConfig.buttonText?.notUploaded ?? model.title
          #endif
          loaderView.stopAnimating()
          
        }else if model.status == DocumentStatus.APPROVED{
          #if canImport(AmaniLocalization)
          labelTest = AmaniLocalization.localizedString(forKey: "\(model.stepConfig.documents?.first?.id ?? "ID")_APPROVED")

//          switch model.stepConfig.documents?.first?.id{
//          case "CO":
//            labelTest = AmaniLocalization.localizedString(forKey: "ID_APPROVED")
//          case "DL":
//            labelTest = AmaniLocalization.localizedString(forKey: "DL_APPROVED")
//          case "IB":
//            labelTest = AmaniLocalization.localizedString(forKey: "IB_APPROVED")
//          case "ID":
//            labelTest = AmaniLocalization.localizedString(forKey: "ID_APPROVED")
//          case "NF":
//            labelTest = AmaniLocalization.localizedString(forKey: "NF_APPROVED")
//          case "PA":
//            labelTest = AmaniLocalization.localizedString(forKey: "PA_APPROVED")
//          case "SE":
//            labelTest = AmaniLocalization.localizedString(forKey: "SE_APPROVED")
//          case "SG":
//            labelTest = AmaniLocalization.localizedString(forKey: "SG_APPROVED")
//          case "UB":
//            labelTest = AmaniLocalization.localizedString(forKey: "ID_APPROVED")
//          case "VA":
//            labelTest = AmaniLocalization.localizedString(forKey: "ID_APPROVED")
//          default:
//            print("Missing case")
//          }
          
          #else
          labelTest = model.stepConfig.buttonText?.notUploaded ?? model.title
          #endif
          loaderView.stopAnimating()
          
        }else if model.status == DocumentStatus.REJECTED{
          #if canImport(AmaniLocalization)
          labelTest = AmaniLocalization.localizedString(forKey: "\(model.stepConfig.documents?.first?.id ?? "ID")_REJECTED")

//          switch model.stepConfig.documents?.first?.id{
//          case "CO":
//            labelTest = AmaniLocalization.localizedString(forKey: "ID_REJECTED")
//          case "DL":
//            labelTest = AmaniLocalization.localizedString(forKey: "DL_REJECTED")
//          case "IB":
//            labelTest = AmaniLocalization.localizedString(forKey: "IB_REJECTED")
//          case "ID":
//            labelTest = AmaniLocalization.localizedString(forKey: "ID_REJECTED")
//          case "NF":
//            labelTest = AmaniLocalization.localizedString(forKey: "NF_REJECTED")
//          case "PA":
//            labelTest = AmaniLocalization.localizedString(forKey: "PA_REJECTED")
//          case "SE":
//            labelTest = AmaniLocalization.localizedString(forKey: "SE_REJECTED")
//          case "SG":
//            labelTest = AmaniLocalization.localizedString(forKey: "SG_REJECTED")
//          case "UB":
//            labelTest = AmaniLocalization.localizedString(forKey: "ID_REJECTED")
//          case "VA":
//            labelTest = AmaniLocalization.localizedString(forKey: "ID_REJECTED")
//          default:
//            print("Missing case")
//          }
          
          #else
          labelTest = model.stepConfig.buttonText?.notUploaded ?? model.title
          #endif
          loaderView.stopAnimating()
          
        }else if model.status == DocumentStatus.AUTOMATICALLY_REJECTED{
          #if canImport(AmaniLocalization)
          labelTest = AmaniLocalization.localizedString(forKey: "\(model.stepConfig.documents?.first?.id ?? "ID")_AUTOMATICALLYREJECTED")

//          switch model.stepConfig.documents?.first?.id{
//          case "CO":
//            labelTest = AmaniLocalization.localizedString(forKey: "ID_AUTOMATICALLYREJECTED")
//          case "DL":
//            labelTest = AmaniLocalization.localizedString(forKey: "DL_AUTOMATICALLYREJECTED")
//          case "IB":
//            labelTest = AmaniLocalization.localizedString(forKey: "IB_AUTOMATICALLYREJECTED")
//          case "ID":
//            labelTest = AmaniLocalization.localizedString(forKey: "ID_AUTOMATICALLYREJECTED")
//          case "NF":
//            labelTest = AmaniLocalization.localizedString(forKey: "NF_AUTOMATICALLYREJECTED")
//          case "PA":
//            labelTest = AmaniLocalization.localizedString(forKey: "PA_AUTOMATICALLYREJECTED")
//          case "SE":
//            labelTest = AmaniLocalization.localizedString(forKey: "SE_AUTOMATICALLYREJECTED")
//          case "SG":
//            labelTest = AmaniLocalization.localizedString(forKey: "SG_AUTOMATICALLYREJECTED")
//          case "UB":
//            labelTest = AmaniLocalization.localizedString(forKey: "ID_AUTOMATICALLYREJECTED")
//          case "VA":
//            labelTest = AmaniLocalization.localizedString(forKey: "ID_AUTOMATICALLYREJECTED")
//          default:
//            print("Missing case")
//          }
          
          #else
          labelTest = model.stepConfig.buttonText?.notUploaded ?? model.title
          #endif
          loaderView.stopAnimating()
          
        }else if model.status == DocumentStatus.NOT_UPLOADED{
          #if canImport(AmaniLocalization)
          labelTest = AmaniLocalization.localizedString(forKey: "\(model.stepConfig.documents?.first?.id ?? "ID")_NOTUPLOADED")
//          switch model.stepConfig.documents?.first?.id{
//          case "CO":
//            labelTest = AmaniLocalization.localizedString(forKey: "ID_NOTUPLOADED")
//          case "DL":
//            labelTest = AmaniLocalization.localizedString(forKey: "DL_NOTUPLOADED")
//          case "IB":
//            labelTest = AmaniLocalization.localizedString(forKey: "IB_NOTUPLOADED")
//          case "ID":
//            labelTest = AmaniLocalization.localizedString(forKey: "ID_NOTUPLOADED")
//          case "NF":
//            labelTest = AmaniLocalization.localizedString(forKey: "NF_NOTUPLOADED")
//          case "PA":
//            labelTest = AmaniLocalization.localizedString(forKey: "PA_NOTUPLOADED")
//          case "SE":
//            labelTest = AmaniLocalization.localizedString(forKey: "SE_NOTUPLOADED")
//          case "SG":
//            labelTest = AmaniLocalization.localizedString(forKey: "SG_NOTUPLOADED")
//          case "UB":
//            labelTest = AmaniLocalization.localizedString(forKey: "ID_NOTUPLOADED")
//          case "VA":
//            labelTest = AmaniLocalization.localizedString(forKey: "ID_NOTUPLOADED")
//          default:
//            print("Missing case")
//          }
          #else
          labelTest = model.stepConfig.buttonText?.notUploaded ?? model.title
          #endif
          loaderView.stopAnimating()
          
        }else if model.status == DocumentStatus.PENDING_REVIEW{
          #if canImport(AmaniLocalization)
          labelTest = AmaniLocalization.localizedString(forKey: "\(model.stepConfig.documents?.first?.id)_PENDINGREVIEW")
//          switch model.stepConfig.documents?.first?.id{
//          case "CO":
//            labelTest = AmaniLocalization.localizedString(forKey: "ID_PENDINGREVIEW")
//          case "DL":
//            labelTest = AmaniLocalization.localizedString(forKey: "DL_PENDINGREVIEW")
//          case "IB":
//            labelTest = AmaniLocalization.localizedString(forKey: "IB_PENDINGREVIEW")
//          case "ID":
//            labelTest = AmaniLocalization.localizedString(forKey: "ID_PENDINGREVIEW")
//          case "NF":
//            labelTest = AmaniLocalization.localizedString(forKey: "NF_PENDINGREVIEW")
//          case "PA":
//            labelTest = AmaniLocalization.localizedString(forKey: "PA_PENDINGREVIEW")
//          case "SE":
//            labelTest = AmaniLocalization.localizedString(forKey: "SE_PENDINGREVIEW")
//          case "SG":
//            labelTest = AmaniLocalization.localizedString(forKey: "SG_PENDINGREVIEW")
//          case "UB":
//            labelTest = AmaniLocalization.localizedString(forKey: "ID_PENDINGREVIEW")
//          case "VA":
//            labelTest = AmaniLocalization.localizedString(forKey: "ID_PENDINGREVIEW")
//          default:
//            print("Missing case")
//          }
          #else
          labelTest = model.stepConfig.buttonText?.notUploaded ?? model.title
          #endif
          loaderView.stopAnimating()
          
        } else {
          if ((model.getRuleModel().errors?.count ?? 0) > 0){
              // TODO: Get the error name from the DocumentStepModel.
            labelTest += "xxxxxx"
            loaderView.stopAnimating()
          }
          
          loaderView.stopAnimating()
        }
      }
        self?.titleLabel.text = labelTest
        self?.titleLabel.textColor = model.textColor
        self?.outerView.backgroundColor = model.buttonColor
        self?.outerView.alpha = alpha
        
    }
  }

}

// MARK: Setting the constraints
extension KYCStepTableViewCell {
    private func setupUI() {
        self.contentView.backgroundColor = UIColor(hexString: AmaniUI.sharedInstance.config?.generalconfigs?.appBackground ?? "#EEF4FA" )
    
        outerView.addShadowWithBorder(
            shadowRadius: 4,
            shadowColor: #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.25),
            shadowOpacity: 1,
            borderColor: .clear,
            borderWidth: 0,
            cornerRadious: CGFloat(AmaniUI.sharedInstance.config?.generalconfigs?.buttonRadius ?? 10)
        )
        if let bordercolor: String = AmaniUI.sharedInstance.config?.generalconfigs?.primaryButtonBorderColor {
            outerView.addBorder(borderWidth: 2, borderColor: UIColor(hexString: bordercolor).cgColor)
        }
    }
    
    private func setConstraints() {
        contentView.addSubview(outerView)
        outerView.addSubviews(titleLabel, loaderView)
        
        NSLayoutConstraint.activate([
            outerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            outerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            outerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            outerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
           
            
            titleLabel.leadingAnchor.constraint(equalTo: outerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: outerView.trailingAnchor, constant: 11),
            titleLabel.bottomAnchor.constraint(equalTo: outerView.bottomAnchor),
            titleLabel.topAnchor.constraint(equalTo: outerView.topAnchor),
            titleLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 50),
            
            
            loaderView.topAnchor.constraint(equalTo: outerView.topAnchor),
            loaderView.bottomAnchor.constraint(equalTo: outerView.bottomAnchor),
            loaderView.trailingAnchor.constraint(equalTo: outerView.trailingAnchor),
            loaderView.widthAnchor.constraint(equalToConstant: 65)
            
        ])
        
        setupUI()
    }
    
  
    
}
