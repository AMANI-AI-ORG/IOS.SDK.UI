import UIKit
import AmaniSDK
import Lottie

@available(iOS 13, *)
class ContainerV2ViewController: BaseViewController {

    // MARK: - Business logic

    private var animationName: String?
    private var docStep: DocumentStepModel?
    private var step: steps = .front
    private var totalSteps: Int = 2
    private var isSelfie: Bool = false
    private var bypassIntro: Bool = false
    private var stepModels: [KYCStepViewModel]?
    private var callback: (() -> Void)?
    private var disappearCallback: (() -> Void)?

    // MARK: - V2 UI

    private let scrollView = UIScrollView()
    private let eyebrowLabel = UILabel()
    private let progressView = StepProgressView()
    private let headlineLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let illustrationCard = UIView()
    private var lottieAnimationView: LottieAnimationView?
    private let badgeView = UIView()
    private let badgeIconView = UIImageView()
    private let checklistCard = UIView()
    private let continueButton = UIButton(type: .custom)

    // MARK: - Static content (front/back copy — not yet config-driven)

    private struct PrepContent {
        let navTitle: String
        let headline: String
        let description: String
        let checklistHeader: String
        let checklistItems: [String]
        let badgeIcon: String
    }

    private var content: PrepContent {
        if isSelfie {
            return PrepContent(
                navTitle: "Selfie",
                headline: "Let's take your selfie",
                description: "Look straight at the camera and keep your face centered in the frame.",
                checklistHeader: "BEFORE YOU START",
                checklistItems: [
                    "Good, even lighting on your face",
                    "Remove glasses, hats, or masks",
                    "Hold the phone at eye level",
                ],
                badgeIcon: "faceid"
            )
        }
        switch step {
        case .front:
            return PrepContent(
                navTitle: "Front of ID",
                headline: "Photograph the front side",
                description: "Take the photo in a bright area and make sure the document fits fully in the frame.",
                checklistHeader: "BEFORE YOU SHOOT",
                checklistItems: [
                    "Bright, even lighting",
                    "All four corners visible",
                    "No glare on the photo or text",
                ],
                badgeIcon: "camera.fill"
            )
        case .back:
            return PrepContent(
                navTitle: "Back of ID",
                headline: "Now flip it over",
                description: "We'll read the machine-readable zone (MRZ) on the back of your card.",
                checklistHeader: "BEFORE YOU SHOOT",
                checklistItems: [
                    "MRZ lines fully readable",
                    "Barcode not covered by fingers",
                    "Flat surface, no tilt",
                ],
                badgeIcon: "arrow.triangle.2.circlepath.camera.fill"
            )
        }
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        guard !bypassIntro else { return }
        setupV2UI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if bypassIntro {
            callback?()
            return
        }
        lottieAnimationView?.play()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        lottieAnimationView?.pause()
        disappearCallback?()
    }

    // MARK: - Bind

    func bind(
        animationName: String?,
        docStep: DocumentStepModel?,
        step: steps,
        totalSteps: Int,
        isSelfie: Bool = false,
        bypassIntro: Bool = false,
        stepModels: [KYCStepViewModel]? = nil,
        callback: @escaping () -> Void
    ) {
        self.animationName = animationName
        self.docStep = docStep
        self.step = step
        self.totalSteps = totalSteps
        self.isSelfie = isSelfie
        self.bypassIntro = bypassIntro
        self.stepModels = stepModels
        self.callback = callback
    }

    func setDisappearCallback(_ callback: @escaping () -> Void) {
        self.disappearCallback = callback
    }

    // MARK: - UI Setup

