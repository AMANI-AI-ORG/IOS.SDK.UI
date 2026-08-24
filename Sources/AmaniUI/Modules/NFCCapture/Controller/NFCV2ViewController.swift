import UIKit
import AmaniSDK
import Lottie

@available(iOS 13, *)
class NFCV2ViewController: BaseViewController {

    // MARK: - Business logic (mirrored from NFCViewController)

    var nfcFormView: NFCConfigureV2View!
    var docID: String?
    private var documentVersion: DocumentVersion?
    private var onFinishCallback: (() -> Void)?
    private var appConfig: AppConfigModel?
    private var nfcNavTitle: String?
    var isDone: Bool = false
    var maxAttempts: Int = 0
    let idCaptureModule = Amani.sharedInstance.IdCapture()
    let amani: Amani = Amani.sharedInstance

    // MARK: - V2 UI

    private let illustrationContainer = UIView()
    private var lottieAnimationView: LottieAnimationView?
    private let captionLabel = UILabel()
    private let continueButton = UIButton(type: .custom)

    private var captionTimer: Timer?

    // MARK: - Animation states (mirrors nfc_animation_v2.json's `amani.textStates` markers)

    private struct AnimationState {
        let marker: String
        let key: String
        let frame: CGFloat
    }

    private static let animationStates: [AnimationState] = [
        AnimationState(marker: "state:place", key: "place", frame: 0),
        AnimationState(marker: "state:detected", key: "detected", frame: 36),
        AnimationState(marker: "state:hold", key: "hold", frame: 66),
        AnimationState(marker: "state:reading", key: "reading", frame: 96),
        AnimationState(marker: "state:dontMove", key: "dontMove", frame: 132),
        AnimationState(marker: "state:remove", key: "remove", frame: 164),
        AnimationState(marker: "state:retry", key: "retry", frame: 224),
        AnimationState(marker: "state:success", key: "success", frame: 267),
    ]

    /// The Lottie file has no native text layers — these captions are the only on-screen copy
    /// describing each state, rendered as a native label kept in sync with the animation's frame.
    /// Proposed future server config key: `nfcV2.animationStates`. Deferred, per spec — hardcoded until that config exists.
    private static let defaultCaptions: [String: String] = [
        "place": "Place the document behind your phone",
        "detected": "Chip located",
        "hold": "Hold still",
        "reading": "Reading…",
        "dontMove": "Don't move your phone",
        "remove": "You can take the phone away",
        "retry": "Try again and reposition the phone",
        "success": "Read complete",
    ]

    /// Recolor defaults for the semantic keypaths authored in nfc_animation_v2.json.
    /// Per spec these are NOT config-driven — override here if the palette ever needs to change.
    private enum AnimationColor {
        static let accent = hextoUIColor(hexString: "ED2C5F")
        static let accentStroke = hextoUIColor(hexString: "ED2C5F")
        static let onColor = hextoUIColor(hexString: "FFFFFF")
        static let device = hextoUIColor(hexString: "2A3143")
        static let deviceStroke = hextoUIColor(hexString: "2A3143")
        static let document = hextoUIColor(hexString: "D8B45E")
        static let documentStroke = hextoUIColor(hexString: "A8873C")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        appConfig = try? amani.appConfig().getApplicationConfig()
        setupV2UI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        playIdleLoop()
        startCaptionSync()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        lottieAnimationView?.pause()
        stopCaptionSync()
#if canImport(AmaniVoiceAssistantSDK)
        Task { @MainActor in
            try? await AmaniUI.sharedInstance.voiceAssistant?.stop()
        }
#endif
    }

    override func popViewController() {
        if let customView = nfcFormView, !customView.isHidden {
            hideCustomView()
        } else {
            super.popViewController()
        }
    }

    func hideCustomView() {
        nfcFormView.isHidden = true
        nfcFormView.removeFromSuperview()
        if let nfcNavTitle = nfcNavTitle {
            navigationItem.title = nfcNavTitle
        }
    }

