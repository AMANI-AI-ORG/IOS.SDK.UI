
import Foundation
import UIKit
import AmaniSDK

class TermsAndConditionsView: UIView, UITextViewDelegate {
    private var descriptionTextView: UITextView!
    private var acceptButton: UIButton!
    private var declineButton: UIButton!
    
    private var completion: (() -> Void)?
    private var declineCompletion: (() -> Void)?
    
    var appConfig: AppConfigModel?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        descriptionTextView = UITextView()
        descriptionTextView.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        descriptionTextView.isEditable = false
        descriptionTextView.backgroundColor = .clear
        descriptionTextView.showsVerticalScrollIndicator = false
        
        acceptButton = UIButton(type: .system)
        acceptButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        acceptButton.addTarget(self, action: #selector(acceptPressed), for: .touchUpInside)
        
        declineButton = UIButton(type: .system)
        declineButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        declineButton.addTarget(self, action: #selector(declinePressed), for: .touchUpInside)
        declineButton.layer.borderWidth = 1
        
        let buttonStackView = UIStackView(arrangedSubviews: [declineButton, acceptButton])
        buttonStackView.axis = .horizontal
        buttonStackView.spacing = 16
        buttonStackView.distribution = .fillEqually
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        
        let mainStackView = UIStackView(arrangedSubviews: [descriptionTextView, buttonStackView])
        mainStackView.axis = .vertical
        mainStackView.spacing = 24
        mainStackView.alignment = .fill
        mainStackView.distribution = .fill
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Ensure descriptionTextView expands to fill space
        descriptionTextView.setContentHuggingPriority(.defaultLow, for: .vertical)
        buttonStackView.setContentHuggingPriority(.defaultHigh, for: .vertical)
        
        addSubview(mainStackView)
        
        NSLayoutConstraint.activate([
            mainStackView.topAnchor.constraint(equalTo: topAnchor),
            mainStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            mainStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            mainStackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            acceptButton.heightAnchor.constraint(equalToConstant: 56),
            declineButton.heightAnchor.constraint(equalToConstant: 56),
        ])
    }
    
    func bind(completion: @escaping () -> Void, declineCompletion: @escaping () -> Void) {
        self.completion = completion
        self.declineCompletion = declineCompletion
        
        guard let tc = appConfig?.generalconfigs?.termsAndConditions else {
            print("Warning: showTermsAndConditions is true but terms_and_conditions config is missing")
            completion()
            return
        }
        
        descriptionTextView.text = tc.description ?? ""
        descriptionTextView.delegate = self
        
        acceptButton.setTitle(tc.acceptButtonText ?? appConfig?.generalconfigs?.continueText ?? "Accept", for: .normal)
        declineButton.setTitle(tc.declineButtonText ?? "Decline", for: .normal)
        
        // Initially disable buttons and dim them
        acceptButton.isEnabled = false
        acceptButton.alpha = 0.5
        declineButton.isEnabled = false
        declineButton.alpha = 0.5
        
        // Check if content is small enough that scroll is not needed
        DispatchQueue.main.async { [weak self] in
            self?.checkIfScrollIsNeeded()
        }
        
        if let generalConfig = appConfig?.generalconfigs {
            let buttonRadius = CGFloat(generalConfig.buttonRadius ?? 10)
            
            descriptionTextView.textColor = hextoUIColor(hexString: generalConfig.appFontColor ?? "#20202F")
            
            acceptButton.backgroundColor = hextoUIColor(hexString: generalConfig.primaryButtonBackgroundColor ?? ThemeColor.primaryColor.toHexString())
            acceptButton.setTitleColor(hextoUIColor(hexString: generalConfig.primaryButtonTextColor ?? "#FFFFFF"), for: .normal)
            acceptButton.layer.cornerRadius = 28
            acceptButton.clipsToBounds = true
            
            declineButton.backgroundColor = .clear
            let declineColor = hextoUIColor(hexString: generalConfig.secondaryButtonTextColor ?? generalConfig.primaryButtonBackgroundColor ?? "#EA3365")
            declineButton.setTitleColor(declineColor, for: .normal)
            declineButton.layer.borderColor = declineColor.cgColor
            declineButton.layer.cornerRadius = 28
            declineButton.clipsToBounds = true
        }
    }
    
    @objc private func acceptPressed() {
        Amani.sharedInstance.customerInfo().acceptTermsConditions { [weak self] success in
            if success {
                self?.completion?()
            } else {
                // In a real app, show an error alert. 
                // For now, we proceed as per the requirement or just try again.
                print("Failed to accept T&C")
                self?.completion?() // Proceeding anyway or handling error
            }
        }
    }
    
    @objc private func declinePressed() {
        // As per user request: "users will be able to continue even if they reject... we just need to keep the log of it"
        print("User declined Terms and Conditions")
        declineCompletion?()
    }
    
    // MARK: - UITextViewDelegate & Scroll Logic
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let height = scrollView.frame.size.height
        let contentYoffset = scrollView.contentOffset.y
        let distanceFromBottom = scrollView.contentSize.height - contentYoffset
        
        // Use a small threshold (1.0) to account for floating point precision
        if (distanceFromBottom <= height + 1.0) {
            enableActionButtons()
        }
    }
    
    private func checkIfScrollIsNeeded() {
        // If the content size is smaller than or equal to the frame size, 
        // the user doesn't need to scroll.
        if descriptionTextView.contentSize.height <= descriptionTextView.frame.size.height {
            enableActionButtons()
        }
    }
    
    private func enableActionButtons() {
        if !acceptButton.isEnabled {
            acceptButton.isEnabled = true
            acceptButton.alpha = 1.0
            
            declineButton.isEnabled = true
            declineButton.alpha = 1.0
        }
    }
}
