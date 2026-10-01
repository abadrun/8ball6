import UIKit

public enum SpicySettingKind: String, CaseIterable, Codable {
    case language
    case appearance
    case animation
    case overlaySizing
    case accessibility
    case account
    case help
    case about
    case version

    var titleKey: SpicyLocalizationKey {
        switch self {
        case .language: return .language
        case .appearance: return .appearance
        case .animation: return .animation
        case .overlaySizing: return .overlaySizing
        case .accessibility: return .accessibility
        case .account: return .account
        case .help: return .help
        case .about: return .about
        case .version: return .version
        }
    }

    var iconName: String {
        switch self {
        case .language: return "globe"
        case .appearance: return "paintpalette"
        case .animation: return "sparkles"
        case .overlaySizing: return "rectangle.expand.vertical"
        case .accessibility: return "accessibility"
        case .account: return "person.crop.circle"
        case .help: return "questionmark.circle"
        case .about: return "info.circle"
        case .version: return "number"
        }
    }
}

public protocol SpicySettingsViewDelegate: AnyObject {
    func spicySettingsView(_ view: SpicySettingsView, didSelect kind: SpicySettingKind)
}

public final class SpicySettingsView: UIView {
    public weak var delegate: SpicySettingsViewDelegate?

    private let scrollView = UIScrollView()
    private let stack = UIStackView()
    private var localizer = SpicyLocalizer()
    private var rowButtons: [SpicySettingKind: UIButton] = [:]

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    public func configure(localizer: SpicyLocalizer) {
        self.localizer = localizer
        rebuildRows()
        localizer.applySemanticDirection(to: self)
    }

    private func setup() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = UIColor.clear
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = SpicyTheme.Spacing.sm

        addSubview(scrollView)
        scrollView.addSubview(stack)
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            stack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])
    }

    private func rebuildRows() {
        stack.arrangedSubviews.forEach { view in
            stack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        rowButtons.removeAll()

        SpicySettingKind.allCases.forEach { kind in
            let button = makeRowButton(kind: kind)
            stack.addArrangedSubview(button)
            rowButtons[kind] = button
        }
    }

    private func makeRowButton(kind: SpicySettingKind) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.contentHorizontalAlignment = .leading
        button.backgroundColor = UIColor.white.withAlphaComponent(0.07)
        button.layer.cornerRadius = SpicyTheme.CornerRadius.medium
        button.layer.borderWidth = SpicyTheme.Border.hairline
        button.layer.borderColor = SpicyTheme.Palette.border.cgColor
        button.tintColor = SpicyTheme.Palette.saffron
        button.tag = SpicySettingKind.allCases.firstIndex(of: kind) ?? 0
        button.addTarget(self, action: #selector(rowTapped(_:)), for: .touchUpInside)
        button.accessibilityTraits = .button
        button.accessibilityLabel = localizer.localized(kind.titleKey)
        button.accessibilityHint = subtitle(for: kind)
        button.setImage(UIImage(systemName: kind.iconName), for: .normal)
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: SpicyTheme.Spacing.md, bottom: 0, right: SpicyTheme.Spacing.md)
        button.titleEdgeInsets = UIEdgeInsets(top: SpicyTheme.Spacing.sm, left: SpicyTheme.Spacing.lg, bottom: SpicyTheme.Spacing.sm, right: SpicyTheme.Spacing.lg)
        button.contentEdgeInsets = UIEdgeInsets(top: SpicyTheme.Spacing.md, left: SpicyTheme.Spacing.md, bottom: SpicyTheme.Spacing.md, right: SpicyTheme.Spacing.md)

        let title = localizer.localized(kind.titleKey)
        let subtitle = subtitle(for: kind) ?? ""
        let attributed = NSMutableAttributedString(
            string: title,
            attributes: [
                .font: SpicyTheme.Typography.bodyEmphasis,
                .foregroundColor: SpicyTheme.Palette.textPrimary
            ]
        )
        if !subtitle.isEmpty {
            attributed.append(NSAttributedString(
                string: "\n\(subtitle)",
                attributes: [
                    .font: SpicyTheme.Typography.caption,
                    .foregroundColor: SpicyTheme.Palette.textTertiary
                ]
            ))
        }
        button.setAttributedTitle(attributed, for: .normal)
        button.titleLabel?.numberOfLines = 0
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: SpicyTheme.ControlSizing.minimumTouchTarget).isActive = true
        return button
    }

    private func subtitle(for kind: SpicySettingKind) -> String? {
        switch kind {
        case .language: return localizer.localized(.languageDescription)
        case .appearance: return localizer.localized(.settingsSubtitle)
        case .animation: return localizer.localized(.accessibilityReduceMotion)
        case .overlaySizing: return localizer.localized(.settingsSubtitle)
        case .accessibility: return localizer.localized(.accessibilityDynamicType)
        case .account: return localizer.localized(.accountSubtitle)
        case .help: return localizer.localized(.helpSubtitle)
        case .about: return localizer.localized(.aboutSubtitle)
        case .version: return "MR. SPICY 1.0.0"
        }
    }

    @objc private func rowTapped(_ sender: UIButton) {
        let all = SpicySettingKind.allCases
        guard sender.tag >= 0, sender.tag < all.count else { return }
        delegate?.spicySettingsView(self, didSelect: all[sender.tag])
    }
}
