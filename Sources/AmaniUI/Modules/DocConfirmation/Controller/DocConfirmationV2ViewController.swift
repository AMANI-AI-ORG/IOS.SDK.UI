import UIKit
import AmaniSDK

class DocConfirmationV2ViewController: BaseViewController {

    // MARK: - Business logic properties (mirrored from v1)

    private var image: UIImage?
    private var confirmCallback: (() -> Void)?
    private var documentID: DocumentID?
    private var documentVersion: DocumentVersion?
    private var documentStep: DocumentStepModel?
    private var mrzDocumentId: String?
    private var confirmClicked: Bool = false
    private var stepid: Int = 0
    let child = AnimationViewDocConfirmation()

    private var isLastStepOfDocument: Bool {
        guard let totalStep = documentVersion?.steps?.count, totalStep > 0 else { return false }
        return stepid >= totalStep - 1
    }

    // MARK: - V2 UI

    private let scrollView = UIScrollView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let imageView = UIImageView()
    private let qualityCard = UIView()
    private let retakeButton = UIButton(type: .custom)
    private let confirmButton = UIButton(type: .custom)

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        if !AmaniUI.sharedInstance.isEnabledClientSideMrz {
            Amani.sharedInstance.setMRZDelegate(delegate: self)
        }
        setupV2UI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        confirmClicked = false
    }

    // MARK: - Bind

    func bind(image: UIImage, documentID: DocumentID, docVer: DocumentVersion, docStep: DocumentStepModel, stepid: Int, callback: @escaping () -> Void) {
        self.image = image
        self.documentID = documentID
        self.documentVersion = docVer
        self.documentStep = docStep
        self.stepid = stepid
        self.confirmCallback = callback
        self.confirmClicked = false
    }

    // MARK: - UI Setup

    private func setupV2UI() {
        let appConfig = try? Amani.sharedInstance.appConfig().getApplicationConfig()
        let gc = appConfig?.generalconfigs
        let fontColor = hextoUIColor(hexString: gc?.appFontColor ?? "FFFFFF")
        let accentColor = hextoUIColor(hexString: gc?.primaryButtonBackgroundColor ?? "#C0395A")
        let bgColor = hextoUIColor(hexString: gc?.appBackground ?? "FFFFFF")
        view.backgroundColor = bgColor

        // Navigation bar
        setNavigationBarWith(title: gc?.v2DocumentConfirmationNavTitle ?? "Review capture")
        let backButton = makeNavButton(
            icon: UIImage(systemName: "arrow.left"),
            tintColor: hextoUIColor(hexString: gc?.topBarFontColor ?? "1A1A2E")
        )
        backButton.addTarget(self, action: #selector(tryAgainAction(_:)), for: .touchUpInside)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backButton)

        // Title
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = gc?.v2DocumentConfirmationHeader ?? "Looks good?"
        titleLabel.font = UIFont.systemFont(ofSize: 26, weight: .bold)
        titleLabel.textColor = fontColor
        titleLabel.numberOfLines = 0

        // Subtitle
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.text = gc?.v2DocumentConfirmationSubtitle ?? "Make sure the document is sharp and fully visible."
        subtitleLabel.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        subtitleLabel.textColor = fontColor.withAlphaComponent(0.55)
        subtitleLabel.numberOfLines = 0

        // Image view
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = image
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 16
        imageView.backgroundColor = UIColor.black.withAlphaComponent(0.85)

        // Quality checks card
        buildQualityCard(fontColor: fontColor, accentColor: accentColor, gc: gc)

        // Content stack
        let contentStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel, imageView, qualityCard])
        contentStack.axis = .vertical
        contentStack.spacing = 0
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.setCustomSpacing(6, after: titleLabel)
        contentStack.setCustomSpacing(20, after: subtitleLabel)
        contentStack.setCustomSpacing(16, after: imageView)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.addSubview(contentStack)

        // Retake button (outlined)
        retakeButton.translatesAutoresizingMaskIntoConstraints = false
        retakeButton.setTitle(gc?.tryAgainText ?? "Retake", for: .normal)
        retakeButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        retakeButton.setTitleColor(fontColor, for: .normal)
        retakeButton.backgroundColor = .clear
        retakeButton.layer.cornerRadius = AmaniUI.sharedInstance.style.ctaButtonCornerRadius
        retakeButton.layer.borderWidth = 1.5
        retakeButton.layer.borderColor = fontColor.withAlphaComponent(0.25).cgColor
        let retakeIcon = UIImage(systemName: "arrow.counterclockwise")?.withRenderingMode(.alwaysTemplate)
        retakeButton.setImage(retakeIcon, for: .normal)
        retakeButton.tintColor = fontColor
        retakeButton.semanticContentAttribute = .forceLeftToRight
        retakeButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 6)
        retakeButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 6, bottom: 0, right: 0)
        retakeButton.addTarget(self, action: #selector(tryAgainAction(_:)), for: .touchUpInside)

        // Confirm button (filled)
        confirmButton.translatesAutoresizingMaskIntoConstraints = false
        confirmButton.setTitle(gc?.confirmText ?? "Use this photo", for: .normal)
        confirmButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        confirmButton.setTitleColor(hextoUIColor(hexString: gc?.primaryButtonTextColor ?? "FFFFFF"), for: .normal)
        confirmButton.backgroundColor = accentColor
        confirmButton.layer.cornerRadius = AmaniUI.sharedInstance.style.ctaButtonCornerRadius
        confirmButton.addTarget(self, action: #selector(confirmAction(_:)), for: .touchUpInside)

        view.addSubview(scrollView)
        view.addSubview(retakeButton)
        view.addSubview(confirmButton)

        let ctaHeight = AmaniUI.sharedInstance.style.ctaButtonHeight

        NSLayoutConstraint.activate([
            // Retake button: 50% width, left
            retakeButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            retakeButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            retakeButton.heightAnchor.constraint(equalToConstant: ctaHeight),

            // Confirm button: 50% width, right
            confirmButton.leadingAnchor.constraint(equalTo: retakeButton.trailingAnchor, constant: 10),
            confirmButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            confirmButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            confirmButton.heightAnchor.constraint(equalToConstant: ctaHeight),
            confirmButton.widthAnchor.constraint(equalTo: retakeButton.widthAnchor),

            // Scroll view
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: retakeButton.topAnchor, constant: -12),

            // Content stack
            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40),

            // Image: 3:2 aspect ratio (landscape — fits ID cards)
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 0.65),
        ])
    }

    // MARK: - Quality card

    private func buildQualityCard(fontColor: UIColor, accentColor: UIColor, gc: GeneralConfig?) {
        qualityCard.translatesAutoresizingMaskIntoConstraints = false
        qualityCard.backgroundColor = fontColor.withAlphaComponent(0.05)
        qualityCard.layer.cornerRadius = AmaniUI.sharedInstance.style.cardCornerRadius
        qualityCard.layer.borderWidth = 1
        qualityCard.layer.borderColor = fontColor.withAlphaComponent(0.1).cgColor

        let headerLabel = UILabel()
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        headerLabel.text = gc?.v2DocumentQualityHeader ?? "QUALITY CHECKS"
        headerLabel.font = UIFont.systemFont(ofSize: 11, weight: .semibold)
        headerLabel.textColor = fontColor.withAlphaComponent(0.45)

        let checks = [
            gc?.v2DocumentQuality1 ?? "Sharp & in focus",
            gc?.v2DocumentQuality2 ?? "Document fully visible",
            gc?.v2DocumentQuality3 ?? "No glare or shadows",
        ]

        let rowsStack = UIStackView(arrangedSubviews: checks.map { makeQualityRow(text: $0, fontColor: fontColor, accentColor: accentColor) })
        rowsStack.axis = .vertical
        rowsStack.spacing = 14
        rowsStack.translatesAutoresizingMaskIntoConstraints = false

        qualityCard.addSubview(headerLabel)
        qualityCard.addSubview(rowsStack)

        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: qualityCard.topAnchor, constant: 16),
            headerLabel.leadingAnchor.constraint(equalTo: qualityCard.leadingAnchor, constant: 16),
            headerLabel.trailingAnchor.constraint(equalTo: qualityCard.trailingAnchor, constant: -16),

            rowsStack.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 14),
            rowsStack.leadingAnchor.constraint(equalTo: qualityCard.leadingAnchor, constant: 16),
            rowsStack.trailingAnchor.constraint(equalTo: qualityCard.trailingAnchor, constant: -16),
            rowsStack.bottomAnchor.constraint(equalTo: qualityCard.bottomAnchor, constant: -16),
        ])
    }

    private func makeQualityRow(text: String, fontColor: UIColor, accentColor: UIColor) -> UIView {
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
        button.backgroundColor = tintColor.withAlphaComponent(0.12)
        button.layer.cornerRadius = AmaniUI.sharedInstance.style.navButtonCornerRadius
        button.frame = CGRect(x: 0, y: 0, width: size, height: size)
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: size),
            button.heightAnchor.constraint(equalToConstant: size),
        ])
        return button
    }

    // MARK: - Actions

    @objc func tryAgainAction(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }

    @objc func confirmAction(_ sender: Any) {
        guard !confirmClicked else { return }
        confirmClicked = true
        if documentVersion?.nfc ?? false {
            if isLastStepOfDocument {
                checkMRZ()
            } else {
                confirmCallback?()
            }
        } else {
            confirmCallback?()
        }
    }

    func checkMRZ() {
        if !AmaniUI.sharedInstance.isEnabledClientSideMrz {
            createAnimationView()
            Amani.sharedInstance.IdCapture().getMrz { mrzDocumentId in
                self.mrzDocumentId = mrzDocumentId
            }
        }
    }

    func createAnimationView() {
        DispatchQueue.main.async {
            self.view.addSubview(self.child)
            self.child.frame = self.view.frame
            self.view.bringSubviewToFront(self.child)
            self.child.bind(config: self.documentVersion!)
        }
    }

    func dismissAnimationView() {
        DispatchQueue.main.async {
            self.child.removeFromSuperview()
        }
    }
}

