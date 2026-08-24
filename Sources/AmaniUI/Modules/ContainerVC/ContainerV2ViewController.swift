import UIKit
import AmaniSDK
import Lottie

@available(iOS 13, *)
class ContainerV2ViewController: BaseViewController {

    // MARK: - Business logic

    private var animationName: String?
    private var docStep: DocumentStepModel?
    private var documentVersion: DocumentVersion?
    private var step: steps = .front
    private var totalSteps: Int = 2
    private var isSelfie: Bool = false
    private var bypassIntro: Bool = false
    private var callback: (() -> Void)?
    private var disappearCallback: (() -> Void)?

    // MARK: - V2 UI

    private let scrollView = UIScrollView()
    private let eyebrowLabel = UILabel()
    private let headlineLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let illustrationCard = UIView()
    private var lottieAnimationView: LottieAnimationView?
    private let badgeView = UIView()
    private let badgeIconView = UIImageView()
    private let checklistCard = UIView()
    private let continueButton = UIButton(type: .custom)
    private var isLeavingViewHierarchy = false
    private var didInvokeDisappearCallback = false
    private var didStartBoundFlow = false

    // MARK: - Content (config-driven — see v2_prep_config_plan)

    private struct PrepContent {
        let navTitle: String
        let eyebrowLabel: String?
        let headline: String
        let description: String
        let checklistHeader: String
        let checklistItems: [String]
        let badgeIcon: String
    }

    /// `step == .front` is the primary slot (ID front / Selfie first instruction),
    /// `step == .back` is the secondary slot (ID back / Selfie second instruction).
    private var content: PrepContent {
        let isSecondary = step == .back
        let dv = documentVersion
        let gc = (try? Amani.sharedInstance.appConfig().getApplicationConfig())?.generalconfigs

        let title = (isSecondary ? dv?.v2GuideSecondTitle : dv?.v2GuideTitle)
        let description = (isSecondary ? dv?.v2GuideSecondDescription : dv?.v2GuideDescription)
        let checklistHeader = dv?.v2GuideChecklistHeader
        let check1 = isSecondary ? dv?.v2GuideSecondCheck1 : dv?.v2GuideCheck1
        let check2 = isSecondary ? dv?.v2GuideSecondCheck2 : dv?.v2GuideCheck2
        let check3 = isSecondary ? dv?.v2GuideSecondCheck3 : dv?.v2GuideCheck3

        if isSelfie {
            return PrepContent(
                navTitle: docStep?.captureTitle ?? gc?.v2SelfieText ?? "Selfie",
                eyebrowLabel: dv?.v2GuideEyebrow,
                headline: title ?? (isSecondary ? "Follow the movements" : "Let's take your selfie"),
                description: description ?? (isSecondary
                    ? "You'll be asked to turn your head and follow the on-screen prompts."
                    : "Look straight at the camera and keep your face centered in the frame."),
                checklistHeader: (checklistHeader ?? "Before you start").uppercased(),
                checklistItems: isSecondary
                    ? [
                        check1 ?? "Stay in a well-lit area",
                        check2 ?? "Keep your whole face visible",
                        check3 ?? "Move slowly when prompted",
                    ]
                    : [
                        check1 ?? "Good, even lighting on your face",
                        check2 ?? "Remove glasses, hats, or masks",
                        check3 ?? "Hold the phone at eye level",
                    ],
                badgeIcon: isSecondary ? "arrow.triangle.2.circlepath" : "faceid"
            )
        }

        let navTitle = docStep?.captureTitle
            ?? (isSecondary ? gc?.v2BackSideText : gc?.v2FrontSideText)
            ?? (isSecondary ? "Back of ID" : "Front of ID")

        return PrepContent(
            navTitle: navTitle,
            eyebrowLabel: dv?.v2GuideEyebrow ?? "Photo capture",
            headline: title ?? (isSecondary ? "Now flip it over" : "Photograph the front side"),
            description: description ?? (isSecondary
                ? "We'll read the machine-readable zone (MRZ) on the back of your card."
                : "Take the photo in a bright area and make sure the document fits fully in the frame."),
            checklistHeader: (checklistHeader ?? "Before you shoot").uppercased(),
            checklistItems: isSecondary
                ? [
                    check1 ?? "MRZ lines fully readable",
                    check2 ?? "Barcode not covered by fingers",
                    check3 ?? "Flat surface, no tilt",
                ]
                : [
                    check1 ?? "Bright, even lighting",
                    check2 ?? "All four corners visible",
                    check3 ?? "No glare on the photo or text",
                ],
            badgeIcon: isSecondary ? "arrow.triangle.2.circlepath.camera.fill" : "camera.fill"
        )
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        guard !bypassIntro else { return }
        setupV2UI()
    }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    /*
     Settings dönüşü gerçek bir navigation çıkışı değildir.
     */
    isLeavingViewHierarchy = false
    
    if bypassIntro {
      startBoundFlowIfNeeded()
      return
    }
    
    lottieAnimationView?.play()
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    
    lottieAnimationView?.pause()
      
    
    /*
     Cleanup yalnızca controller gerçekten pop veya dismiss
     ediliyorsa yapılır.
     */
    isLeavingViewHierarchy =
    isMovingFromParent ||
    isBeingDismissed ||
    navigationController?.isBeingDismissed == true ||
    tabBarController?.isBeingDismissed == true

