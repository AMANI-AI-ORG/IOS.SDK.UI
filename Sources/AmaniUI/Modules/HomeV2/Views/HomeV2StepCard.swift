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

    private let contentStack = UIStackView()

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
        contentStack.axis = .vertical
        contentStack.spacing = 10
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.addArrangedSubview(rowStack)
        contentStack.addArrangedSubview(errorCard)
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
        let gc = AmaniUI.sharedInstance.config?.generalconfigs
        let fontColor = hextoUIColor(hexString: gc?.appFontColor ?? "FFFFFF")
        let mutedColor = fontColor.withAlphaComponent(0.45)
        let inactiveSurface = fontColor.withAlphaComponent(0.07)
        let inactiveBorder = fontColor.withAlphaComponent(0.18)
        let inactiveBadge = fontColor.withAlphaComponent(0.12)

        // Active cards always use the brand accent (primaryButtonBackgroundColor).
        // Terminal-state cards (approved/rejected/pending/processing) use the per-step
        // config color from stepConfig.buttonColor, which matches v1 behavior.
        let statusColor: UIColor
        let statusTextColor: UIColor
        switch state {
        case .active:
            statusColor = accentColor
            statusTextColor = .white
        case .completed, .pendingReview, .rejected, .processing:
            statusColor = step.buttonColor
            statusTextColor = step.textColor
        case .locked:
            statusColor = inactiveBadge   // not used for card/badge coloring
            statusTextColor = mutedColor
        }

        // Card appearance
        cardView.layer.cornerRadius = style.cardCornerRadius
        cardView.clipsToBounds = true

        switch state {
        case .active:
            cardView.layer.borderWidth = style.cardBorderWidth
            cardView.layer.borderColor = accentColor.cgColor
            cardView.backgroundColor = step.buttonColor.withAlphaComponent(0.07)
        case .rejected:
            cardView.layer.borderWidth = style.cardBorderWidth
            cardView.layer.borderColor = accentColor.cgColor
            cardView.backgroundColor = statusColor.withAlphaComponent(0.07)
        case .processing:
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

        // Title — always the step name so subtitle status labels don't duplicate it
        switch state {
        case .active, .rejected, .processing, .completed, .pendingReview:
            titleLabel.text = step.title
            titleLabel.textColor = fontColor
        case .locked:
            titleLabel.text = step.title
            titleLabel.textColor = mutedColor
        }

        // Subtitle — reuse existing buttonText config keys for terminal states
        let time = estimatedTime(for: step)
        switch state {
        case .active:
            let startLabel = gc?.v2StepStartHereLabel ?? "Start here"
            let upNextLabel = gc?.v2StepUpNextLabel ?? "Up next"
            subtitleLabel.text = hasProgress ? "\(upNextLabel) · \(time)" : "\(startLabel) · \(time)"
            subtitleLabel.textColor = mutedColor
        case .completed:
            subtitleLabel.text = gc?.v2ApprovedBadgeText ?? step.stepConfig.buttonText?.approved ?? "Verified"
            subtitleLabel.textColor = mutedColor
        case .pendingReview:
            subtitleLabel.text = step.stepConfig.buttonText?.pendingReview ?? "Under review"
            subtitleLabel.textColor = mutedColor
        case .rejected:
            let isProfileInfoStep = step.documents.contains { $0.id == "IB" }
            if isProfileInfoStep, let rejectedText = gc?.v2StepRejectedText {
                subtitleLabel.text = rejectedText
            } else {
                subtitleLabel.text = step.stepConfig.buttonText?.rejected ?? "Rejected · Action needed"
            }
            subtitleLabel.textColor = mutedColor
        case .locked:
            subtitleLabel.text = time
            subtitleLabel.textColor = mutedColor
        case .processing:
            subtitleLabel.text = step.stepConfig.buttonText?.processing ?? "Processing..."
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

        // Dim content for rejected — border (on cardView.layer) stays full opacity
        contentStack.alpha = (state == .rejected) ? 0.75 : 1.0

        // Error sub-card
        if state == .rejected {
            errorCard.isHidden = false
            errorCard.backgroundColor = hextoUIColor(hexString: gc?.appBackground ?? "FFFFFF")
            errorCard.layer.borderWidth = 1
            errorCard.layer.borderColor = statusColor.withAlphaComponent(0.25).cgColor

            errorIconView.image = UIImage(systemName: "exclamationmark.circle")?.withRenderingMode(.alwaysTemplate)
            errorIconView.tintColor = fontColor

            let firstVersion = step.documents.first?.versions?.first
            errorTitleLabel.text = firstVersion?.v2StepRejectionTitle ?? gc?.v2StepRejectionTitle ?? gc?.v2StepRejectionFallbackTitle ?? "Verification could not be completed"
            errorTitleLabel.textColor = fontColor

            errorMessageLabel.text = firstVersion?.v2StepRejectionDescription ?? gc?.v2StepRejectionDescription ?? gc?.v2StepRejectionFallbackDescription ?? "Your submission could not be accepted. Please try again to continue."
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
        let gc = AmaniUI.sharedInstance.config?.generalconfigs
        if let configured = step.documents.first?.versions?.first?.v2EstimatedTime { return configured }
        if let configured = gc?.v2EstimatedTime { return configured }
        return gc?.v2StepDefaultDuration ?? "~30 sec"
    }
}