    // MARK: - Bind

    func bind(documentVersion: DocumentVersion, callback: @escaping () -> Void) {
        self.documentVersion = documentVersion
        self.onFinishCallback = callback
    }

    // MARK: - UI Setup

    private func setupV2UI() {
        guard let docVer = documentVersion else { return }
        let gc = appConfig?.generalconfigs
        let accentColor = hextoUIColor(hexString: gc?.primaryButtonBackgroundColor ?? "#C0395A")
        let bgColor = hextoUIColor(hexString: gc?.appBackground ?? "FFFFFF")
        view.backgroundColor = bgColor

        // Nav bar
        setNavigationBarWith(title: docVer.nfcTitle ?? "")
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

        // Illustration — sized as large as possible and centered on screen.
        buildIllustration()

        // Caption — the animation has no native text layers, so this is the only on-screen copy
        // describing each state, kept in sync with the animation's frame timeline.
        captionLabel.translatesAutoresizingMaskIntoConstraints = false
        captionLabel.text = Self.defaultCaptions[Self.animationStates[0].key]
        captionLabel.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        captionLabel.textColor = accentColor
        captionLabel.textAlignment = .center
        captionLabel.numberOfLines = 0

        // Continue button
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        continueButton.setTitle(gc?.continueText ?? "Continue", for: .normal)
        continueButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        continueButton.setTitleColor(hextoUIColor(hexString: gc?.primaryButtonTextColor ?? "FFFFFF"), for: .normal)
        continueButton.setTitleColor(hextoUIColor(hexString: gc?.primaryButtonTextColor ?? "FFFFFF").withAlphaComponent(0.5), for: .disabled)
        continueButton.backgroundColor = accentColor
        continueButton.layer.cornerRadius = AmaniUI.sharedInstance.style.ctaButtonCornerRadius
        continueButton.addTarget(self, action: #selector(continueButtonPressed(_:)), for: .touchUpInside)

        view.addSubview(illustrationContainer)
        view.addSubview(captionLabel)
        view.addSubview(continueButton)

        let ctaHeight = AmaniUI.sharedInstance.style.ctaButtonHeight

        NSLayoutConstraint.activate([
            // Continue button pinned to bottom
            continueButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            continueButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            continueButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            continueButton.heightAnchor.constraint(equalToConstant: ctaHeight),

            // Caption sits directly above the Continue button with a small gap
            captionLabel.bottomAnchor.constraint(equalTo: continueButton.topAnchor, constant: -12),
            captionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            captionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            captionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),

            // Illustration centered in the remaining space, as large as it can be while keeping
            // the 4:3 aspect ratio that matches the animation's 800x600 canvas.
            illustrationContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            illustrationContainer.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            illustrationContainer.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            illustrationContainer.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            illustrationContainer.heightAnchor.constraint(equalTo: illustrationContainer.widthAnchor, multiplier: 0.75),
            illustrationContainer.topAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            illustrationContainer.bottomAnchor.constraint(lessThanOrEqualTo: captionLabel.topAnchor, constant: -12),
        ])
    }

    // MARK: - Illustration (Lottie)

    private func buildIllustration() {
        illustrationContainer.translatesAutoresizingMaskIntoConstraints = false
        illustrationContainer.backgroundColor = .clear

        let animation = LottieAnimation.named("nfc_animation_v2", bundle: AmaniUI.sharedInstance.getBundle())
        let lottieView = LottieAnimationView(animation: animation)
        lottieView.translatesAutoresizingMaskIntoConstraints = false
        lottieView.backgroundColor = .clear
        lottieView.contentMode = .scaleAspectFit
        applyDynamicColors(to: lottieView)
        illustrationContainer.addSubview(lottieView)
        self.lottieAnimationView = lottieView

        NSLayoutConstraint.activate([
            lottieView.topAnchor.constraint(equalTo: illustrationContainer.topAnchor),
            lottieView.bottomAnchor.constraint(equalTo: illustrationContainer.bottomAnchor),
            lottieView.leadingAnchor.constraint(equalTo: illustrationContainer.leadingAnchor),
            lottieView.trailingAnchor.constraint(equalTo: illustrationContainer.trailingAnchor),
        ])
    }