// MARK: - MRZ delegate (identical logic to v1)

extension DocConfirmationV2ViewController: mrzInfoDelegate {
    func mrzInfo(_ mrz: AmaniSDK.MrzModel?, documentId: String?) {
        if let mrzData = mrz {
            var isReady = false
            switch AmaniUI.sharedInstance.apiVersion {
            case .v1:
                isReady = true
            case .v2:
                isReady = AmaniUI.sharedInstance.isEnabledClientSideMrz ? true : (self.mrzDocumentId == documentId)
            default:
                break
            }
            if isReady {
                AmaniUI.sharedInstance.nviData = NviModel(mrzModel: mrzData)
                if !AmaniUI.sharedInstance.isEnabledClientSideMrz {
                    dismissAnimationView()
                }
                confirmCallback?()
            }
        } else {
            DispatchQueue.main.async {
                let appConfig = try? Amani.sharedInstance.appConfig().getApplicationConfig()
                let actions: [(String, UIAlertAction.Style)] = [
                    (appConfig?.generalconfigs?.okText ?? "Re-try", .default)
                ]
                AlertDialogueUtility.shared.showAlertWithActions(
                    vc: self,
                    title: appConfig?.generalconfigs?.tryAgainText,
                    message: self.documentVersion?.mrzReadErrorText,
                    actions: actions
                ) { _ in
                    self.dismissAnimationView()
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }
    }
}
