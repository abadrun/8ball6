import UIKit

/// Central MR. SPICY design system.
///
/// This file intentionally contains visual constants only. It does not alter the
/// original host application, accounts, ads, payments, gameplay, or server state.
public enum SpicyTheme {
    public enum Palette {
        public static let background = UIColor(red: 0.055, green: 0.035, blue: 0.047, alpha: 1.0)
        public static let elevatedBackground = UIColor(red: 0.110, green: 0.071, blue: 0.086, alpha: 1.0)
        public static let cardBackground = UIColor(red: 0.156, green: 0.093, blue: 0.101, alpha: 0.96)
        public static let modalBackground = UIColor(red: 0.084, green: 0.052, blue: 0.064, alpha: 0.98)
        public static let overlayScrim = UIColor.black.withAlphaComponent(0.42)

        public static let chili = UIColor(red: 0.890, green: 0.184, blue: 0.118, alpha: 1.0)
        public static let paprika = UIColor(red: 1.000, green: 0.365, blue: 0.157, alpha: 1.0)
        public static let saffron = UIColor(red: 1.000, green: 0.722, blue: 0.255, alpha: 1.0)
        public static let mint = UIColor(red: 0.286, green: 0.847, blue: 0.612, alpha: 1.0)
        public static let error = UIColor(red: 1.000, green: 0.310, blue: 0.310, alpha: 1.0)
        public static let warning = UIColor(red: 1.000, green: 0.770, blue: 0.325, alpha: 1.0)
        public static let success = UIColor(red: 0.329, green: 0.843, blue: 0.494, alpha: 1.0)

        public static let textPrimary = UIColor.white
        public static let textSecondary = UIColor(white: 0.88, alpha: 1.0)
        public static let textTertiary = UIColor(white: 0.68, alpha: 1.0)
        public static let disabledText = UIColor(white: 0.58, alpha: 1.0)
        public static let border = UIColor.white.withAlphaComponent(0.14)
        public static let selectedBorder = saffron.withAlphaComponent(0.82)
        public static let separator = UIColor.white.withAlphaComponent(0.10)
    }

    public enum Typography {
        public static let title = UIFontMetrics(forTextStyle: .headline).scaledFont(
            for: UIFont.systemFont(ofSize: 19, weight: .semibold)
        )
        public static let subtitle = UIFontMetrics(forTextStyle: .subheadline).scaledFont(
            for: UIFont.systemFont(ofSize: 14, weight: .medium)
        )
        public static let body = UIFontMetrics(forTextStyle: .body).scaledFont(
            for: UIFont.systemFont(ofSize: 15, weight: .regular)
        )
        public static let bodyEmphasis = UIFontMetrics(forTextStyle: .body).scaledFont(
            for: UIFont.systemFont(ofSize: 15, weight: .semibold)
        )
        public static let caption = UIFontMetrics(forTextStyle: .caption1).scaledFont(
            for: UIFont.systemFont(ofSize: 12, weight: .medium)
        )
        public static let button = UIFontMetrics(forTextStyle: .callout).scaledFont(
            for: UIFont.systemFont(ofSize: 15, weight: .semibold)
        )
    }

    public enum Spacing {
        public static let xxs: CGFloat = 4
        public static let xs: CGFloat = 6
        public static let sm: CGFloat = 8
        public static let md: CGFloat = 12
        public static let lg: CGFloat = 16
        public static let xl: CGFloat = 20
        public static let xxl: CGFloat = 28
    }

    public enum CornerRadius {
        public static let small: CGFloat = 10
        public static let medium: CGFloat = 16
        public static let large: CGFloat = 22
        public static let pill: CGFloat = 999
    }

    public enum Border {
        public static let hairline: CGFloat = 1.0 / UIScreen.main.scale
        public static let selected: CGFloat = 1.5
        public static let focused: CGFloat = 2.0
    }

    public enum Shadow {
        public static let opacity: Float = 0.28
        public static let radius: CGFloat = 16
        public static let offset = CGSize(width: 0, height: 10)
    }

    public enum IconSizing {
        public static let small: CGFloat = 18
        public static let medium: CGFloat = 24
        public static let large: CGFloat = 36
        public static let logo: CGFloat = 38
        public static let feature: CGFloat = 30
    }

    public enum ControlSizing {
        public static let minimumTouchTarget: CGFloat = 44
        public static let featureCircle: CGFloat = 92
        public static let compactFeatureCircle: CGFloat = 78
        public static let headerHeight: CGFloat = 64
        public static let modalMaxWidth: CGFloat = 420
    }

    public enum Overlay {
        public static let maxWidth: CGFloat = 540
        public static let compactMaxWidth: CGFloat = 360
        public static let opacity: CGFloat = 0.98
        public static let minimizedWidth: CGFloat = 168
        public static let minimizedHeight: CGFloat = 58
    }

    public enum Animation {
        public static let quick: TimeInterval = 0.16
        public static let standard: TimeInterval = 0.24
        public static let relaxed: TimeInterval = 0.34
        public static let damping: CGFloat = 0.82
        public static let initialVelocity: CGFloat = 0.64

        public static func duration(_ value: TimeInterval) -> TimeInterval {
            UIAccessibility.isReduceMotionEnabled ? 0.01 : value
        }
    }

    public static func applyCardStyle(to view: UIView, radius: CGFloat = CornerRadius.large) {
        view.backgroundColor = Palette.cardBackground
        view.layer.cornerRadius = radius
        view.layer.borderWidth = Border.hairline
        view.layer.borderColor = Palette.border.cgColor
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = Shadow.opacity
        view.layer.shadowRadius = Shadow.radius
        view.layer.shadowOffset = Shadow.offset
        view.clipsToBounds = false
    }

    public static func applyPrimaryButtonStyle(to button: UIButton) {
        button.titleLabel?.font = Typography.button
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.backgroundColor = Palette.chili
        button.tintColor = Palette.textPrimary
        button.setTitleColor(Palette.textPrimary, for: .normal)
        button.setTitleColor(Palette.disabledText, for: .disabled)
        button.layer.cornerRadius = CornerRadius.medium
        button.contentEdgeInsets = UIEdgeInsets(top: Spacing.md, left: Spacing.lg, bottom: Spacing.md, right: Spacing.lg)
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: ControlSizing.minimumTouchTarget).isActive = true
    }

    public static func applySecondaryButtonStyle(to button: UIButton) {
        button.titleLabel?.font = Typography.button
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        button.tintColor = Palette.textPrimary
        button.setTitleColor(Palette.textPrimary, for: .normal)
        button.setTitleColor(Palette.disabledText, for: .disabled)
        button.layer.cornerRadius = CornerRadius.medium
        button.layer.borderWidth = Border.hairline
        button.layer.borderColor = Palette.border.cgColor
        button.contentEdgeInsets = UIEdgeInsets(top: Spacing.md, left: Spacing.lg, bottom: Spacing.md, right: Spacing.lg)
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: ControlSizing.minimumTouchTarget).isActive = true
    }

    public static func statusColor(for state: SpicyStatusTone) -> UIColor {
        switch state {
        case .neutral: return Palette.textTertiary
        case .active: return Palette.mint
        case .warning: return Palette.warning
        case .error: return Palette.error
        case .success: return Palette.success
        }
    }
}

public enum SpicyStatusTone: String, Codable, CaseIterable {
    case neutral
    case active
    case warning
    case error
    case success
}
