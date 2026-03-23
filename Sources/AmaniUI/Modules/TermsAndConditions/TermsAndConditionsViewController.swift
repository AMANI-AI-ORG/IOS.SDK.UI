
import Foundation
import UIKit
import AmaniSDK

class TermsAndConditionsViewController: BaseViewController {
    private let tcView = TermsAndConditionsView()
    private var handler: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        guard let appConfig = try? Amani.sharedInstance.appConfig().getApplicationConfig() else {
            print("AppConfigError")
            return
        }
        
        view.backgroundColor = hextoUIColor(hexString: appConfig.generalconfigs?.appBackground ?? "#EEF4FA")
        
        tcView.appConfig = appConfig
        self.title = appConfig.generalconfigs?.termsAndConditions?.title ?? "Terms and Conditions"
        
        tcView.bind(completion: { [weak self] in
            self?.handler?()
        }, declineCompletion: { [weak self] in
            self?.handler?()
        })
        
        view.addSubview(tcView)
        tcView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tcView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            tcView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            tcView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            tcView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
        
        addPoweredByIcon()
    }
    
    func setCompletionHandler(_ handler: @escaping (() -> Void)) {
        self.handler = handler
    }
    
    // This is needed because NonKYCStepManager expects a bind method if we follow the pattern
    func bind(stepVM: KYCStepViewModel?) {
        // T&C might not need a full stepVM if it's purely config driven, 
        // but we keep it for consistency with NonKYCStepManager
    }
}
