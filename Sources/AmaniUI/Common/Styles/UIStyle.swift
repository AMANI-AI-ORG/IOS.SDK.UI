import UIKit

struct UIStyle {
    let cardCornerRadius: CGFloat
    let badgeSize: CGFloat
    let badgeCornerRadius: CGFloat
    let ctaButtonCornerRadius: CGFloat
    let ctaButtonHeight: CGFloat
    let cardBorderWidth: CGFloat
    let navButtonSize: CGFloat
    let navButtonCornerRadius: CGFloat

    static let v1 = UIStyle(
        cardCornerRadius: CGFloat(AmaniUI.sharedInstance.config?.generalconfigs?.buttonRadius ?? 10),
        badgeSize: 36,
        badgeCornerRadius: 8,
        ctaButtonCornerRadius: 24,
        ctaButtonHeight: 50,
        cardBorderWidth: 2,
        navButtonSize: 36,
        navButtonCornerRadius: 8
    )

    static let v2 = UIStyle(
        cardCornerRadius: 16,
        badgeSize: 40,
        badgeCornerRadius: 12,
        ctaButtonCornerRadius: 16,
        ctaButtonHeight: 56,
        cardBorderWidth: 1.5,
        navButtonSize: 36,
        navButtonCornerRadius: 14
    )
}
