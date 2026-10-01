import UIKit

public enum SpicyAccountState: Equatable, Codable {
    case unavailable(reason: String?)
    case signedOut
    case guest
    case authorized(displayName: String)
    case error(message: String)
}

public enum SpicyEntitlementState: Equatable, Codable {
    case unknown
    case inactive
    case authorized(source: String)
    case expired(dateDescription: String?)
    case unavailable(reason: String?)
}

public struct SpicyAccountModel: Equatable, Codable {
    public var accountState: SpicyAccountState
    public var proState: SpicyEntitlementState
    public var licenseState: SpicyEntitlementState
    public var versionDescription: String

    public init(
        accountState: SpicyAccountState = .unavailable(reason: nil),
        proState: SpicyEntitlementState = .unknown,
        licenseState: SpicyEntitlementState = .unknown,
        versionDescription: String = "MR. SPICY 1.0.0"
    ) {
        self.accountState = accountState
        self.proState = proState
        self.licenseState = licenseState
        self.versionDescription = versionDescription
    }
}

public final class SpicyAccountView: UIView {
    private let stack = UIStackView()
    private let titleLabel = UILabel()
    private let truthfulStateLabel = UILabel()
    private let accountCard = UIStackView()
    private let proCard = UIStackView()
    private let licenseCard = UIStackView()
    private let versionCard = UIStackView()
    private var localizer = SpicyLocalizer()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    public func configure(model: SpicyAccountModel, localizer: SpicyLocalizer) {
        self.localizer = localizer
        titleLabel.text = localizer.localized(.accountTitle)
        truthfulStateLabel.text = localizer.localized(.truthfulStateNote)
        configureCard(accountCard, title: localizer.localized(.account), value: accountText(model.accountState))
        configureCard(proCard, title: localizer.localized(.proTitle), value: entitlementText(model.proState, unknownText: localizer.localized(.proUnknown)))
        configureCard(licenseCard, title: localizer.localized(.licenseTitle), value: entitlementText(model.licenseState, unknownText: localizer.localized(.licenseUnknown)))
        configureCard(versionCard, title: localizer.localized(.version), value: model.versionDescription)
        localizer.applySemanticDirection(to: self)
    }

    private func setup() {
        translatesAutoresizingMaskIntoConstraints = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = SpicyTheme.Spacing.md

        titleLabel.font = SpicyTheme.Typography.title
        titleLabel.textColor = SpicyTheme.Palette.textPrimary
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.numberOfLines = 0

        truthfulStateLabel.font = SpicyTheme.Typography.caption
        truthfulStateLabel.textColor = SpicyTheme.Palette.warning
        truthfulStateLabel.adjustsFontForContentSizeCategory = true
        truthfulStateLabel.numberOfLines = 0

        [accountCard, proCard, licenseCard, versionCard].forEach { card in
            card.axis = .vertical
            card.alignment = .fill
            card.spacing = SpicyTheme.Spacing.xs
            card.isLayoutMarginsRelativeArrangement = true
            card.layoutMargins = UIEdgeInsets(top: SpicyTheme.Spacing.md, left: SpicyTheme.Spacing.md, bottom: SpicyTheme.Spacing.md, right: SpicyTheme.Spacing.md)
            SpicyTheme.applyCardStyle(to: card, radius: SpicyTheme.CornerRadius.medium)
        }

        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(truthfulStateLabel)
        stack.addArrangedSubview(accountCard)
        stack.addArrangedSubview(proCard)
        stack.addArrangedSubview(licenseCard)
        stack.addArrangedSubview(versionCard)
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor)
        ])
    }

    private func configureCard(_ card: UIStackView, title: String, value: String) {
        card.arrangedSubviews.forEach { view in
            card.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        let titleLabel = UILabel()
        titleLabel.font = SpicyTheme.Typography.caption
        titleLabel.textColor = SpicyTheme.Palette.textTertiary
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.numberOfLines = 0
        titleLabel.text = title

        let valueLabel = UILabel()
        valueLabel.font = SpicyTheme.Typography.bodyEmphasis
        valueLabel.textColor = SpicyTheme.Palette.textPrimary
        valueLabel.adjustsFontForContentSizeCategory = true
        valueLabel.numberOfLines = 0
        valueLabel.text = value

        card.addArrangedSubview(titleLabel)
        card.addArrangedSubview(valueLabel)
        card.isAccessibilityElement = true
        card.accessibilityLabel = title
        card.accessibilityValue = value
    }

    private func accountText(_ state: SpicyAccountState) -> String {
        switch state {
        case .unavailable(let reason): return reason ?? localizer.localized(.accountUnavailable)
        case .signedOut: return localizer.localized(.accountSignedOut)
        case .guest: return localizer.localized(.accountGuest)
        case .authorized(let displayName): return displayName
        case .error(let message): return message
        }
    }

    private func entitlementText(_ state: SpicyEntitlementState, unknownText: String) -> String {
        switch state {
        case .unknown: return unknownText
        case .inactive: return localizer.localized(.statusUnavailable)
        case .authorized(let source): return "\(localizer.localized(.statusSuccess)): \(source)"
        case .expired(let dateDescription): return dateDescription.map { "\(localizer.localized(.statusUnavailable)): \($0)" } ?? localizer.localized(.statusUnavailable)
        case .unavailable(let reason): return reason ?? localizer.localized(.statusUnavailable)
        }
    }
}
