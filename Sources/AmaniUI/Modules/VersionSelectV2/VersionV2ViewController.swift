import UIKit
import AmaniSDK

class VersionV2ViewController: BaseViewController {

    // MARK: - Data

    var documentHandler: DocumentHandlerHelper?
    var stepVM: KYCStepViewModel!
    private var allStepModels: [KYCStepViewModel]?

    // MARK: - UI

    private let progressView = StepProgressView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let scrollView = UIScrollView()
    private let cardsStack = UIStackView()

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
        let backBarItem = UIBarButtonItem(customView: backButton)
#if compiler(>=6.2)
      if #available(iOS 26.0, *) {
        backBarItem.hidesSharedBackground = true
      }
#endif
        navigationItem.leftBarButtonItem = backBarItem

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

        view.addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40),
        ] + (showProgress ? [progressView.heightAnchor.constraint(equalToConstant: 56)] : []))
    }

    // MARK: - Cards

    private func buildOptionCards(accentColor: UIColor, fontColor: UIColor) {
        guard let versions = documentHandler?.versionList, !versions.isEmpty else { return }

        cardsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for version in versions {
            let card = DocumentOptionCard()
            card.configure(version: version, accentColor: accentColor, fontColor: fontColor) { [weak self] in
                self?.documentHandler?.onVersionPressed(version: version)
            }
            cardsStack.addArrangedSubview(card)
        }
    }

    // MARK: - Nav button helper

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
}