    /// Recolors the animation's semantic keypaths (see nfc_animation_v2.json's `amani.colorTokens`),
    /// using a `**` wildcard head so one value recolors every shape sharing that name.
    /// Per spec: colors stay code-level defaults (not server-config-driven); only `background` is forced transparent
    /// so the phone-screen cutout shows this screen's real background through it.
    private func applyDynamicColors(to lottieView: LottieAnimationView) {
        let overrides: [(name: String, color: UIColor)] = [
            ("accent", AnimationColor.accent),
            ("accentStroke", AnimationColor.accentStroke),
            ("onColor", AnimationColor.onColor),
            ("device", AnimationColor.device),
            ("deviceStroke", AnimationColor.deviceStroke),
            ("document", AnimationColor.document),
            ("documentStroke", AnimationColor.documentStroke),
        ]
        for override in overrides {
            lottieView.setValueProvider(
                ColorValueProvider(override.color.lottieColorValue),
                keypath: AnimationKeypath(keypath: "**.\(override.name).Color")
            )
        }
        lottieView.setValueProvider(
            ColorValueProvider(UIColor.clear.lottieColorValue),
            keypath: AnimationKeypath(keypath: "**.background.Color")
        )
    }

    // MARK: - Animation playback / caption sync

    private func playIdleLoop() {
        guard let lottieView = lottieAnimationView else { return }
        let removeFrame = Self.animationStates.first(where: { $0.key == "remove" })?.frame ?? 164
        lottieView.play(fromFrame: 0, toFrame: removeFrame, loopMode: .loop)
    }

    /// Plays the phone-removal → checkmark segment on success, or the "try again" cue (stopping
    /// before the checkmark fades in) on failure, then resumes once the animation settles.
    private func playOutcome(success: Bool) async {
        guard let lottieView = lottieAnimationView else { return }
        let removeFrame = Self.animationStates.first(where: { $0.key == "remove" })?.frame ?? 164
        let retryFrame = Self.animationStates.first(where: { $0.key == "retry" })?.frame ?? 224
        let successFrame = Self.animationStates.first(where: { $0.key == "success" })?.frame ?? 267
        let endFrame = lottieView.animation?.endFrame ?? 300
        await withCheckedContinuation { continuation in
            if success {
                lottieView.play(fromFrame: removeFrame, toFrame: endFrame, loopMode: .playOnce) { _ in
                    continuation.resume()
                }
            } else {
                lottieView.play(fromFrame: retryFrame, toFrame: successFrame, loopMode: .playOnce) { _ in
                    continuation.resume()
                }
            }
        }
    }

