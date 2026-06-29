import UIKit
import AmaniSDK

final class DocumentOptionCard: UIView {

    // MARK: - Subviews

    private let cardView = UIView()

    private let iconContainer = UIView()
    private let iconImageView = UIImageView()

    private let titleLabel = UILabel()

    private let chevronIcon = UIImageView()

    private let checkmarkContainer = UIView()
    private let checkmarkIcon = UIImageView()

    private let chipsRow = UIStackView()

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
        cardView.clipsToBounds = true

        // Icon container
        iconContainer.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.clipsToBounds = true
        iconContainer.layer.cornerRadius = 10
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.contentMode = .scaleAspectFit
        iconContainer.addSubview(iconImageView)

        // Title
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        titleLabel.numberOfLines = 2

        // Chevron (not selected)
        chevronIcon.translatesAutoresizingMaskIntoConstraints = false
        chevronIcon.contentMode = .scaleAspectFit
        chevronIcon.image = UIImage(systemName: "chevron.right")?.withRenderingMode(.alwaysTemplate)

        // Checkmark circle (selected)
        checkmarkContainer.translatesAutoresizingMaskIntoConstraints = false
        checkmarkContainer.clipsToBounds = true
        checkmarkContainer.layer.cornerRadius = 12
        checkmarkIcon.translatesAutoresizingMaskIntoConstraints = false
        checkmarkIcon.contentMode = .scaleAspectFit
        checkmarkIcon.tintColor = .white
        checkmarkIcon.image = UIImage(systemName: "checkmark")?.withRenderingMode(.alwaysTemplate)
        checkmarkContainer.addSubview(checkmarkIcon)

        // Top row: icon | title | chevron OR checkmark
        let topRow = UIStackView(arrangedSubviews: [iconContainer, titleLabel, chevronIcon, checkmarkContainer])
        topRow.axis = .horizontal
        topRow.spacing = 12
        topRow.alignment = .center
        topRow.translatesAutoresizingMaskIntoConstraints = false

        // Chips row (shown when selected)
        chipsRow.axis = .horizontal
        chipsRow.spacing = 8
        chipsRow.alignment = .center
        chipsRow.translatesAutoresizingMaskIntoConstraints = false
        chipsRow.isHidden = true

