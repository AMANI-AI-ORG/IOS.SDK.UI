import UIKit
import AmaniSDK

@available(iOS 13, *)
class NFCV2ViewController: BaseViewController {

    // MARK: - Business logic (mirrored from NFCViewController)

    var nfcFormView: NFCConfigureView!
    var docID: String?
    private var documentVersion: DocumentVersion?
    private var onFinishCallback: (() -> Void)?
    private var appConfig: AppConfigModel?
    var isDone: Bool = false
    var maxAttempts: Int = 0
    let idCaptureModule = Amani.sharedInstance.IdCapture()
    let amani: Amani = Amani.sharedInstance

    // MARK: - V2 UI

    private let iconWrapperView = UIView()          // holds pulse layers + icon circle
    private let iconCircle = UIView()
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let searchingRow = UIView()
    private let searchingDot = UIView()
    private let searchingLabel = UILabel()
    private let continueButton = UIButton(type: .custom)

    private var pulseLayers: [CAShapeLayer] = []

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        appConfig = try? amani.appConfig().getApplicationConfig()
        setupV2UI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startPulseAnimations()
        startBlinkAnimation()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
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
        let fontColor = hextoUIColor(hexString: gc?.appFontColor ?? "FFFFFF")
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
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backButton)

        // Pulse wrapper — clips turned OFF so rings can bleed outside
        iconWrapperView.translatesAutoresizingMaskIntoConstraints = false
        iconWrapperView.clipsToBounds = false

        // Icon circle — bigger
        let circleSize: CGFloat = 148
        iconCircle.translatesAutoresizingMaskIntoConstraints = false
        iconCircle.backgroundColor = accentColor
        iconCircle.layer.cornerRadius = circleSize / 2
        iconCircle.clipsToBounds = true

        // NFC icon
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        let nfcSymbol = UIImage(systemName: "wave.3.right") ?? UIImage(systemName: "wifi")
        iconImageView.image = nfcSymbol?.withRenderingMode(.alwaysTemplate)
        iconImageView.tintColor = .white
        iconImageView.contentMode = .scaleAspectFit
        iconCircle.addSubview(iconImageView)
        iconWrapperView.addSubview(iconCircle)

        // Title
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = docVer.nfcTitle
        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = fontColor
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0

        // Subtitle (first description only)
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.text = docVer.nfcDescription1
        subtitleLabel.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        subtitleLabel.textColor = fontColor.withAlphaComponent(0.55)
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0

        // Searching row
        buildSearchingRow(fontColor: fontColor, accentColor: accentColor)

        // Continue button
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        continueButton.setTitle(gc?.continueText ?? "Continue", for: .normal)
        continueButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        continueButton.setTitleColor(hextoUIColor(hexString: gc?.primaryButtonTextColor ?? "FFFFFF"), for: .normal)
        continueButton.setTitleColor(hextoUIColor(hexString: gc?.primaryButtonTextColor ?? "FFFFFF").withAlphaComponent(0.5), for: .disabled)
        continueButton.backgroundColor = accentColor
        continueButton.layer.cornerRadius = AmaniUI.sharedInstance.style.ctaButtonCornerRadius
        continueButton.addTarget(self, action: #selector(continueButtonPressed(_:)), for: .touchUpInside)

        view.addSubview(iconWrapperView)
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(searchingRow)
        view.addSubview(continueButton)

        let ctaHeight = AmaniUI.sharedInstance.style.ctaButtonHeight
        // Wrapper must fit the rings: startRadius = circleSize/2 = 74, scaled ×2.0 = 148pt radius → diameter 296
        let wrapperSize: CGFloat = 300

        NSLayoutConstraint.activate([
            // Icon wrapper pinned near the top — this drives everything upward
            iconWrapperView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            iconWrapperView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            iconWrapperView.widthAnchor.constraint(equalToConstant: wrapperSize),
            iconWrapperView.heightAnchor.constraint(equalToConstant: wrapperSize),

            // Icon circle centered in wrapper
            iconCircle.centerXAnchor.constraint(equalTo: iconWrapperView.centerXAnchor),
            iconCircle.centerYAnchor.constraint(equalTo: iconWrapperView.centerYAnchor),
            iconCircle.widthAnchor.constraint(equalToConstant: circleSize),
            iconCircle.heightAnchor.constraint(equalToConstant: circleSize),

            // NFC icon inside circle
            iconImageView.centerXAnchor.constraint(equalTo: iconCircle.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconCircle.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 64),
            iconImageView.heightAnchor.constraint(equalToConstant: 64),

            // Title below icon
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            titleLabel.topAnchor.constraint(equalTo: iconWrapperView.bottomAnchor, constant: 24),

            // Subtitle below title
            subtitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),

            // Searching row below subtitle
            searchingRow.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            searchingRow.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 20),

            // Continue button pinned to bottom
            continueButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            continueButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            continueButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            continueButton.heightAnchor.constraint(equalToConstant: ctaHeight),
        ])

        buildPulseLayers(accentColor: accentColor, circleSize: circleSize, wrapperSize: wrapperSize)
    }

    private func buildSearchingRow(fontColor: UIColor, accentColor: UIColor) {
        searchingRow.translatesAutoresizingMaskIntoConstraints = false

        searchingDot.translatesAutoresizingMaskIntoConstraints = false
        searchingDot.backgroundColor = accentColor
        searchingDot.layer.cornerRadius = 5

        searchingLabel.translatesAutoresizingMaskIntoConstraints = false
        searchingLabel.text = "Searching for chip..."
        searchingLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        searchingLabel.textColor = fontColor.withAlphaComponent(0.55)

        searchingRow.addSubview(searchingDot)
        searchingRow.addSubview(searchingLabel)

        NSLayoutConstraint.activate([
            searchingDot.leadingAnchor.constraint(equalTo: searchingRow.leadingAnchor),
            searchingDot.centerYAnchor.constraint(equalTo: searchingRow.centerYAnchor),
            searchingDot.widthAnchor.constraint(equalToConstant: 10),
            searchingDot.heightAnchor.constraint(equalToConstant: 10),

            searchingLabel.leadingAnchor.constraint(equalTo: searchingDot.trailingAnchor, constant: 8),
            searchingLabel.trailingAnchor.constraint(equalTo: searchingRow.trailingAnchor),
            searchingLabel.topAnchor.constraint(equalTo: searchingRow.topAnchor),
            searchingLabel.bottomAnchor.constraint(equalTo: searchingRow.bottomAnchor),
        ])
    }

    // MARK: - Pulse ring layers

    private func buildPulseLayers(accentColor: UIColor, circleSize: CGFloat, wrapperSize: CGFloat) {
        pulseLayers.forEach { $0.removeFromSuperlayer() }
        pulseLayers.removeAll()

        // The ring path is centered at the wrapper's midpoint.
        // Setting frame = wrapper bounds ensures anchorPoint (0.5, 0.5)
        // sits exactly on the path center — so transform.scale expands outward uniformly.
        let center = CGPoint(x: wrapperSize / 2, y: wrapperSize / 2)
        let startRadius = circleSize / 2

        for i in 0..<3 {
            let ring = CAShapeLayer()
            ring.frame = CGRect(x: 0, y: 0, width: wrapperSize, height: wrapperSize)
            let path = UIBezierPath(
                arcCenter: center,
                radius: startRadius,
                startAngle: 0,
                endAngle: 2 * .pi,
                clockwise: true
            )
            ring.path = path.cgPath
            ring.fillColor = UIColor.clear.cgColor
            ring.strokeColor = accentColor.cgColor
            ring.lineWidth = 1.5
            ring.opacity = 0
            iconWrapperView.layer.insertSublayer(ring, at: 0)
            pulseLayers.append(ring)

            let scaleAnim = CABasicAnimation(keyPath: "transform.scale")
            scaleAnim.fromValue = 1.0
            scaleAnim.toValue = 2.0

            let opacityAnim = CABasicAnimation(keyPath: "opacity")
            opacityAnim.fromValue = 0.5
            opacityAnim.toValue = 0.0

            let group = CAAnimationGroup()
            group.animations = [scaleAnim, opacityAnim]
            group.duration = 2.4
            group.beginTime = CACurrentMediaTime() + Double(i) * 0.8
            group.repeatCount = .infinity
            group.timingFunction = CAMediaTimingFunction(name: .easeOut)
            group.isRemovedOnCompletion = false
            ring.add(group, forKey: "pulse_\(i)")
        }
    }

    private func startPulseAnimations() {
        pulseLayers.forEach { layer in
            if layer.animation(forKey: "pulse_0") == nil {
                layer.resumeAnimation()
            }
        }
    }

    private func startBlinkAnimation() {
        let blink = CABasicAnimation(keyPath: "opacity")
        blink.fromValue = 1.0
        blink.toValue = 0.15
        blink.duration = 0.9
        blink.autoreverses = true
        blink.repeatCount = .infinity
        blink.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        searchingDot.layer.add(blink, forKey: "blink")
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
        nfcFormView = NFCConfigureView()
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

// MARK: - CALayer resume helper

private extension CALayer {
    func resumeAnimation() {
        let pausedTime = timeOffset
        speed = 1.0
        timeOffset = 0.0
        beginTime = 0.0
        let timeSincePause = convertTime(CACurrentMediaTime(), from: nil) - pausedTime
        beginTime = timeSincePause
    }
}
