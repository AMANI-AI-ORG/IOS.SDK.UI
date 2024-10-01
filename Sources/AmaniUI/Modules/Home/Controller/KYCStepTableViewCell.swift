import UIKit
import AmaniSDK
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
          labelTest = model.stepConfig.buttonText?.processing ?? model.title
          loaderView.startAnimating()
          
        }else if model.status == DocumentStatus.APPROVED{
          labelTest = model.stepConfig.buttonText?.approved ?? model.title
          loaderView.stopAnimating()
          
        }else if model.status == DocumentStatus.REJECTED{
          labelTest = model.stepConfig.buttonText?.rejected ?? model.title
          loaderView.stopAnimating()
          
        }else if model.status == DocumentStatus.AUTOMATICALLY_REJECTED{
          labelTest = model.stepConfig.buttonText?.autoRejected ?? model.title
          loaderView.stopAnimating()
          
        }else if model.status == DocumentStatus.NOT_UPLOADED{
          labelTest = model.stepConfig.buttonText?.notUploaded ?? model.title
          loaderView.stopAnimating()
          
        }else if model.status == DocumentStatus.PENDING_REVIEW{
          labelTest = model.stepConfig.buttonText?.pendingReview ?? model.title
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
