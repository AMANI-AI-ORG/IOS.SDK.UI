import UIKit
import AmaniSDK

class HomeV2ViewController: HomeViewController {

    // MARK: - V2 UI properties

    private let progressView = StepProgressView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let scrollView = UIScrollView()
    private let stepsStack = UIStackView()
    private let ctaButton = UIButton(type: .custom)
    private var stepCards: [HomeV2StepCard] = []
    private var selectedStepIndex: Int? = nil

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
        buildV2Layout(accentColor: accentColor)

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
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backButton)

    }

    private func makeNavButton(icon: UIImage?, tintColor: UIColor) -> UIButton {
        let button = UIButton(type: .custom)
        let size = AmaniUI.sharedInstance.style.navButtonSize
        let symConfig = UIImage.SymbolConfiguration(pointSize: 13, weight: .medium)
        button.setImage(icon?.withConfiguration(symConfig).withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = tintColor
        button.backgroundColor = tintColor.withAlphaComponent(0.12)
        button.layer.cornerRadius = AmaniUI.sharedInstance.style.navButtonCornerRadius
        button.frame = CGRect(x: 0, y: 0, width: size, height: size)
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: size),
            button.heightAnchor.constraint(equalToConstant: size),
        ])
        return button
    }

    // MARK: - Build layout (called once)

    private func buildV2Layout(accentColor: UIColor) {
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

        // CTA button
        ctaButton.translatesAutoresizingMaskIntoConstraints = false
        ctaButton.backgroundColor = accentColor
        ctaButton.setTitleColor(.white, for: .normal)
        ctaButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        ctaButton.layer.cornerRadius = AmaniUI.sharedInstance.style.ctaButtonCornerRadius
        ctaButton.addTarget(self, action: #selector(ctaTapped), for: .touchUpInside)

        view.addSubview(scrollView)
        view.addSubview(ctaButton)

        let ctaBottomPad: CGFloat = 16

        NSLayoutConstraint.activate([
            // CTA pinned to bottom
            ctaButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            ctaButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            ctaButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -ctaBottomPad),
            ctaButton.heightAnchor.constraint(equalToConstant: AmaniUI.sharedInstance.style.ctaButtonHeight),

            // ScrollView above CTA
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: ctaButton.topAnchor, constant: -10),

            // Content stack fills scroll view width
            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40),

            // Progress view fixed height
            progressView.heightAnchor.constraint(equalToConstant: 44),
        ])
    }

    // MARK: - Configure views with data

    private func configureAllViews(customerInfo: CustomerResponseModel?, accentColor: UIColor) {
        guard let steps = stepModels, !steps.isEmpty else { return }

        selectedStepIndex = nil
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
                onTap: isSelectable(step) ? { [weak self] in self?.selectStep(at: i) } : nil
            )
            stepsStack.addArrangedSubview(card)
            stepCards.append(card)
        }

        // Auto-select the first actionable step so there is always a clear visual state
        autoSelectFirstActionable(steps: steps, accentColor: accentColor)
    }

    // MARK: - Selection

    private func isSelectable(_ step: KYCStepViewModel) -> Bool {
        return step.isEnabled()
            && step.status != .APPROVED
            && step.status != .PENDING_REVIEW
            && step.status != .PROCESSING
    }

    private func autoSelectFirstActionable(steps: [KYCStepViewModel], accentColor: UIColor) {
        let idx = steps.firstIndex(where: { isSelectable($0) })
        if let idx = idx {
            selectStep(at: idx, animated: false)
        } else {
            // All steps done or locked — CTA says Continue
            ctaButton.backgroundColor = accentColor
            ctaButton.setTitle("Continue", for: .normal)
        }
    }

    private func selectStep(at index: Int, animated: Bool = true) {
        guard let steps = stepModels, index < steps.count else { return }
        selectedStepIndex = index

        let accentColor = accentColor(from: AmaniUI.sharedInstance.config)
        let hasProgress = steps.contains { $0.status == .APPROVED || $0.status == .PENDING_REVIEW }
        let step = steps[index]

        let applyChanges = {
            for (i, card) in self.stepCards.enumerated() {
                if self.isSelectable(steps[i]) {
                    card.alpha = i == index ? 1.0 : 0.45
                } else {
                    card.alpha = 1.0
                }
            }
            self.ctaButton.backgroundColor = accentColor
            self.ctaButton.setTitle(self.ctaTitleForStep(step, hasProgress: hasProgress), for: .normal)
        }

        if animated {
            UIView.animate(withDuration: 0.2, animations: applyChanges)
        } else {
            applyChanges()
        }
    }

    // MARK: - CTA action

    @objc private func ctaTapped() {
        guard let steps = stepModels else { return }
        let index: Int
        if let selected = selectedStepIndex {
            index = selected
        } else if let i = steps.firstIndex(where: { isSelectable($0) }) {
            index = i
        } else {
            return
        }
        navigateToStep(step: steps[index])
    }

    private func navigateToStep(step: KYCStepViewModel) {
        guard isSelectable(step) else { return }

        step.onStepPressed { [weak self] result in
            switch result {
            case .failure(let error):
                print("HomeV2: step press error \(error)")
            case .success(let model):
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
        let completedCount = steps.filter { $0.status == .APPROVED || $0.status == .PENDING_REVIEW }.count
        let rejectedCount = steps.filter { $0.status == .REJECTED || $0.status == .AUTOMATICALLY_REJECTED }.count
        let remainingCount = steps.count - completedCount

        if rejectedCount > 0 {
            let step = rejectedCount == 1 ? "step needs" : "steps need"
            return (
                "Verification incomplete",
                "\(numberWord(rejectedCount).capitalized) \(step) your attention before we can continue."
            )
        } else if completedCount == 0 {
            return (
                "Let's get you verified",
                "\(numberWord(steps.count).capitalized) quick steps. Should take about 2 minutes."
            )
        } else {
            let steps = remainingCount == 1 ? "step" : "steps"
            return (
                "You're making progress",
                "\(numberWord(remainingCount).capitalized) more \(steps) to finish verification."
            )
        }
    }

    private func ctaTitleForStep(_ step: KYCStepViewModel, hasProgress: Bool) -> String {
        let name = step.stepConfig.title ?? step.title
        if step.status == .REJECTED || step.status == .AUTOMATICALLY_REJECTED {
            return "Retake \(name)"
        }
        return hasProgress ? "Continue with \(name)" : "Start with \(name)"
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

    private func numberWord(_ n: Int) -> String {
        switch n {
        case 1: return "one"
        case 2: return "two"
        case 3: return "three"
        case 4: return "four"
        case 5: return "five"
        default: return "\(n)"
        }
    }
}
