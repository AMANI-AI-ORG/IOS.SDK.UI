import UIKit
import AmaniSDK

@available(iOS 13, *)
class NFCConfigureV2View: UIView {

    // MARK: - Business logic (mirrored from NFCConfigureView, logic unchanged)

    var setButtonCb: ((NviModel) async -> Void)?
    weak var delegate: AlertDelegate?
    private var newNviData: NviModel?

    private lazy var numericDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "ddMMyyyy"
        return formatter
    }()

    var appConfig: AppConfigModel? {
        didSet {
            guard appConfig != nil else { return }
            setupV2UI()
        }
    }

    // MARK: - V2 UI

    private let scrollView = UIScrollView()
    private let documentNoField = UITextField()
    private let birthdateField = UITextField()
    private let expiryField = UITextField()
    private let submitButton = UIButton(type: .custom)
    private var submitButtonBottomConstraint: NSLayoutConstraint!
    private weak var activeField: UITextField?

    private lazy var dismissKeyboardGesture: UITapGestureRecognizer = {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(handleBackgroundTap))
        gesture.cancelsTouchesInView = false
        gesture.delegate = self
        return gesture
    }()

    // MARK: - Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)
        registerForKeyboardNotifications()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        registerForKeyboardNotifications()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        endEditing(true)
    }

    @objc private func handleBackgroundTap() {
        endEditing(true)
    }

    // MARK: - Bind (mirrored from NFCConfigureView)

    func setTextsFrom(nvi: NviModel?) {
        DispatchQueue.main.async {
            self.documentNoField.text = nvi?.documentNo ?? ""

            if let dateOfBirth = nvi?.dateOfBirth,
               let birthDate = self.dateFormatter(dateString: dateOfBirth) {
                self.birthdateField.text = self.insertDateSlashes(self.numericDateFormatter.string(from: birthDate))
            }

            if let dateOfExpire = nvi?.dateOfExpire,
               let expiryDate = self.dateFormatter(dateString: dateOfExpire) {
                self.expiryField.text = self.insertDateSlashes(self.numericDateFormatter.string(from: expiryDate))
            }
        }
    }

    func triggerAlert() {
        delegate?.showAlert(
            title: "Caution!",
            message: "The dates are not valid. Please set correct dates format",
            actions: [("Ok", .default)]
        ) { _ in }
    }

    private func dateFormatter(dateString: String?) -> Date? {
        guard let dateString = dateString, isValidDateFormat(dateString) else {
            print("Invalid date format: \(dateString ?? "nil")")
            self.triggerAlert()
            return nil
        }

        let formats = ["yyMMdd", "yyyyMMdd"]
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")

        for format in formats {
            dateFormatter.dateFormat = format
            if let date = dateFormatter.date(from: dateString) {
                return date
            }
        }
        self.triggerAlert()
        return nil
    }

    private func isValidDateFormat(_ dateString: String) -> Bool {
        let validLengths = [6, 8]
        return validLengths.contains(dateString.count) && dateString.range(of: "^[0-9]+$", options: .regularExpression) != nil
    }

    // MARK: - Keyboard avoidance

    private func registerForKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let endFrameValue = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }

        let endFrame = convert(endFrameValue.cgRectValue, from: nil)
        let overlap = max(0, bounds.maxY - endFrame.minY)
        let keyboardHeightAboveSafeArea = max(0, overlap - safeAreaInsets.bottom)
        submitButtonBottomConstraint.constant = -(keyboardHeightAboveSafeArea + 16)

        animateKeyboardTransition(userInfo: userInfo) {
            if let activeField = self.activeField {
                let fieldRect = activeField.convert(activeField.bounds, to: self.scrollView)
                self.scrollView.scrollRectToVisible(fieldRect.insetBy(dx: 0, dy: -24), animated: false)
            }
        }
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        submitButtonBottomConstraint.constant = -16
        animateKeyboardTransition(userInfo: userInfo)
    }

    private func animateKeyboardTransition(userInfo: [AnyHashable: Any], completion: (() -> Void)? = nil) {
        let duration = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double) ?? 0.25
        let curveRaw = (userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt) ?? UInt(UIView.AnimationCurve.easeInOut.rawValue)
        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: UIView.AnimationOptions(rawValue: curveRaw << 16),
            animations: {
                self.layoutIfNeeded()
            },
            completion: { _ in completion?() }
        )
    }

    // MARK: - Date input helpers (typed "DD/MM/YYYY" instead of a date-picker wheel)

    private func insertDateSlashes(_ digits: String) -> String {
        var result = ""
        for (index, character) in digits.enumerated() {
            if index == 2 || index == 4 {
                result += "/"
            }
            result.append(character)
        }
        return result
    }

    private func parseTypedDate(from text: String?) -> Date? {
        guard let text = text else { return nil }
        let digits = text.filter(\.isNumber)
        guard digits.count == 8 else { return nil }
        return numericDateFormatter.date(from: digits)
    }

    // MARK: - Submit (mirrored from NFCConfigureView.tapSubmitButton — same NviModel/setButtonCb contract)

    @objc private func tapSubmitButton(_ sender: UIButton) {
        guard let docNo = documentNoField.text else { return }

        guard let birthDateValue = parseTypedDate(from: birthdateField.text),
              let expiryDateValue = parseTypedDate(from: expiryField.text) else {
            triggerAlert()
            return
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyMMdd"
        let birthDate = dateFormatter.string(from: birthDateValue)
        let expiryDate = dateFormatter.string(from: expiryDateValue)

        self.newNviData = NviModel(documentNo: docNo, dateOfBirth: birthDate, dateOfExpire: expiryDate)

        Task {
            if let nviData = self.newNviData {
                guard let setButtonCb = self.setButtonCb else { return }
                await setButtonCb(nviData)
            }
        }
    }

    // MARK: - UI Setup

    private func setupV2UI() {
        let gc = appConfig?.generalconfigs
        let fontColor = hextoUIColor(hexString: gc?.appFontColor ?? "20202F")
        let accentColor = hextoUIColor(hexString: gc?.primaryButtonBackgroundColor ?? "#C0395A")
        let bgColor = hextoUIColor(hexString: gc?.appBackground ?? "FFFFFF")
        backgroundColor = bgColor

        // Badge pill
        let badgeWrapper = buildBadgePill(accentColor: accentColor)

        // Headline
        let headlineLabel = UILabel()
        headlineLabel.translatesAutoresizingMaskIntoConstraints = false
        headlineLabel.text = "Check your details"
        headlineLabel.font = UIFont.systemFont(ofSize: 26, weight: .bold)
        headlineLabel.textColor = fontColor
        headlineLabel.numberOfLines = 0

        // Description
        let descriptionLabel = UILabel()
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.text = "This was read securely from your ID's chip. Confirm it matches your document."
        descriptionLabel.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        descriptionLabel.textColor = fontColor.withAlphaComponent(0.55)
        descriptionLabel.numberOfLines = 0

        // Detail rows
        documentNoField.keyboardType = .default
        birthdateField.keyboardType = .numberPad
        expiryField.keyboardType = .numberPad
        birthdateField.attributedPlaceholder = NSAttributedString(string: "DD/MM/YYYY", attributes: [.foregroundColor: fontColor.withAlphaComponent(0.3)])
        expiryField.attributedPlaceholder = NSAttributedString(string: "DD/MM/YYYY", attributes: [.foregroundColor: fontColor.withAlphaComponent(0.3)])

        let documentRow = makeDetailRow(icon: "creditcard.fill", label: "Document number", field: documentNoField, fontColor: fontColor, accentColor: accentColor)
        let birthdateRow = makeDetailRow(icon: UIImage(systemName: "birthday.cake.fill") != nil ? "birthday.cake.fill" : "calendar", label: "Date of birth", field: birthdateField, fontColor: fontColor, accentColor: accentColor)
        let expiryRow = makeDetailRow(icon: "calendar", label: "Date of expiry", field: expiryField, fontColor: fontColor, accentColor: accentColor)

        let rowsStack = UIStackView(arrangedSubviews: [documentRow, birthdateRow, expiryRow])
        rowsStack.axis = .vertical
        rowsStack.spacing = 12
        rowsStack.translatesAutoresizingMaskIntoConstraints = false

        // Info banner
        let infoBanner = buildInfoBanner(fontColor: fontColor)

        // Content stack
        let contentStack = UIStackView(arrangedSubviews: [badgeWrapper, headlineLabel, descriptionLabel, rowsStack, infoBanner])
        contentStack.axis = .vertical
        contentStack.spacing = 0
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.setCustomSpacing(20, after: badgeWrapper)
        contentStack.setCustomSpacing(6, after: headlineLabel)
        contentStack.setCustomSpacing(24, after: descriptionLabel)
        contentStack.setCustomSpacing(16, after: rowsStack)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.addSubview(contentStack)

        // Submit button
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        submitButton.setTitle(gc?.confirmText ?? "Looks correct", for: .normal)
        submitButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        submitButton.setTitleColor(hextoUIColor(hexString: gc?.primaryButtonTextColor ?? "FFFFFF"), for: .normal)
        submitButton.backgroundColor = accentColor
        submitButton.layer.cornerRadius = AmaniUI.sharedInstance.style.ctaButtonCornerRadius
        submitButton.addTarget(self, action: #selector(tapSubmitButton(_:)), for: .touchUpInside)

        addSubview(scrollView)
        addSubview(submitButton)
        addGestureRecognizer(dismissKeyboardGesture)

        let ctaHeight = AmaniUI.sharedInstance.style.ctaButtonHeight
        submitButtonBottomConstraint = submitButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -16)

        NSLayoutConstraint.activate([
            submitButton.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 20),
            submitButton.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -20),
            submitButtonBottomConstraint,
            submitButton.heightAnchor.constraint(equalToConstant: ctaHeight),

            scrollView.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: submitButton.topAnchor, constant: -12),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 12),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40),
        ])
    }

    // MARK: - Badge pill

    private func buildBadgePill(accentColor: UIColor) -> UIView {
        let wrapper = UIView()
        wrapper.translatesAutoresizingMaskIntoConstraints = false

        let pill = UIView()
        pill.translatesAutoresizingMaskIntoConstraints = false
        pill.backgroundColor = accentColor.withAlphaComponent(0.12)
        pill.layer.cornerRadius = 14

        let icon = UIImageView()
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.image = UIImage(systemName: "wave.3.right")?.withRenderingMode(.alwaysTemplate)
        icon.tintColor = accentColor
        icon.contentMode = .scaleAspectFit

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "READ FROM CHIP"
        label.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        label.textColor = accentColor

        let stack = UIStackView(arrangedSubviews: [icon, label])
        stack.axis = .horizontal
        stack.spacing = 6
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.isUserInteractionEnabled = false

        pill.addSubview(stack)
        wrapper.addSubview(pill)

        NSLayoutConstraint.activate([
            icon.widthAnchor.constraint(equalToConstant: 14),
            icon.heightAnchor.constraint(equalToConstant: 14),

            stack.topAnchor.constraint(equalTo: pill.topAnchor, constant: 7),
            stack.bottomAnchor.constraint(equalTo: pill.bottomAnchor, constant: -7),
            stack.leadingAnchor.constraint(equalTo: pill.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: pill.trailingAnchor, constant: -12),

            pill.topAnchor.constraint(equalTo: wrapper.topAnchor),
            pill.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor),
            pill.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor),
        ])

        return wrapper
    }

    // MARK: - Detail row (icon + label + editable value + checkmark)

    private func makeDetailRow(icon: String, label: String, field: UITextField, fontColor: UIColor, accentColor: UIColor) -> UIView {
        let iconContainer = UIView()
        iconContainer.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.backgroundColor = accentColor.withAlphaComponent(0.12)
        iconContainer.layer.cornerRadius = 12

        let iconView = UIImageView()
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.image = UIImage(systemName: icon)?.withRenderingMode(.alwaysTemplate)
        iconView.tintColor = accentColor
        iconView.contentMode = .scaleAspectFit
        iconContainer.addSubview(iconView)

        let labelLabel = UILabel()
        labelLabel.translatesAutoresizingMaskIntoConstraints = false
        labelLabel.text = label.uppercased()
        labelLabel.font = UIFont.systemFont(ofSize: 11, weight: .semibold)
        labelLabel.textColor = fontColor.withAlphaComponent(0.45)

        field.translatesAutoresizingMaskIntoConstraints = false
        field.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        field.textColor = fontColor
        field.borderStyle = .none
        field.backgroundColor = .clear
        field.returnKeyType = .done
        field.delegate = self

        let textStack = UIStackView(arrangedSubviews: [labelLabel, field])
        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.translatesAutoresizingMaskIntoConstraints = false

        let checkContainer = UIView()
        checkContainer.translatesAutoresizingMaskIntoConstraints = false
        checkContainer.backgroundColor = accentColor.withAlphaComponent(0.12)
        checkContainer.layer.cornerRadius = 16

        let checkIcon = UIImageView()
        checkIcon.translatesAutoresizingMaskIntoConstraints = false
        checkIcon.image = UIImage(systemName: "checkmark")?.withRenderingMode(.alwaysTemplate)
        checkIcon.tintColor = accentColor
        checkIcon.contentMode = .scaleAspectFit
        checkContainer.addSubview(checkIcon)

        let row = UIView()
        row.translatesAutoresizingMaskIntoConstraints = false
        row.backgroundColor = fontColor.withAlphaComponent(0.03)
        row.layer.cornerRadius = AmaniUI.sharedInstance.style.cardCornerRadius
        row.layer.borderWidth = 1
        row.layer.borderColor = fontColor.withAlphaComponent(0.08).cgColor

        row.addSubview(iconContainer)
        row.addSubview(textStack)
        row.addSubview(checkContainer)

        NSLayoutConstraint.activate([
            row.heightAnchor.constraint(equalToConstant: 72),

            iconContainer.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 14),
            iconContainer.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            iconContainer.widthAnchor.constraint(equalToConstant: 44),
            iconContainer.heightAnchor.constraint(equalToConstant: 44),

            iconView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 20),
            iconView.heightAnchor.constraint(equalToConstant: 20),

            textStack.leadingAnchor.constraint(equalTo: iconContainer.trailingAnchor, constant: 12),
            textStack.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            textStack.trailingAnchor.constraint(lessThanOrEqualTo: checkContainer.leadingAnchor, constant: -8),

            checkContainer.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -14),
            checkContainer.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            checkContainer.widthAnchor.constraint(equalToConstant: 32),
            checkContainer.heightAnchor.constraint(equalToConstant: 32),

            checkIcon.centerXAnchor.constraint(equalTo: checkContainer.centerXAnchor),
            checkIcon.centerYAnchor.constraint(equalTo: checkContainer.centerYAnchor),
            checkIcon.widthAnchor.constraint(equalToConstant: 14),
            checkIcon.heightAnchor.constraint(equalToConstant: 14),
        ])

        return row
    }

    // MARK: - Info banner

    private func buildInfoBanner(fontColor: UIColor) -> UIView {
        let banner = UIView()
        banner.translatesAutoresizingMaskIntoConstraints = false
        banner.backgroundColor = fontColor.withAlphaComponent(0.06)
        banner.layer.cornerRadius = AmaniUI.sharedInstance.style.cardCornerRadius

        let icon = UIImageView()
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.image = UIImage(systemName: "lock.fill")?.withRenderingMode(.alwaysTemplate)
        icon.tintColor = fontColor.withAlphaComponent(0.6)
        icon.contentMode = .scaleAspectFit

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "These values were read from your ID. Tap any field to correct it if something looks wrong."
        label.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        label.textColor = fontColor.withAlphaComponent(0.6)
        label.numberOfLines = 0

        banner.addSubview(icon)
        banner.addSubview(label)

        NSLayoutConstraint.activate([
            icon.topAnchor.constraint(equalTo: banner.topAnchor, constant: 14),
            icon.leadingAnchor.constraint(equalTo: banner.leadingAnchor, constant: 14),
            icon.widthAnchor.constraint(equalToConstant: 16),
            icon.heightAnchor.constraint(equalToConstant: 16),

            label.topAnchor.constraint(equalTo: banner.topAnchor, constant: 14),
            label.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 10),
            label.trailingAnchor.constraint(equalTo: banner.trailingAnchor, constant: -14),
            label.bottomAnchor.constraint(equalTo: banner.bottomAnchor, constant: -14),
        ])

        return banner
    }
}

// MARK: - UITextFieldDelegate

@available(iOS 13, *)
extension NFCConfigureV2View: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        activeField = textField
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard textField === birthdateField || textField === expiryField else { return true }

        let current = (textField.text ?? "") as NSString
        let updated = current.replacingCharacters(in: range, with: string)
        let digits = String(updated.filter(\.isNumber).prefix(8))
        textField.text = insertDateSlashes(digits)
        return false
    }
}

// MARK: - UIGestureRecognizerDelegate

@available(iOS 13, *)
extension NFCConfigureV2View: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        !(touch.view is UITextField)
    }
}