    private func startCaptionSync() {
        captionTimer?.invalidate()
        captionTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 20.0, repeats: true) { [weak self] _ in
            self?.updateCaption()
        }
    }

    private func stopCaptionSync() {
        captionTimer?.invalidate()
        captionTimer = nil
    }

    private func updateCaption() {
        guard let frame = lottieAnimationView?.currentFrame,
              let state = Self.animationStates.last(where: { $0.frame <= frame }) else { return }
        let caption = Self.defaultCaptions[state.key]
        if captionLabel.text != caption {
            captionLabel.text = caption
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

    // MARK: - Actions (identical logic to v1)

    @objc func continueButtonPressed(_ sender: Any) {
        Task { @MainActor in
#if canImport(AmaniVoiceAssistantSDK)
            if let docID = self.docID {
                try? await AmaniUI.sharedInstance.voiceAssistant?.play(key: "VOICE_\(docID)")
            }
#endif
            maxAttempts += 1
            let sdkMaxAttemptValue = (documentVersion?.maxNfcAttempt ?? (documentVersion?.maxAttempt ?? 3))
            if maxAttempts <= sdkMaxAttemptValue {
                await scanNFC()
            } else {
                self.doNext(done: true)
            }
        }
    }

    func uploadNFCResult() {
        idCaptureModule.upload(location: nil) { isUploadSuccess in
            self.isDone = isUploadSuccess != nil
            self.doNext(done: self.isDone)
        }
    }

    func scanNFC() async {
        continueButton.isEnabled = false
        if let nvi: NviModel = AmaniUI.sharedInstance.nviData {
            let isDone = await idCaptureModule.startNFC(nvi: nvi)
            await playOutcome(success: isDone)
            if isDone {
                self.doNext(done: isDone)
            } else {
                continueButton.isEnabled = true
                await animateWithNFCFormUI(nvi: nvi)
            }
        }
    }

    func doNext(done: Bool) {
        let tryAgainText = try? Amani.sharedInstance.appConfig().getApplicationConfig().generalconfigs?.tryAgainText
        if done {
            DispatchQueue.main.async {
                self.onFinishCallback?()
            }
        } else {
            DispatchQueue.main.async {
                self.continueButton.setTitle(tryAgainText ?? "Try Again", for: .normal)
                self.continueButton.isEnabled = true
            }
        }
    }

    private func setNFCFormUIView(nvi: NviModel) async {
        if nfcNavTitle == nil {
            nfcNavTitle = navigationItem.title
        }
        navigationItem.title = "Chip data"

        nfcFormView = NFCConfigureV2View()
        nfcFormView.appConfig = appConfig
        nfcFormView.setTextsFrom(nvi: nvi)
        nfcFormView.delegate = self
        self.view.addSubview(nfcFormView)

        nfcFormView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            nfcFormView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
            nfcFormView.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor),
            nfcFormView.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor),
            nfcFormView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
        ])

        nfcFormView.setButtonCb = { [weak self] newNvi in
            guard let self = self else { return }
            nfcFormView.removeFromSuperview()
            self.maxAttempts += 1
            let isDone = await self.idCaptureModule.startNFC(nvi: newNvi)
            if isDone {
                self.doNext(done: isDone)
            } else {
                let fallbackNvi = (newNvi.dateOfBirth == "" || newNvi.dateOfExpire == "" || newNvi.documentNo == "") ? nvi : newNvi
                await self.animateWithNFCFormUI(nvi: fallbackNvi)
            }
        }
    }

    private func animateWithNFCFormUI(nvi: NviModel) async {
        await animateAsync(withDuration: 0.3) { [weak self] in
            Task {
                guard let self = self else { return }
#if canImport(AmaniVoiceAssistantSDK)
                try? await AmaniUI.sharedInstance.voiceAssistant?.stop()
#endif
                let sdkMaxAttemptValue = (self.documentVersion?.maxNfcAttempt ?? (self.documentVersion?.maxAttempt ?? 3))
                if self.maxAttempts <= sdkMaxAttemptValue {
                    await self.setNFCFormUIView(nvi: nvi)
                } else {
                    self.doNext(done: true)
                }
            }
        }
    }

    private func animateAsync(withDuration duration: TimeInterval, animations: @escaping () -> Void) async {
        await withCheckedContinuation { continuation in
            UIView.animate(withDuration: duration, animations: animations) { _ in
                continuation.resume()
            }
        }
    }
}

// MARK: - AlertDelegate

@available(iOS 13, *)
extension NFCV2ViewController: AlertDelegate {
    func showAlert(title: String, message: String, actions: [(String, UIAlertAction.Style)], completion: ((Int) -> Void)?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        for (index, action) in actions.enumerated() {
            alert.addAction(UIAlertAction(title: action.0, style: action.1) { _ in completion?(index) })
        }
        self.present(alert, animated: true)
    }
}
