import UIKit
import AmaniSDK

final class StepProgressView: UIView {

    private var dotViews: [UIView] = []
    private var lineViews: [UIView] = []
    private var labelViews: [UILabel] = []

    // MARK: - Public configure

    func configure(steps: [KYCStepViewModel], accentColor: UIColor) {
        subviews.forEach { $0.removeFromSuperview() }
        dotViews = []
        lineViews = []
        labelViews = []

        guard !steps.isEmpty else { return }

        let fontColor = hextoUIColor(hexString: AmaniUI.sharedInstance.config?.generalconfigs?.appFontColor ?? "FFFFFF")

        let activeIndex = steps.firstIndex(where: {
            ($0.isEnabled() && $0.status != .APPROVED && $0.status != .PENDING_REVIEW)
                || $0.status == .REJECTED || $0.status == .AUTOMATICALLY_REJECTED
        }) ?? 0

        // Build step containers (equal-width columns)
        let stepStack = UIStackView()
        stepStack.axis = .horizontal
        stepStack.distribution = .fillEqually
        stepStack.alignment = .fill
        stepStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stepStack)

        NSLayoutConstraint.activate([
            stepStack.topAnchor.constraint(equalTo: topAnchor),
            stepStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stepStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stepStack.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        for (i, step) in steps.enumerated() {
            let isCompleted = step.status == .APPROVED || step.status == .PENDING_REVIEW
            let isActive = i == activeIndex

            // Dot
            let dot = UIView()
            dot.translatesAutoresizingMaskIntoConstraints = false
            dot.layer.cornerRadius = 6

            if isCompleted || isActive {
                dot.backgroundColor = accentColor
                dot.layer.borderWidth = 0
            } else {
                dot.backgroundColor = .clear
                dot.layer.borderWidth = 1.5
                dot.layer.borderColor = fontColor.withAlphaComponent(0.3).cgColor
            }
            dotViews.append(dot)

            // Label
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.text = step.stepConfig.title ?? step.id
            label.font = UIFont.systemFont(ofSize: 9, weight: .medium)
            label.textAlignment = .center
            label.numberOfLines = 2
            label.lineBreakMode = .byWordWrapping

            if isActive {
                label.textColor = accentColor
                label.font = UIFont.systemFont(ofSize: 9, weight: .semibold)
            } else if isCompleted {
                label.textColor = fontColor.withAlphaComponent(0.7)
            } else {
                label.textColor = fontColor.withAlphaComponent(0.35)
            }
            labelViews.append(label)

            // Container column
            let container = UIView()
            container.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(dot)
            container.addSubview(label)

            NSLayoutConstraint.activate([
                dot.widthAnchor.constraint(equalToConstant: 12),
                dot.heightAnchor.constraint(equalToConstant: 12),
                dot.centerXAnchor.constraint(equalTo: container.centerXAnchor),
                dot.topAnchor.constraint(equalTo: container.topAnchor),

                label.topAnchor.constraint(equalTo: dot.bottomAnchor, constant: 4),
                label.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                label.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                label.bottomAnchor.constraint(equalTo: container.bottomAnchor),
                label.heightAnchor.constraint(equalToConstant: 28),
            ])

            stepStack.addArrangedSubview(container)
        }

        // Lines between dots — laid over the stepStack as siblings in self
        for i in 0..<(steps.count - 1) {
            let isCompleted = steps[i].status == .APPROVED || steps[i].status == .PENDING_REVIEW
            let line = UIView()
            line.translatesAutoresizingMaskIntoConstraints = false
            line.backgroundColor = isCompleted ? accentColor : fontColor.withAlphaComponent(0.2)
            lineViews.append(line)
            addSubview(line)

            let leftDot = dotViews[i]
            let rightDot = dotViews[i + 1]

            NSLayoutConstraint.activate([
                line.heightAnchor.constraint(equalToConstant: 2),
                line.centerYAnchor.constraint(equalTo: leftDot.centerYAnchor),
                line.leadingAnchor.constraint(equalTo: leftDot.trailingAnchor, constant: 2),
                line.trailingAnchor.constraint(equalTo: rightDot.leadingAnchor, constant: -2),
            ])
        }
    }
}
