import UIKit
import AmaniSDK

final class HomeV2StepCard: UIView {

    // MARK: - Card state

    enum CardState {
        case active, completed, pendingReview, locked, rejected, processing
    }

    // MARK: - Subviews

    private let cardView = UIView()

    private let badgeView = UIView()
    private let badgeNumberLabel = UILabel()
    private let badgeIconView = UIImageView()

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    private let rightIconView = UIImageView()

    private let errorCard = UIView()
    private let errorIconView = UIImageView()
    private let errorTitleLabel = UILabel()
    private let errorMessageLabel = UILabel()

    private var tapAction: (() -> Void)?

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        buildLayout()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        buildLayout()
    }

    // MARK: - Layout

    private func buildLayout() {
        translatesAutoresizingMaskIntoConstraints = false
        addSubview(cardView)
        cardView.translatesAutoresizingMaskIntoConstraints = false

        // Badge
        badgeView.translatesAutoresizingMaskIntoConstraints = false
        badgeView.clipsToBounds = true
        badgeNumberLabel.translatesAutoresizingMaskIntoConstraints = false
        badgeNumberLabel.textAlignment = .center
        badgeNumberLabel.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        badgeNumberLabel.textColor = .white
        badgeIconView.translatesAutoresizingMaskIntoConstraints = false
        badgeIconView.contentMode = .scaleAspectFit
        badgeIconView.tintColor = .white
        badgeView.addSubview(badgeNumberLabel)
        badgeView.addSubview(badgeIconView)

        // Labels
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        titleLabel.numberOfLines = 2

        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)

        let labelStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        labelStack.axis = .vertical
        labelStack.spacing = 2
        labelStack.translatesAutoresizingMaskIntoConstraints = false

        // Right icon
        rightIconView.translatesAutoresizingMaskIntoConstraints = false
        rightIconView.contentMode = .scaleAspectFit

        // Main row
        let rowStack = UIStackView(arrangedSubviews: [badgeView, labelStack, rightIconView])
        rowStack.axis = .horizontal
        rowStack.spacing = 12
        rowStack.alignment = .center
        rowStack.translatesAutoresizingMaskIntoConstraints = false

        // Error sub-card
        errorCard.translatesAutoresizingMaskIntoConstraints = false
        errorCard.layer.cornerRadius = 10

        errorIconView.translatesAutoresizingMaskIntoConstraints = false
        errorIconView.contentMode = .scaleAspectFit

        errorTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        errorTitleLabel.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        errorTitleLabel.numberOfLines = 0

        errorMessageLabel.translatesAutoresizingMaskIntoConstraints = false
        errorMessageLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        errorMessageLabel.numberOfLines = 0

        let errorTextStack = UIStackView(arrangedSubviews: [errorTitleLabel, errorMessageLabel])
        errorTextStack.axis = .vertical
        errorTextStack.spacing = 3
        errorTextStack.translatesAutoresizingMaskIntoConstraints = false

        errorCard.addSubview(errorIconView)
        errorCard.addSubview(errorTextStack)

        // Outer content stack (row + optional error card)
        let contentStack = UIStackView(arrangedSubviews: [rowStack, errorCard])
        contentStack.axis = .vertical
        contentStack.spacing = 10
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            // cardView fills self
            cardView.topAnchor.constraint(equalTo: topAnchor),
            cardView.leadingAnchor.constraint(equalTo: leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: trailingAnchor),
            cardView.bottomAnchor.constraint(equalTo: bottomAnchor),

            // badge fixed size
            badgeView.widthAnchor.constraint(equalToConstant: 40),
            badgeView.heightAnchor.constraint(equalToConstant: 40),

            // badge label / icon centered in badge
            badgeNumberLabel.centerXAnchor.constraint(equalTo: badgeView.centerXAnchor),
            badgeNumberLabel.centerYAnchor.constraint(equalTo: badgeView.centerYAnchor),

            badgeIconView.centerXAnchor.constraint(equalTo: badgeView.centerXAnchor),
            badgeIconView.centerYAnchor.constraint(equalTo: badgeView.centerYAnchor),
            badgeIconView.widthAnchor.constraint(equalToConstant: 20),
            badgeIconView.heightAnchor.constraint(equalToConstant: 20),

            // right icon fixed size
            rightIconView.widthAnchor.constraint(equalToConstant: 22),
            rightIconView.heightAnchor.constraint(equalToConstant: 22),

            // content stack inset from card edges
            contentStack.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 14),
            contentStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 14),
            contentStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -14),
            contentStack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -14),

            // error card inner layout
            errorIconView.leadingAnchor.constraint(equalTo: errorCard.leadingAnchor, constant: 12),
            errorIconView.topAnchor.constraint(equalTo: errorCard.topAnchor, constant: 12),
            errorIconView.widthAnchor.constraint(equalToConstant: 20),
            errorIconView.heightAnchor.constraint(equalToConstant: 20),

            errorTextStack.leadingAnchor.constraint(equalTo: errorIconView.trailingAnchor, constant: 10),
            errorTextStack.topAnchor.constraint(equalTo: errorCard.topAnchor, constant: 12),
            errorTextStack.trailingAnchor.constraint(equalTo: errorCard.trailingAnchor, constant: -12),
            errorTextStack.bottomAnchor.constraint(equalTo: errorCard.bottomAnchor, constant: -12),
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        cardView.addGestureRecognizer(tap)
        cardView.isUserInteractionEnabled = true
    }

    @objc private func handleTap() {
        tapAction?()
    }

    // MARK: - Configure

    func configure(
        step: KYCStepViewModel,
        index: Int,
        accentColor: UIColor,
        hasProgress: Bool,
        onTap: (() -> Void)?
    ) {
        tapAction = onTap
        let style = AmaniUI.sharedInstance.style
        let state = resolveState(for: step)
        let fontColor = hextoUIColor(hexString: AmaniUI.sharedInstance.config?.generalconfigs?.appFontColor ?? "FFFFFF")
        let mutedColor = fontColor.withAlphaComponent(0.45)
        let inactiveSurface = fontColor.withAlphaComponent(0.07)
        let inactiveBorder = fontColor.withAlphaComponent(0.18)
        let inactiveBadge = fontColor.withAlphaComponent(0.12)

        // Per-status color and its on-color text, sourced from stepConfig.buttonColor / buttonTextColor
        // (same source as v1 KYCStepTableViewCell). Falls back to accentColor when unconfigured.
        let statusColor = step.buttonColor
        let statusTextColor = step.textColor

        // Card appearance
        cardView.layer.cornerRadius = style.cardCornerRadius
        cardView.clipsToBounds = true

        switch state {
        case .active, .rejected, .processing:
            cardView.layer.borderWidth = style.cardBorderWidth
            cardView.layer.borderColor = statusColor.cgColor
            cardView.backgroundColor = statusColor.withAlphaComponent(0.07)
        case .completed, .pendingReview:
            cardView.layer.borderWidth = style.cardBorderWidth
            cardView.layer.borderColor = statusColor.cgColor
            cardView.backgroundColor = statusColor.withAlphaComponent(0.07)
        case .locked:
            cardView.layer.borderWidth = 1
            cardView.layer.borderColor = inactiveBorder.cgColor
            cardView.backgroundColor = inactiveSurface
        }

        // Badge
        badgeView.layer.cornerRadius = style.badgeCornerRadius

        switch state {
        case .active, .rejected, .completed, .pendingReview, .processing:
            badgeView.backgroundColor = statusColor
        case .locked:
            badgeView.backgroundColor = inactiveBadge
        }

        switch state {
        case .active, .processing:
            badgeNumberLabel.text = "\(index + 1)"
            badgeNumberLabel.textColor = statusTextColor
            badgeNumberLabel.isHidden = false
            badgeIconView.isHidden = true

        case .locked:
            badgeNumberLabel.text = "\(index + 1)"
            badgeNumberLabel.textColor = mutedColor
            badgeNumberLabel.isHidden = false
            badgeIconView.isHidden = true

        case .completed, .pendingReview:
            badgeNumberLabel.isHidden = true
            badgeIconView.isHidden = false
            badgeIconView.image = UIImage(systemName: "checkmark")?.withRenderingMode(.alwaysTemplate)
            badgeIconView.tintColor = statusTextColor

        case .rejected:
            badgeNumberLabel.isHidden = true
            badgeIconView.isHidden = false
            badgeIconView.image = UIImage(systemName: "xmark")?.withRenderingMode(.alwaysTemplate)
            badgeIconView.tintColor = statusTextColor
        }

        // Title
        switch state {
        case .active, .rejected, .processing:
            titleLabel.text = step.title
            titleLabel.textColor = fontColor
        case .completed, .pendingReview:
            titleLabel.text = step.stepConfig.buttonText?.approved ?? step.title
            titleLabel.textColor = fontColor
        case .locked:
            titleLabel.text = step.title
            titleLabel.textColor = mutedColor
        }

        // Subtitle
        let time = estimatedTime(for: step)
        switch state {
        case .active:
            subtitleLabel.text = hasProgress ? "Up next · \(time)" : "Start here · \(time)"
            subtitleLabel.textColor = mutedColor
        case .completed:
            subtitleLabel.text = "Verified"
            subtitleLabel.textColor = mutedColor
        case .pendingReview:
            subtitleLabel.text = "Under review"
            subtitleLabel.textColor = mutedColor
        case .rejected:
            subtitleLabel.text = "Rejected · Action needed"
            subtitleLabel.textColor = mutedColor
        case .locked:
            subtitleLabel.text = time
            subtitleLabel.textColor = mutedColor
        case .processing:
            subtitleLabel.text = "Processing..."
            subtitleLabel.textColor = mutedColor
        }

        // Right icon
        switch state {
        case .active:
            rightIconView.isHidden = false
            rightIconView.image = UIImage(systemName: "arrow.right")?.withRenderingMode(.alwaysTemplate)
            rightIconView.tintColor = statusColor
        case .rejected:
            rightIconView.isHidden = true
        case .processing:
            rightIconView.isHidden = false
            rightIconView.image = UIImage(systemName: "clock")?.withRenderingMode(.alwaysTemplate)
            rightIconView.tintColor = statusColor
        case .locked:
            rightIconView.isHidden = false
            rightIconView.image = UIImage(systemName: "lock.fill")?.withRenderingMode(.alwaysTemplate)
            rightIconView.tintColor = fontColor.withAlphaComponent(0.3)
        case .completed, .pendingReview:
            rightIconView.isHidden = true
        }

        // Error sub-card
        if state == .rejected {
            errorCard.isHidden = false
            errorCard.backgroundColor = hextoUIColor(hexString: AmaniUI.sharedInstance.config?.generalconfigs?.appBackground ?? "FFFFFF")
            errorCard.layer.borderWidth = 1
            errorCard.layer.borderColor = statusColor.withAlphaComponent(0.25).cgColor

            errorIconView.image = UIImage(systemName: "exclamationmark.circle")?.withRenderingMode(.alwaysTemplate)
            errorIconView.tintColor = fontColor

            errorTitleLabel.text = "Verification could not be completed"
            errorTitleLabel.textColor = fontColor

            errorMessageLabel.text = "Please retake your document in good lighting and make sure all details are clearly visible."
            errorMessageLabel.textColor = fontColor.withAlphaComponent(0.6)
        } else {
            errorCard.isHidden = true
        }
    }

    // MARK: - Helpers

    private func resolveState(for step: KYCStepViewModel) -> CardState {
        switch step.status {
        case .APPROVED:             return .completed
        case .PENDING_REVIEW:       return .pendingReview
        case .PROCESSING:           return .processing
        case .REJECTED,
             .AUTOMATICALLY_REJECTED: return .rejected
        case .NOT_UPLOADED:
            return step.isEnabled() ? .active : .locked
        @unknown default:
            return step.isEnabled() ? .active : .locked
        }
    }

    private func estimatedTime(for step: KYCStepViewModel) -> String {
        let ids = Set(step.documents.compactMap { $0.id })
        if ids.contains("NF") { return "~2 min" }
        if ids.contains("IB") { return "~1 min" }
        if ids.contains("SE") { return "~30 sec" }
        if ids.contains("ID") || ids.contains("DL") || ids.contains("PA") || ids.contains("VA") { return "~30 sec" }
        return "~1 min"
    }
}