    private func setupV2UI() {
        let appConfig = try? Amani.sharedInstance.appConfig().getApplicationConfig()
        let gc = appConfig?.generalconfigs
        let fontColor = hextoUIColor(hexString: gc?.appFontColor ?? "20202F")
        let accentColor = hextoUIColor(hexString: gc?.primaryButtonBackgroundColor ?? "#C0395A")
        let bgColor = hextoUIColor(hexString: gc?.appBackground ?? "FFFFFF")
        view.backgroundColor = bgColor

        // Navigation bar
        setNavigationBarWith(title: content.navTitle, textColor: hextoUIColor(hexString: gc?.topBarFontColor ?? "1A1A2E"))
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

        // Eyebrow (ID front/back) or progress bar (selfie)
        eyebrowLabel.translatesAutoresizingMaskIntoConstraints = false
        let eyebrowText = "STEP \(step.rawValue + 1) OF \(totalSteps) · PHOTO CAPTURE"
        eyebrowLabel.attributedText = NSAttributedString(string: eyebrowText, attributes: [.kern: 0.5])
        eyebrowLabel.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        eyebrowLabel.textColor = fontColor.withAlphaComponent(0.45)

        progressView.translatesAutoresizingMaskIntoConstraints = false
        if let stepModels = stepModels, !stepModels.isEmpty {
            progressView.configure(steps: stepModels, accentColor: accentColor)
        }

        // Headline
        headlineLabel.translatesAutoresizingMaskIntoConstraints = false
        headlineLabel.text = content.headline
        headlineLabel.font = UIFont.systemFont(ofSize: 26, weight: .bold)
        headlineLabel.textColor = fontColor
        headlineLabel.numberOfLines = 0

        // Description
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.text = content.description
        descriptionLabel.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        descriptionLabel.textColor = fontColor.withAlphaComponent(0.55)
        descriptionLabel.numberOfLines = 0

        // Illustration card
        buildIllustrationCard(accentColor: accentColor)

        // Checklist card
        buildChecklistCard(fontColor: fontColor, accentColor: accentColor)

        // Content stack
        let topView: UIView = isSelfie ? progressView : eyebrowLabel
        let contentStack = UIStackView(arrangedSubviews: [topView, headlineLabel, descriptionLabel, illustrationCard, checklistCard])
        contentStack.axis = .vertical
        contentStack.spacing = 0
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.setCustomSpacing(isSelfie ? 20 : 8, after: topView)
        contentStack.setCustomSpacing(6, after: headlineLabel)
        contentStack.setCustomSpacing(24, after: descriptionLabel)
        contentStack.setCustomSpacing(20, after: illustrationCard)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.addSubview(contentStack)

        // Continue button
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        continueButton.setTitle("Open camera", for: .normal)
        continueButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        continueButton.setTitleColor(hextoUIColor(hexString: gc?.primaryButtonTextColor ?? "FFFFFF"), for: .normal)
        continueButton.backgroundColor = accentColor
        continueButton.layer.cornerRadius = AmaniUI.sharedInstance.style.ctaButtonCornerRadius
        let cameraIcon = UIImage(systemName: "camera.fill")?.withRenderingMode(.alwaysTemplate)
        continueButton.setImage(cameraIcon, for: .normal)
        continueButton.tintColor = hextoUIColor(hexString: gc?.primaryButtonTextColor ?? "FFFFFF")
        continueButton.semanticContentAttribute = .forceLeftToRight
        continueButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 8)
        continueButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0)
        continueButton.addTarget(self, action: #selector(continueButtonPressed(_:)), for: .touchUpInside)

        view.addSubview(scrollView)
        view.addSubview(continueButton)

        let ctaHeight = AmaniUI.sharedInstance.style.ctaButtonHeight

        var constraints = [
            continueButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            continueButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            continueButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            continueButton.heightAnchor.constraint(equalToConstant: ctaHeight),

            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: continueButton.topAnchor, constant: -12),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 12),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40),

            illustrationCard.heightAnchor.constraint(equalTo: illustrationCard.widthAnchor, multiplier: 0.75),
        ]

        if isSelfie {
            constraints.append(progressView.heightAnchor.constraint(equalToConstant: 56))
        }

        NSLayoutConstraint.activate(constraints)
    }

    private func buildIllustrationCard(accentColor: UIColor) {
        illustrationCard.translatesAutoresizingMaskIntoConstraints = false
        illustrationCard.backgroundColor = .clear
        illustrationCard.layer.cornerRadius = AmaniUI.sharedInstance.style.cardCornerRadius
        illustrationCard.clipsToBounds = false

        let side = step == .front ? "front" : "back"
        let primaryName = isSelfie ? "xxx_se_0_front" : "\((animationName ?? "id").lowercased())_\(side)"
        let fallbackName = isSelfie ? "xxx_se_0_front" : "xxx_id_\(side)"
        let animation = LottieAnimation.named(primaryName, bundle: AmaniUI.sharedInstance.getBundle())
            ?? LottieAnimation.named(fallbackName, bundle: AmaniUI.sharedInstance.getBundle())

        let lottieView = LottieAnimationView(animation: animation)
        lottieView.translatesAutoresizingMaskIntoConstraints = false
        lottieView.backgroundColor = .clear
        lottieView.contentMode = .scaleAspectFit
        lottieView.loopMode = .loop
        lottieView.layer.cornerRadius = AmaniUI.sharedInstance.style.cardCornerRadius
        lottieView.clipsToBounds = true
        self.lottieAnimationView = lottieView

        let badgeSize = AmaniUI.sharedInstance.style.badgeSize
        badgeView.translatesAutoresizingMaskIntoConstraints = false
        badgeView.backgroundColor = accentColor
        badgeView.layer.cornerRadius = badgeSize / 2

        badgeIconView.translatesAutoresizingMaskIntoConstraints = false
        badgeIconView.image = UIImage(systemName: content.badgeIcon)?.withRenderingMode(.alwaysTemplate)
        badgeIconView.tintColor = .white
        badgeIconView.contentMode = .scaleAspectFit

        badgeView.addSubview(badgeIconView)
        illustrationCard.addSubview(lottieView)
        illustrationCard.addSubview(badgeView)

        NSLayoutConstraint.activate([
            lottieView.topAnchor.constraint(equalTo: illustrationCard.topAnchor),
            lottieView.bottomAnchor.constraint(equalTo: illustrationCard.bottomAnchor),
            lottieView.leadingAnchor.constraint(equalTo: illustrationCard.leadingAnchor),
            lottieView.trailingAnchor.constraint(equalTo: illustrationCard.trailingAnchor),

            badgeView.topAnchor.constraint(equalTo: illustrationCard.topAnchor, constant: -badgeSize / 3),
            badgeView.trailingAnchor.constraint(equalTo: illustrationCard.trailingAnchor, constant: badgeSize / 3),
            badgeView.widthAnchor.constraint(equalToConstant: badgeSize),
            badgeView.heightAnchor.constraint(equalToConstant: badgeSize),

            badgeIconView.centerXAnchor.constraint(equalTo: badgeView.centerXAnchor),
            badgeIconView.centerYAnchor.constraint(equalTo: badgeView.centerYAnchor),
            badgeIconView.widthAnchor.constraint(equalToConstant: badgeSize * 0.45),
            badgeIconView.heightAnchor.constraint(equalToConstant: badgeSize * 0.45),
        ])

        lottieView.play()
    }

    private func buildChecklistCard(fontColor: UIColor, accentColor: UIColor) {
        checklistCard.translatesAutoresizingMaskIntoConstraints = false
        checklistCard.backgroundColor = fontColor.withAlphaComponent(0.05)
        checklistCard.layer.cornerRadius = AmaniUI.sharedInstance.style.cardCornerRadius
        checklistCard.layer.borderWidth = 1
        checklistCard.layer.borderColor = fontColor.withAlphaComponent(0.1).cgColor

        let headerLabel = UILabel()
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        headerLabel.text = content.checklistHeader
        headerLabel.font = UIFont.systemFont(ofSize: 11, weight: .semibold)
        headerLabel.textColor = fontColor.withAlphaComponent(0.45)

        let rowsStack = UIStackView(arrangedSubviews: content.checklistItems.map { makeChecklistRow(text: $0, fontColor: fontColor, accentColor: accentColor) })
        rowsStack.axis = .vertical
        rowsStack.spacing = 14
        rowsStack.translatesAutoresizingMaskIntoConstraints = false

        checklistCard.addSubview(headerLabel)
        checklistCard.addSubview(rowsStack)

        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: checklistCard.topAnchor, constant: 16),
            headerLabel.leadingAnchor.constraint(equalTo: checklistCard.leadingAnchor, constant: 16),
            headerLabel.trailingAnchor.constraint(equalTo: checklistCard.trailingAnchor, constant: -16),

            rowsStack.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 14),
            rowsStack.leadingAnchor.constraint(equalTo: checklistCard.leadingAnchor, constant: 16),
            rowsStack.trailingAnchor.constraint(equalTo: checklistCard.trailingAnchor, constant: -16),
            rowsStack.bottomAnchor.constraint(equalTo: checklistCard.bottomAnchor, constant: -16),
        ])
    }

    private func makeChecklistRow(text: String, fontColor: UIColor, accentColor: UIColor) -> UIView {
        let checkContainer = UIView()
        checkContainer.translatesAutoresizingMaskIntoConstraints = false
        checkContainer.layer.cornerRadius = 12
        checkContainer.backgroundColor = accentColor.withAlphaComponent(0.12)

        let checkIcon = UIImageView()
        checkIcon.translatesAutoresizingMaskIntoConstraints = false
        checkIcon.image = UIImage(systemName: "checkmark")?.withRenderingMode(.alwaysTemplate)
        checkIcon.tintColor = accentColor
        checkIcon.contentMode = .scaleAspectFit
        checkContainer.addSubview(checkIcon)

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = text
        label.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        label.textColor = fontColor
        label.numberOfLines = 0

        let row = UIStackView(arrangedSubviews: [checkContainer, label])
        row.axis = .horizontal
        row.spacing = 12
        row.alignment = .center
        row.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            checkContainer.widthAnchor.constraint(equalToConstant: 24),
            checkContainer.heightAnchor.constraint(equalToConstant: 24),
            checkIcon.centerXAnchor.constraint(equalTo: checkContainer.centerXAnchor),
            checkIcon.centerYAnchor.constraint(equalTo: checkContainer.centerYAnchor),
            checkIcon.widthAnchor.constraint(equalToConstant: 12),
            checkIcon.heightAnchor.constraint(equalToConstant: 12),
        ])

        return row
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

    // MARK: - Actions

    @objc func continueButtonPressed(_ sender: Any) {
        callback?()
    }
}