    print(
      "[ContainerV2] viewWillDisappear",
      "leavingHierarchy:", isLeavingViewHierarchy,
      "movingFromParent:", isMovingFromParent,
      "beingDismissed:", isBeingDismissed,
      "applicationState:",
      UIApplication.shared.applicationState.rawValue
    )

  }
  
  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    
    guard isLeavingViewHierarchy,
          !didInvokeDisappearCallback else {
      return
    }
    
    didInvokeDisappearCallback = true
    print("[ContainerV2] invoking disappear callback")

    
    disappearCallback?()
  }

    // MARK: - Bind

    func bind(
        animationName: String?,
        docStep: DocumentStepModel?,
        documentVersion: DocumentVersion? = nil,
        step: steps,
        totalSteps: Int,
        isSelfie: Bool = false,
        bypassIntro: Bool = false,
        callback: @escaping () -> Void
    ) {
        self.animationName = animationName
        self.docStep = docStep
        self.documentVersion = documentVersion
        self.step = step
        self.totalSteps = totalSteps
        self.isSelfie = isSelfie
        self.bypassIntro = bypassIntro
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
        let currentContent = content

        // Navigation bar
        setNavigationBarWith(title: currentContent.navTitle, textColor: hextoUIColor(hexString: gc?.topBarFontColor ?? "1A1A2E"))
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

        // Eyebrow — hidden entirely when there's no eyebrow label configured (e.g. Selfie by design)
        let hasEyebrow = !(currentContent.eyebrowLabel?.isEmpty ?? true)
        if hasEyebrow {
            eyebrowLabel.translatesAutoresizingMaskIntoConstraints = false
            let stepPrefixTemplate = documentVersion?.v2GuideStepPrefix ?? "STEP {step} OF {total} · "
            let stepPrefix = stepPrefixTemplate
                .replacingOccurrences(of: "{step}", with: "\(step.rawValue + 1)")
                .replacingOccurrences(of: "{total}", with: "\(totalSteps)")
            let eyebrowText = "\(stepPrefix)\(currentContent.eyebrowLabel!.uppercased())"
            eyebrowLabel.attributedText = NSAttributedString(string: eyebrowText, attributes: [.kern: 0.5])
            eyebrowLabel.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
            eyebrowLabel.textColor = fontColor.withAlphaComponent(0.45)
        }

        // Headline
        headlineLabel.translatesAutoresizingMaskIntoConstraints = false
        headlineLabel.text = currentContent.headline
        headlineLabel.font = UIFont.systemFont(ofSize: 26, weight: .bold)
        headlineLabel.textColor = fontColor
        headlineLabel.numberOfLines = 0

        // Description
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.text = currentContent.description
        descriptionLabel.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        descriptionLabel.textColor = fontColor.withAlphaComponent(0.55)
        descriptionLabel.numberOfLines = 0

        // Illustration card
        buildIllustrationCard(accentColor: accentColor)

        // Checklist card
        buildChecklistCard(fontColor: fontColor, accentColor: accentColor)

        // Content stack
        var arrangedSubviews: [UIView] = []
        if hasEyebrow {
            arrangedSubviews.append(eyebrowLabel)
        }
        arrangedSubviews.append(contentsOf: [headlineLabel, descriptionLabel, illustrationCard, checklistCard])

        let contentStack = UIStackView(arrangedSubviews: arrangedSubviews)
        contentStack.axis = .vertical
        contentStack.spacing = 0
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        if hasEyebrow {
            contentStack.setCustomSpacing(8, after: eyebrowLabel)
        }
        contentStack.setCustomSpacing(6, after: headlineLabel)
        contentStack.setCustomSpacing(24, after: descriptionLabel)
        contentStack.setCustomSpacing(20, after: illustrationCard)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.addSubview(contentStack)

        // Continue button
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        continueButton.setTitle(gc?.v2OpenCameraButtonText ?? "Open camera", for: .normal)
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

        NSLayoutConstraint.activate([
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
        ])
    }

    private func buildIllustrationCard(accentColor: UIColor) {
        illustrationCard.translatesAutoresizingMaskIntoConstraints = false
        illustrationCard.backgroundColor = .clear
        illustrationCard.layer.cornerRadius = AmaniUI.sharedInstance.style.cardCornerRadius
        illustrationCard.clipsToBounds = false

        let side = step == .front ? "front" : "back"
        // Pose estimation is the only selfie flow that reaches a secondary (step == .back) guide screen
        // (see SelfieHandler.showsSecondaryGuide) — so this only ever affects that second screen.
        let isSecondarySelfieGuide = isSelfie && step == .back
        let primaryName = isSelfie
            ? (isSecondarySelfieGuide ? "xxx_se_1_front" : "xxx_se_0_front")
            : "\((animationName ?? "id").lowercased())_\(side)"
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
      startBoundFlowIfNeeded()
    }
  
  private func startBoundFlowIfNeeded() {
    guard !didStartBoundFlow else {

      print("[ContainerV2] duplicate flow start ignored")

      return
    }
    
    didStartBoundFlow = true
    

    print("[ContainerV2] starting bound flow")

    
    callback?()
  }
}
