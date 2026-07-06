import UIKit
import AmaniSDK

class SuccessV2ViewController: BaseViewController {

    // MARK: - Data

    private var stepModels: [KYCStepViewModel]?

    // MARK: - UI

    private let progressView = StepProgressView()
    private let iconWrapperView = UIView()
    private let iconCircle = UIView()
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let continueButton = UIButton(type: .custom)

    private var pulseLayers: [CAShapeLayer] = []

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupV2UI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startPulseAnimations()
#if canImport(AmaniVoiceAssistantSDK)
        Task { @MainActor in
            try? await AmaniUI.sharedInstance.voiceAssistant?.play(key: "VOICE_SUCCESS")
        }
#endif
    }

    override func popViewController() {
        AmaniUI.sharedInstance.closeAmaniSDK()
        navigationController?.dismiss(animated: true, completion: nil)
    }

    // MARK: - Bind

    func bind(stepModels: [KYCStepViewModel]?) {
        self.stepModels = stepModels
    }

    // MARK: - UI Setup

    private func setupV2UI() {
        let gc = try? Amani.sharedInstance.appConfig().getApplicationConfig().generalconfigs
        let fontColor = hextoUIColor(hexString: gc?.appFontColor ?? "FFFFFF")
        let accentColor = hextoUIColor(hexString: gc?.primaryButtonBackgroundColor ?? "#C0395A")
        let bgColor = hextoUIColor(hexString: gc?.appBackground ?? "FFFFFF")
        view.backgroundColor = bgColor

        // Nav bar — no back button on success, but keep close action consistent
        setNavigationBarWith(title: "")
        navigationItem.leftBarButtonItem = nil
        navigationItem.hidesBackButton = true

        // Progress view
        progressView.translatesAutoresizingMaskIntoConstraints = false
        if let steps = stepModels {
            progressView.configure(steps: steps, accentColor: accentColor)
        }

        // Pulse wrapper (clipsToBounds OFF so rings bleed beyond circle edge)
        iconWrapperView.translatesAutoresizingMaskIntoConstraints = false
        iconWrapperView.clipsToBounds = false

        // Checkmark circle
        let circleSize: CGFloat = 130
        iconCircle.translatesAutoresizingMaskIntoConstraints = false
        iconCircle.backgroundColor = accentColor
        iconCircle.layer.cornerRadius = circleSize / 2
        iconCircle.clipsToBounds = true

        // Checkmark icon
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.image = UIImage(systemName: "checkmark")?.withRenderingMode(.alwaysTemplate)
        iconImageView.tintColor = .white
        iconImageView.contentMode = .scaleAspectFit
        iconCircle.addSubview(iconImageView)
        iconWrapperView.addSubview(iconCircle)

        // Title
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = gc?.successHeaderText ?? "You're all done!"
        titleLabel.font = UIFont.systemFont(ofSize: 26, weight: .bold)
        titleLabel.textColor = fontColor
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0

        // Subtitle
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.text = gc?.successInfo1Text ?? "All steps are complete. We'll review your documents and let you know the result."
        subtitleLabel.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        subtitleLabel.textColor = fontColor.withAlphaComponent(0.55)
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0

        // Continue button
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        continueButton.setTitle(gc?.continueText ?? "Continue", for: .normal)
        continueButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        continueButton.setTitleColor(hextoUIColor(hexString: gc?.primaryButtonTextColor ?? "FFFFFF"), for: .normal)
        continueButton.backgroundColor = accentColor
        continueButton.layer.cornerRadius = AmaniUI.sharedInstance.style.ctaButtonCornerRadius
        continueButton.addTarget(self, action: #selector(continueBtnAction(_:)), for: .touchUpInside)

        view.addSubview(progressView)
        view.addSubview(iconWrapperView)
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(continueButton)

        let ctaHeight = AmaniUI.sharedInstance.style.ctaButtonHeight
        let wrapperSize: CGFloat = 270
        let circleOffset: CGFloat = (wrapperSize - circleSize) / 2

        NSLayoutConstraint.activate([
            // Progress view at top
            progressView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            progressView.heightAnchor.constraint(equalToConstant: 44),

            // Icon wrapper below progress view
            iconWrapperView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            iconWrapperView.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 24),
            iconWrapperView.widthAnchor.constraint(equalToConstant: wrapperSize),
            iconWrapperView.heightAnchor.constraint(equalToConstant: wrapperSize),

            // Checkmark circle centered in wrapper
            iconCircle.centerXAnchor.constraint(equalTo: iconWrapperView.centerXAnchor),
            iconCircle.centerYAnchor.constraint(equalTo: iconWrapperView.centerYAnchor),
            iconCircle.widthAnchor.constraint(equalToConstant: circleSize),
            iconCircle.heightAnchor.constraint(equalToConstant: circleSize),

            // Checkmark icon inside circle
            iconImageView.centerXAnchor.constraint(equalTo: iconCircle.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconCircle.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 56),
            iconImageView.heightAnchor.constraint(equalToConstant: 56),

            // Title below icon
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            titleLabel.topAnchor.constraint(equalTo: iconWrapperView.bottomAnchor, constant: 20),

            // Subtitle below title
            subtitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),

            // Continue button pinned to bottom
            continueButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            continueButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            continueButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            continueButton.heightAnchor.constraint(equalToConstant: ctaHeight),
        ])

        buildPulseLayers(accentColor: accentColor, circleSize: circleSize, wrapperSize: wrapperSize)
    }

    // MARK: - Pulse rings (same logic as NFCV2ViewController)

    private func buildPulseLayers(accentColor: UIColor, circleSize: CGFloat, wrapperSize: CGFloat) {
        pulseLayers.forEach { $0.removeFromSuperlayer() }
        pulseLayers.removeAll()

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
                let pausedTime = layer.timeOffset
                layer.speed = 1.0
                layer.timeOffset = 0.0
                layer.beginTime = 0.0
                let timeSincePause = layer.convertTime(CACurrentMediaTime(), from: nil) - pausedTime
                layer.beginTime = timeSincePause
            }
        }
    }

    // MARK: - Actions (identical to v1)

    @objc func continueBtnAction(_ sender: UIButton) {
        let customer = Amani.sharedInstance.customerInfo().getCustomer()
        guard let customerId: String = customer.id else { return }
        AmaniUI.sharedInstance.delegate?.onKYCSuccess(CustomerId: customerId)
        AmaniUI.sharedInstance.closeAmaniSDK()
        navigationController?.dismiss(animated: true, completion: nil)
    }
}
