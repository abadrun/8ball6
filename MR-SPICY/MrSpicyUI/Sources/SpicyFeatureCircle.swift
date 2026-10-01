import UIKit

public enum SpicyFeatureCategory: String, CaseIterable, Codable {
    case automation
    case queue
    case account
    case pro
    case license
    case settings
    case language
    case help
    case about
}

public struct SpicyFeatureDescriptor: Hashable, Codable {
    public let category: SpicyFeatureCategory
    public let titleKey: SpicyLocalizationKey
    public let subtitleKey: SpicyLocalizationKey
    public let systemImageName: String
    public let isImplementedByDefault: Bool

    public init(
        category: SpicyFeatureCategory,
        titleKey: SpicyLocalizationKey,
        subtitleKey: SpicyLocalizationKey,
        systemImageName: String,
        isImplementedByDefault: Bool = true
    ) {
        self.category = category
        self.titleKey = titleKey
        self.subtitleKey = subtitleKey
        self.systemImageName = systemImageName
        self.isImplementedByDefault = isImplementedByDefault
    }
}

public struct SpicyFeaturePresentationState: Equatable, Codable {
    public var isSelected: Bool
    public var isActive: Bool
    public var isDisabled: Bool
    public var statusTone: SpicyStatusTone

    public init(
        isSelected: Bool = false,
        isActive: Bool = false,
        isDisabled: Bool = false,
        statusTone: SpicyStatusTone = .neutral
    ) {
        self.isSelected = isSelected
        self.isActive = isActive
        self.isDisabled = isDisabled
        self.statusTone = statusTone
    }
}

/// Circular MR. SPICY feature control.
///
/// The control is presentation-only. It provides no competitive gameplay,
/// aim assistance, entitlement bypass, ad bypass, or server manipulation.
public final class SpicyFeatureCircle: UIControl {
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let textStack = UIStackView()
    private let contentStack = UIStackView()
    private let statusDot = UIView()

    private var descriptor: SpicyFeatureDescriptor?
    private var presentationState = SpicyFeaturePresentationState()
    private var localizer = SpicyLocalizer()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    public func configure(
        descriptor: SpicyFeatureDescriptor,
        state: SpicyFeaturePresentationState,
        localizer: SpicyLocalizer
    ) {
        self.descriptor = descriptor
        self.presentationState = state
        self.localizer = localizer

        titleLabel.text = localizer.localized(descriptor.titleKey)
        subtitleLabel.text = localizer.localized(descriptor.subtitleKey)
        iconView.image = UIImage(systemName: descriptor.systemImageName)
        isEnabled = !state.isDisabled
        accessibilityLabel = titleLabel.text
        accessibilityHint = subtitleLabel.text
        accessibilityValue = state.isSelected ? localizer.localized(.statusReady) : localizer.localized(.statusUnavailable)
        localizer.applySemanticDirection(to: self)
        applyState(animated: false)
    }

    public override var isHighlighted: Bool {
        didSet { applyState(animated: true) }
    }

    public override var isSelected: Bool {
        didSet {
            presentationState.isSelected = isSelected
            applyState(animated: true)
        }
    }

    public override var isEnabled: Bool {
        didSet { applyState(animated: true) }
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        titleLabel.font = SpicyTheme.Typography.caption
        subtitleLabel.font = SpicyTheme.Typography.caption
    }

    private func setup() {
        translatesAutoresizingMaskIntoConstraints = false
        isAccessibilityElement = true
        accessibilityTraits.insert(.button)

        SpicyTheme.applyCardStyle(to: self, radius: SpicyTheme.CornerRadius.large)

        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = SpicyTheme.Palette.saffron
        iconView.setContentHuggingPriority(.required, for: .vertical)

        statusDot.translatesAutoresizingMaskIntoConstraints = false
        statusDot.layer.cornerRadius = 4
        statusDot.backgroundColor = SpicyTheme.Palette.textTertiary

        titleLabel.font = SpicyTheme.Typography.caption
        titleLabel.textColor = SpicyTheme.Palette.textPrimary
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 2
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.lineBreakMode = .byWordWrapping

        subtitleLabel.font = SpicyTheme.Typography.caption
        subtitleLabel.textColor = SpicyTheme.Palette.textTertiary
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 2
        subtitleLabel.adjustsFontForContentSizeCategory = true
        subtitleLabel.lineBreakMode = .byWordWrapping

        textStack.axis = .vertical
        textStack.alignment = .fill
        textStack.spacing = SpicyTheme.Spacing.xxs
        textStack.addArrangedSubview(titleLabel)
        textStack.addArrangedSubview(subtitleLabel)

        contentStack.axis = .vertical
        contentStack.alignment = .center
        contentStack.spacing = SpicyTheme.Spacing.sm
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.isUserInteractionEnabled = false
        contentStack.addArrangedSubview(iconView)
        contentStack.addArrangedSubview(textStack)

        addSubview(contentStack)
        addSubview(statusDot)

        NSLayoutConstraint.activate([
            widthAnchor.constraint(greaterThanOrEqualToConstant: SpicyTheme.ControlSizing.compactFeatureCircle),
            heightAnchor.constraint(greaterThanOrEqualToConstant: SpicyTheme.ControlSizing.compactFeatureCircle),
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: SpicyTheme.Spacing.sm),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -SpicyTheme.Spacing.sm),
            contentStack.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: SpicyTheme.IconSizing.feature),
            iconView.heightAnchor.constraint(equalToConstant: SpicyTheme.IconSizing.feature),
            statusDot.widthAnchor.constraint(equalToConstant: 8),
            statusDot.heightAnchor.constraint(equalToConstant: 8),
            statusDot.topAnchor.constraint(equalTo: topAnchor, constant: SpicyTheme.Spacing.sm),
            statusDot.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -SpicyTheme.Spacing.sm)
        ])
    }

    private func applyState(animated: Bool) {
        let changes = {
            let disabled = self.presentationState.isDisabled || !self.isEnabled
            let selected = self.presentationState.isSelected || self.isSelected
            let active = self.presentationState.isActive

            self.alpha = disabled ? 0.56 : 1.0
            self.transform = self.isHighlighted && !disabled ? CGAffineTransform(scaleX: 0.96, y: 0.96) : .identity
            self.layer.borderWidth = selected ? SpicyTheme.Border.selected : SpicyTheme.Border.hairline
            self.layer.borderColor = selected ? SpicyTheme.Palette.selectedBorder.cgColor : SpicyTheme.Palette.border.cgColor
            self.backgroundColor = selected ? SpicyTheme.Palette.elevatedBackground : SpicyTheme.Palette.cardBackground
            self.iconView.tintColor = disabled ? SpicyTheme.Palette.disabledText : (active ? SpicyTheme.Palette.mint : SpicyTheme.Palette.saffron)
            self.titleLabel.textColor = disabled ? SpicyTheme.Palette.disabledText : SpicyTheme.Palette.textPrimary
            self.subtitleLabel.textColor = disabled ? SpicyTheme.Palette.disabledText : SpicyTheme.Palette.textTertiary
            self.statusDot.backgroundColor = disabled ? SpicyTheme.Palette.disabledText : SpicyTheme.statusColor(for: self.presentationState.statusTone)
        }

        guard animated else {
            changes()
            return
        }

        UIView.animate(
            withDuration: SpicyTheme.Animation.duration(SpicyTheme.Animation.quick),
            delay: 0,
            options: [.beginFromCurrentState, .allowUserInteraction],
            animations: changes
        )
    }
}