        // Content stack
        let contentStack = UIStackView(arrangedSubviews: [topRow, chipsRow])
        contentStack.axis = .vertical
        contentStack.spacing = 12
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: topAnchor),
            cardView.leadingAnchor.constraint(equalTo: leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: trailingAnchor),
            cardView.bottomAnchor.constraint(equalTo: bottomAnchor),

            iconContainer.widthAnchor.constraint(equalToConstant: 44),
            iconContainer.heightAnchor.constraint(equalToConstant: 44),
            iconImageView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 22),
            iconImageView.heightAnchor.constraint(equalToConstant: 22),

            chevronIcon.widthAnchor.constraint(equalToConstant: 18),
            chevronIcon.heightAnchor.constraint(equalToConstant: 18),

            checkmarkContainer.widthAnchor.constraint(equalToConstant: 24),
            checkmarkContainer.heightAnchor.constraint(equalToConstant: 24),
            checkmarkIcon.centerXAnchor.constraint(equalTo: checkmarkContainer.centerXAnchor),
            checkmarkIcon.centerYAnchor.constraint(equalTo: checkmarkContainer.centerYAnchor),
            checkmarkIcon.widthAnchor.constraint(equalToConstant: 12),
            checkmarkIcon.heightAnchor.constraint(equalToConstant: 12),

            contentStack.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 14),
            contentStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 14),
            contentStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -14),
            contentStack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -14),
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        cardView.addGestureRecognizer(tap)
        cardView.isUserInteractionEnabled = true
    }

    @objc private func handleTap() { tapAction?() }

    // MARK: - Configure

    func configure(version: DocumentVersion, isSelected: Bool, accentColor: UIColor, fontColor: UIColor, onTap: @escaping () -> Void) {
        tapAction = onTap
        let style = AmaniUI.sharedInstance.style

        // Card
        cardView.layer.cornerRadius = style.cardCornerRadius
        if isSelected {
            cardView.layer.borderWidth = style.cardBorderWidth
            cardView.layer.borderColor = accentColor.cgColor
            cardView.backgroundColor = accentColor.withAlphaComponent(0.07)
        } else {
            cardView.layer.borderWidth = 1
            cardView.layer.borderColor = fontColor.withAlphaComponent(0.18).cgColor
            cardView.backgroundColor = fontColor.withAlphaComponent(0.07)
        }

        // Icon
        iconContainer.backgroundColor = isSelected ? accentColor : accentColor.withAlphaComponent(0.12)
        iconImageView.image = iconForDocID(version.docID)?.withRenderingMode(.alwaysTemplate)
        iconImageView.tintColor = isSelected ? .white : accentColor

        // Title
        titleLabel.text = version.title
        titleLabel.textColor = isSelected ? fontColor : fontColor.withAlphaComponent(0.7)

        // Right indicator: show chevron or checkmark
        chevronIcon.isHidden = isSelected
        checkmarkContainer.isHidden = !isSelected
        chevronIcon.tintColor = fontColor.withAlphaComponent(0.35)
        checkmarkContainer.backgroundColor = accentColor

        // Chips
        chipsRow.arrangedSubviews.forEach { $0.removeFromSuperview() }
        if isSelected {
            chipsRow.isHidden = false
            if version.nfc == true {
                chipsRow.addArrangedSubview(makeChip(
                    text: "Fastest with NFC",
                    filled: true,
                    accentColor: accentColor,
                    fontColor: fontColor,
                    icon: "bolt.fill"
                ))
            }
            chipsRow.addArrangedSubview(makeChip(
                text: timeEstimate(for: version),
                filled: false,
                accentColor: accentColor,
                fontColor: fontColor
            ))
            let spacer = UIView()
            spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
            spacer.translatesAutoresizingMaskIntoConstraints = false
            chipsRow.addArrangedSubview(spacer)
        } else {
            chipsRow.isHidden = true
        }
    }

    // MARK: - Chip factory

    private func makeChip(text: String, filled: Bool, accentColor: UIColor, fontColor: UIColor, icon: String? = nil) -> UIView {
        let chip = UIView()
        chip.translatesAutoresizingMaskIntoConstraints = false
        chip.layer.cornerRadius = 14
        chip.clipsToBounds = true

        if filled {
            chip.backgroundColor = accentColor
        } else {
            chip.backgroundColor = .clear
            chip.layer.borderWidth = 1
            chip.layer.borderColor = fontColor.withAlphaComponent(0.2).cgColor
        }

        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.text = text
        label.textColor = filled ? .white : fontColor.withAlphaComponent(0.65)
        label.translatesAutoresizingMaskIntoConstraints = false

        if let iconName = icon {
            let iconView = UIImageView()
            iconView.translatesAutoresizingMaskIntoConstraints = false
            iconView.image = UIImage(systemName: iconName)?.withRenderingMode(.alwaysTemplate)
            iconView.tintColor = .white
            iconView.contentMode = .scaleAspectFit

            let row = UIStackView(arrangedSubviews: [iconView, label])
            row.axis = .horizontal
            row.spacing = 4
            row.alignment = .center
            row.translatesAutoresizingMaskIntoConstraints = false
            chip.addSubview(row)

            NSLayoutConstraint.activate([
                iconView.widthAnchor.constraint(equalToConstant: 12),
                iconView.heightAnchor.constraint(equalToConstant: 12),
                row.leadingAnchor.constraint(equalTo: chip.leadingAnchor, constant: 10),
                row.trailingAnchor.constraint(equalTo: chip.trailingAnchor, constant: -10),
                row.topAnchor.constraint(equalTo: chip.topAnchor, constant: 7),
                row.bottomAnchor.constraint(equalTo: chip.bottomAnchor, constant: -7),
            ])
        } else {
            chip.addSubview(label)
            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: chip.leadingAnchor, constant: 12),
                label.trailingAnchor.constraint(equalTo: chip.trailingAnchor, constant: -12),
                label.topAnchor.constraint(equalTo: chip.topAnchor, constant: 7),
                label.bottomAnchor.constraint(equalTo: chip.bottomAnchor, constant: -7),
            ])
        }

        return chip
    }

    // MARK: - Helpers

    private func iconForDocID(_ docID: String?) -> UIImage? {
        switch docID?.uppercased() {
        case "ID": return UIImage(systemName: "person.text.rectangle.fill")
        case "DL": return UIImage(systemName: "car.fill")
        case "PA": return UIImage(systemName: "doc.text.fill")
        case "NF": return UIImage(systemName: "wave.3.right")
        case "SE": return UIImage(systemName: "person.crop.circle.fill")
        default:   return UIImage(systemName: "person.text.rectangle.fill")
        }
    }

    private func timeEstimate(for version: DocumentVersion) -> String {
        if version.nfc == true { return "~2 min" }
        switch version.docID?.uppercased() {
        case "NF": return "~2 min"
        case "IB": return "~1 min"
        case "SE": return "~30 sec"
        default:   return "~30 sec"
        }
    }
}
