import UIKit
import AmaniSDK

class HomeV2ViewController: HomeViewController {

    // MARK: - V2 UI properties

    private let progressView = StepProgressView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let scrollView = UIScrollView()
    private let stepsStack = UIStackView()
    private var stepCards: [HomeV2StepCard] = []

    // MARK: - Lifecycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    // MARK: - setupUI override (called by HomeViewController.viewWillAppear)

    override func setupUI() {
        guard let appConfig = AmaniUI.sharedInstance.config else { return }
        let accentColor = accentColor(from: appConfig)

        isSuccess = false
        configureNavigationBar(appConfig: appConfig, accentColor: accentColor)
        buildV2Layout()

        let customerInfo = resolvedCustomerInfo()
        configureAllViews(customerInfo: customerInfo, accentColor: accentColor)
        goToSuccess()
    }

    // MARK: - setCustomerInfo override
    // Called by HomeViewController.setupUI — not used in v2 since we override setupUI fully.
    // Only kept for the notification-driven refresh path (onStepModel).
    override func setCustomerInfo(model: CustomerResponseModel) {
        guard let steps = stepModels, !steps.isEmpty else { return }
        let appConfig = AmaniUI.sharedInstance.config
        let accent = accentColor(from: appConfig)
        configureAllViews(customerInfo: model, accentColor: accent)
    }

    // MARK: - onStepModel override

