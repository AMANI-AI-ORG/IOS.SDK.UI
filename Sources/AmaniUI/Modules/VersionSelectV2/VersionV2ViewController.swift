import UIKit
import AmaniSDK

class VersionV2ViewController: BaseViewController {

    // MARK: - Data

    var documentHandler: DocumentHandlerHelper?
    var stepVM: KYCStepViewModel!
    private var allStepModels: [KYCStepViewModel]?
    private var selectedVersion: DocumentVersion?
    private var optionCards: [DocumentOptionCard] = []

    // MARK: - UI

    private let progressView = StepProgressView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let scrollView = UIScrollView()
    private let cardsStack = UIStackView()
    private let ctaButton = UIButton(type: .custom)

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    // MARK: - Bind

    func bind(
        runnerHelper: DocumentHandlerHelper,
        step: KYCStepViewModel,
        allStepModels: [KYCStepViewModel]?
    ) {
        self.documentHandler = runnerHelper
        self.stepVM = step
        self.allStepModels = allStepModels
    }

    // MARK: - Setup

    private func setupUI() {
        let gc = AmaniUI.sharedInstance.config?.generalconfigs
        let fontColor = hextoUIColor(hexString: gc?.appFontColor ?? "FFFFFF")
        let accentColor = hextoUIColor(hexString: gc?.primaryButtonBackgroundColor ?? "#C0395A")
        let bgColor = hextoUIColor(hexString: gc?.appBackground ?? "FFFFFF")
        view.backgroundColor = bgColor

        // Navigation bar
        let navTitle = stepVM?.stepConfig.title ?? "Choose your ID"
        setNavigationBarWith(title: navTitle)
        let backButton = makeNavButton(
            icon: UIImage(systemName: "arrow.left"),
            tintColor: hextoUIColor(hexString: gc?.topBarFontColor ?? "1A1A2E")
        )
        backButton.addTarget(self, action: #selector(popViewController), for: .touchUpInside)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backButton)

        // Title
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont.systemFont(ofSize: 26, weight: .bold)
        titleLabel.textColor = fontColor
        titleLabel.numberOfLines = 0
        titleLabel.text = stepVM?.stepConfig.documentSelectionTitle?.isEmpty == false
            ? stepVM.stepConfig.documentSelectionTitle
            : "Which ID will you use?"

        // Subtitle
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        subtitleLabel.textColor = fontColor.withAlphaComponent(0.55)
        subtitleLabel.numberOfLines = 0
        subtitleLabel.text = stepVM?.stepConfig.documentSelectionDescription?.isEmpty == false
            ? stepVM.stepConfig.documentSelectionDescription
            : "Pick the document you'd like to upload."

        // Cards stack
        cardsStack.axis = .vertical
        cardsStack.spacing = 10
        cardsStack.translatesAutoresizingMaskIntoConstraints = false
        buildOptionCards(accentColor: accentColor, fontColor: fontColor)

        // Content stack (conditionally include progress view)
        var contentViews: [UIView] = []
        let showProgress = allStepModels?.isEmpty == false
        if showProgress, let steps = allStepModels {
            progressView.translatesAutoresizingMaskIntoConstraints = false
            progressView.configure(steps: steps, accentColor: accentColor)
            contentViews.append(progressView)
        }
        contentViews.append(titleLabel)
        contentViews.append(subtitleLabel)
        contentViews.append(cardsStack)

        let contentStack = UIStackView(arrangedSubviews: contentViews)
        contentStack.axis = .vertical
        contentStack.spacing = 0
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        if showProgress {
            contentStack.setCustomSpacing(20, after: progressView)
        }
        contentStack.setCustomSpacing(6, after: titleLabel)
        contentStack.setCustomSpacing(24, after: subtitleLabel)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.addSubview(contentStack)

        // CTA button (disabled until a selection is made)
        ctaButton.translatesAutoresizingMaskIntoConstraints = false
        ctaButton.backgroundColor = accentColor.withAlphaComponent(0.35)
        ctaButton.setTitleColor(.white, for: .normal)
        ctaButton.setTitleColor(UIColor.white.withAlphaComponent(0.6), for: .disabled)
        ctaButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        ctaButton.layer.cornerRadius = AmaniUI.sharedInstance.style.ctaButtonCornerRadius
        ctaButton.setTitle("Select a document to continue", for: .normal)
        ctaButton.isEnabled = false
        ctaButton.addTarget(self, action: #selector(ctaTapped), for: .touchUpInside)

        view.addSubview(scrollView)
        view.addSubview(ctaButton)

        let ctaBottomPad: CGFloat = 16

        NSLayoutConstraint.activate([
            ctaButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            ctaButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            ctaButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -ctaBottomPad),
            ctaButton.heightAnchor.constraint(equalToConstant: AmaniUI.sharedInstance.style.ctaButtonHeight),

            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: ctaButton.topAnchor, constant: -10),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40),
        ] + (showProgress ? [progressView.heightAnchor.constraint(equalToConstant: 44)] : []))
    }

    // MARK: - Cards

    private func buildOptionCards(accentColor: UIColor, fontColor: UIColor) {
        guard let versions = documentHandler?.versionList, !versions.isEmpty else { return }

        cardsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        optionCards.removeAll()

        for (i, version) in versions.enumerated() {
            let card = DocumentOptionCard()
            card.configure(version: version, isSelected: false, accentColor: accentColor, fontColor: fontColor) { [weak self] in
                self?.selectVersion(at: i)
            }
            cardsStack.addArrangedSubview(card)
            optionCards.append(card)
        }
    }

    private func selectVersion(at index: Int) {
        let gc = AmaniUI.sharedInstance.config?.generalconfigs
        let accentColor = hextoUIColor(hexString: gc?.primaryButtonBackgroundColor ?? "#C0395A")
        let fontColor = hextoUIColor(hexString: gc?.appFontColor ?? "FFFFFF")
        guard let versions = documentHandler?.versionList, index < versions.count else { return }

        selectedVersion = versions[index]

        for (i, card) in optionCards.enumerated() {
            card.configure(version: versions[i], isSelected: i == index, accentColor: accentColor, fontColor: fontColor) { [weak self] in
                self?.selectVersion(at: i)
            }
        }

        let title = selectedVersion?.title ?? "Continue"
        UIView.animate(withDuration: 0.2) {
            self.ctaButton.backgroundColor = accentColor
            self.ctaButton.setTitle("Continue with \(title)", for: .normal)
            self.ctaButton.isEnabled = true
        }
    }

    // MARK: - Actions

    @objc private func ctaTapped() {
        guard let version = selectedVersion else { return }
        documentHandler?.onVersionPressed(version: version)
    }

    // MARK: - Nav button helper

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
}