    override func onStepModel(rules: [KYCRuleModel]?) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.viewAppeared else { return }
            _ = try? self.generateKYCStepViewModels(from: AmaniUI.sharedInstance.rulesKYC)
            let accent = self.accentColor(from: AmaniUI.sharedInstance.config)
            self.configureAllViews(customerInfo: nil, accentColor: accent)
            self.goToSuccess()
        }
    }

    // MARK: - Navigation bar

    private func configureNavigationBar(appConfig: AppConfigModel, accentColor: UIColor) {
        let titleText = appConfig.generalconfigs?.mainTitleText ?? "Verification"
        setNavigationBarWith(title: titleText)

        // Back button — rounded square
        let backButton = makeNavButton(
            icon: UIImage(systemName: "arrow.left"),
            tintColor: hextoUIColor(hexString: appConfig.generalconfigs?.topBarFontColor ?? "1A1A2E")
        )
        backButton.addTarget(self, action: #selector(popViewController), for: .touchUpInside)
        let backBarItem = UIBarButtonItem(customView: backButton)
#if compiler(>=6.2)
      if #available(iOS 26.0, *) {
        backBarItem.hidesSharedBackground = true
      }
#endif
        navigationItem.leftBarButtonItem = backBarItem

    }

    private func makeNavButton(icon: UIImage?, tintColor: UIColor) -> UIButton {
        let button = UIButton(type: .custom)
        let size = AmaniUI.sharedInstance.style.navButtonSize
        let symConfig = UIImage.SymbolConfiguration(pointSize: 13, weight: .medium)
        button.setImage(icon?.withConfiguration(symConfig).withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = tintColor
        button.backgroundColor = tintColor.withAlphaComponent(0.3)
        button.layer.cornerRadius = AmaniUI.sharedInstance.style.navButtonCornerRadius
        button.layer.cornerCurve = .continuous
        button.frame = CGRect(x: 0, y: 0, width: size, height: size)
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: size),
            button.heightAnchor.constraint(equalToConstant: size),
        ])
        return button
    }

    // MARK: - Build layout (called once)

    private func buildV2Layout() {
        guard stepsStack.arrangedSubviews.isEmpty else { return }

        view.subviews.forEach { $0.removeFromSuperview() }

        // Progress view
        progressView.translatesAutoresizingMaskIntoConstraints = false

        let gc = AmaniUI.sharedInstance.config?.generalconfigs
        let fontColor = hextoUIColor(hexString: gc?.appFontColor ?? "FFFFFF")

        // Title
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont.systemFont(ofSize: 26, weight: .bold)
        titleLabel.textColor = fontColor
        titleLabel.numberOfLines = 0

        // Subtitle
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        subtitleLabel.textColor = fontColor.withAlphaComponent(0.55)
        subtitleLabel.numberOfLines = 0

        // Steps stack
        stepsStack.axis = .vertical
        stepsStack.spacing = 10
        stepsStack.translatesAutoresizingMaskIntoConstraints = false

        // Scroll content assembly
        let contentStack = UIStackView(arrangedSubviews: [progressView, titleLabel, subtitleLabel, stepsStack])
        contentStack.axis = .vertical
        contentStack.spacing = 0
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        contentStack.setCustomSpacing(20, after: progressView)
        contentStack.setCustomSpacing(6, after: titleLabel)
        contentStack.setCustomSpacing(24, after: subtitleLabel)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.addSubview(contentStack)

        view.addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),

            // Content stack fills scroll view width
            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40),

            // Progress view fixed height
            progressView.heightAnchor.constraint(equalToConstant: 56),
        ])
    }

    // MARK: - Configure views with data

    private func configureAllViews(customerInfo: CustomerResponseModel?, accentColor: UIColor) {
        guard let steps = stepModels, !steps.isEmpty else { return }

        let hasProgress = steps.contains { $0.status == .APPROVED || $0.status == .PENDING_REVIEW }

        // Progress indicator
        progressView.configure(steps: steps, accentColor: accentColor)

        // Header text
        let (title, subtitle) = headerContent(steps: steps)
        titleLabel.text = title
        subtitleLabel.text = subtitle

        // Step cards
        stepsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        stepCards.removeAll()

        for (i, step) in steps.enumerated() {
            let card = HomeV2StepCard()
            card.configure(
                step: step,
                index: i,
                accentColor: accentColor,
                hasProgress: hasProgress,
                onTap: isSelectable(step) ? { [weak self] in self?.navigateToStep(step: step) } : nil
            )
            stepsStack.addArrangedSubview(card)
            stepCards.append(card)
        }
    }

    // MARK: - Selection

    private func isSelectable(_ step: KYCStepViewModel) -> Bool {
        return step.isEnabled()
            && step.status != .APPROVED
            && step.status != .PENDING_REVIEW
            && step.status != .PROCESSING
    }

    private func navigateToStep(step: KYCStepViewModel) {
        guard isSelectable(step) else { return }

        step.onStepPressed { [weak self] result in
            switch result {
            case .failure(let error):
                print("HomeV2: step press error \(error)")
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    let gc = AmaniUI.sharedInstance.config?.generalconfigs
                    AlertDialogueUtility.shared.showAlertWithActions(
                        vc: self,
                        message: gc?.v2GenericErrorText ?? "Something went wrong. Please try again.",
                        actions: [(gc?.okText ?? "OK", .default)]
                    ) { _ in }
                }
            case .success(let model):
                AmaniUI.sharedInstance.markStepAsProcessing(id: model.id)
                model.updateStatus(status: .PROCESSING)
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    let accent = self.accentColor(from: AmaniUI.sharedInstance.config)
                    self.configureAllViews(customerInfo: nil, accentColor: accent)
                }
                model.upload { _, _ in }
            }
        }
    }

    // MARK: - Header text logic

    private func headerContent(steps: [KYCStepViewModel]) -> (String, String) {
        let gc = AmaniUI.sharedInstance.config?.generalconfigs
        let completedCount = steps.filter { $0.status == .APPROVED || $0.status == .PENDING_REVIEW }.count
        let rejectedCount = steps.filter { $0.status == .REJECTED || $0.status == .AUTOMATICALLY_REJECTED }.count
        let remainingCount = steps.count - completedCount

        if rejectedCount > 0 {
            let template = gc?.v2HomeRejectedSubtitle ?? "{count} steps need your attention before we can continue."
            return (
                gc?.v2HomeRejectedTitle ?? "Verification incomplete",
                template.replacingOccurrences(of: "{count}", with: "\(rejectedCount)")
            )
        } else if completedCount == 0 {
            let template = gc?.v2HomeInitialSubtitle ?? "{count} quick steps. Should take about 2 minutes."
            return (
                gc?.v2HomeInitialTitle ?? "Let's get you verified",
                template.replacingOccurrences(of: "{count}", with: "\(steps.count)")
            )
        } else {
            let template = gc?.v2HomeProgressSubtitle ?? "{count} more steps to finish verification."
            return (
                gc?.v2HomeProgressTitle ?? "You're making progress",
                template.replacingOccurrences(of: "{count}", with: "\(remainingCount)")
            )
        }
    }

    // MARK: - Helpers

    private func accentColor(from config: AppConfigModel?) -> UIColor {
        return hextoUIColor(hexString: config?.generalconfigs?.primaryButtonBackgroundColor ?? "#C0395A")
    }

    private func resolvedCustomerInfo() -> CustomerResponseModel {
        var info = Amani.sharedInstance.customerInfo().getCustomer()
        if info.rules == nil || info.rules!.isEmpty, let stored = customerData {
            info = stored
        }
        return info
    }
}
