import UIKit

public protocol SpicyHeaderViewDelegate: AnyObject {
    func spicyHeaderDidTapClose(_ header: SpicyHeaderView)
    func spicyHeaderDidTapMinimize(_ header: SpicyHeaderView)
    func spicyHeaderDidTapSettings(_ header: SpicyHeaderView)
    func spicyHeaderDidTapAccount(_ header: SpicyHeaderView)
    func spicyHeaderDidTapLanguage(_ header: SpicyHeaderView)
}

public struct SpicyHeaderConfiguration: Equatable {
    public var subtitle: SpicyLocalizationKey?
    public var statusText: SpicyLocalizationKey?
    public var statusTone: SpicyStatusTone
    public var showsClose: Bool
    public var showsMinimize: Bool
    public var showsSettings: Bool
    public var showsAccount: Bool
    public var showsLanguage: Bool

    public init(
        subtitle: SpicyLocalizationKey? = .appSubtitle,
        statusText: SpicyLocalizationKey? = .statusReady,
        statusTone: SpicyStatusTone = .neutral,
        showsClose: Bool = true,
        showsMinimize: Bool = true,
        showsSettings: Bool = true,
        showsAccount: Bool = true,
        showsLanguage: Bool = true
    ) {
        self.subtitle = subtitle
        self.statusText = statusText
        self.statusTone = statusTone
        self.showsClose = showsClose
        self.showsMinimize = showsMinimize
        self.showsSettings = showsSettings
        self.showsAccount = showsAccount
        self.showsLanguage = showsLanguage
    }
}

public final class SpicyHeaderView: UIView {
    public weak var delegate: SpicyHeaderViewDelegate?

    private let logoView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let statusLabel = UILabel()
    private let titleStack = UIStackView()
    private let actionStack = UIStackView()
    private let textAndStatusStack = UIStackView()

    private let closeButton = UIButton(type: .system)
    private let minimizeButton = UIButton(type: .system)
    private let settingsButton = UIButton(type: .system)
    private let accountButton = UIButton(type: .system)
    private let languageButton = UIButton(type: .system)

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
        localizer: SpicyLocalizer,
        configuration: SpicyHeaderConfiguration = SpicyHeaderConfiguration(),
        logo: UIImage? = UIImage(named: "MrSpicyLogo")
    ) {
        self.localizer = localizer
        titleLabel.text = localizer.localized(.appTitle)
        subtitleLabel.text = configuration.subtitle.map { localizer.localized($0) }
        statusLabel.text = configuration.statusText.map { localizer.localized($0) }
        statusLabel.textColor = SpicyTheme.statusColor(for: configuration.statusTone)
        logoView.image = logo ?? UIImage(named: "MrSpicyLogo")

        closeButton.isHidden = !configuration.showsClose
        minimizeButton.isHidden = !configuration.showsMinimize
        settingsButton.isHidden = !configuration.showsSettings
        accountButton.isHidden = !configuration.showsAccount
        languageButton.isHidden = !configuration.showsLanguage

        closeButton.accessibilityLabel = localizer.localized(.close)
        closeButton.accessibilityHint = localizer.localized(.accessibilityHintClose)
        minimizeButton.accessibilityLabel = localizer.localized(.minimize)
        minimizeButton.accessibilityHint = localizer.localized(.accessibilityHintMinimize)
        settingsButton.accessibilityLabel = localizer.localized(.settings)
        settingsButton.accessibilityHint = localizer.localized(.accessibilityHintSettings)
        accountButton.accessibilityLabel = localizer.localized(.account)
        accountButton.accessibilityHint = localizer.localized(.accessibilityHintAccount)
        languageButton.accessibilityLabel = localizer.localized(.language)
        languageButton.accessibilityHint = localizer.localized(.accessibilityHintLanguage)
        logoView.accessibilityLabel = localizer.localized(.accessibilityLabelLogo)
        logoView.accessibilityHint = localizer.localized(.accessibilityHintLogo)

        localizer.applySemanticDirection(to: self)
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateResponsiveLayout()
    }

    private func setup() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = UIColor.clear

        logoView.translatesAutoresizingMaskIntoConstraints = false
        logoView.contentMode = .scaleAspectFit
        logoView.clipsToBounds = true
        logoView.layer.cornerRadius = SpicyTheme.CornerRadius.small
        logoView.isAccessibilityElement = true
        logoView.accessibilityTraits = .image

        titleLabel.font = SpicyTheme.Typography.title
        titleLabel.textColor = SpicyTheme.Palette.textPrimary
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.numberOfLines = 1
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        subtitleLabel.font = SpicyTheme.Typography.caption
        subtitleLabel.textColor = SpicyTheme.Palette.textTertiary
        subtitleLabel.adjustsFontForContentSizeCategory = true
        subtitleLabel.numberOfLines = 2

        statusLabel.font = SpicyTheme.Typography.caption
        statusLabel.adjustsFontForContentSizeCategory = true
        statusLabel.numberOfLines = 1
        statusLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        titleStack.axis = .vertical
        titleStack.alignment = .leading
        titleStack.spacing = SpicyTheme.Spacing.xxs
        titleStack.addArrangedSubview(titleLabel)
        titleStack.addArrangedSubview(subtitleLabel)

        textAndStatusStack.axis = .vertical
        textAndStatusStack.alignment = .leading
        textAndStatusStack.spacing = SpicyTheme.Spacing.xxs
        textAndStatusStack.translatesAutoresizingMaskIntoConstraints = false
        textAndStatusStack.addArrangedSubview(titleStack)
        textAndStatusStack.addArrangedSubview(statusLabel)

        actionStack.axis = .horizontal
        actionStack.alignment = .center
        actionStack.distribution = .fill
        actionStack.spacing = SpicyTheme.Spacing.xs
        actionStack.translatesAutoresizingMaskIntoConstraints = false

        configureIconButton(languageButton, systemName: "globe", action: #selector(languageTapped))
        configureIconButton(accountButton, systemName: "person.crop.circle", action: #selector(accountTapped))
        configureIconButton(settingsButton, systemName: "gearshape", action: #selector(settingsTapped))
        configureIconButton(minimizeButton, systemName: "minus", action: #selector(minimizeTapped))
        configureIconButton(closeButton, systemName: "xmark", action: #selector(closeTapped))

        [languageButton, accountButton, settingsButton, minimizeButton, closeButton].forEach(actionStack.addArrangedSubview)

        addSubview(logoView)
        addSubview(textAndStatusStack)
        addSubview(actionStack)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(greaterThanOrEqualToConstant: SpicyTheme.ControlSizing.headerHeight),
            logoView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: SpicyTheme.Spacing.lg),
            logoView.centerYAnchor.constraint(equalTo: centerYAnchor),
            logoView.widthAnchor.constraint(equalToConstant: SpicyTheme.IconSizing.logo),
            logoView.heightAnchor.constraint(equalToConstant: SpicyTheme.IconSizing.logo),
            textAndStatusStack.leadingAnchor.constraint(equalTo: logoView.trailingAnchor, constant: SpicyTheme.Spacing.md),
            textAndStatusStack.centerYAnchor.constraint(equalTo: centerYAnchor),
            actionStack.leadingAnchor.constraint(greaterThanOrEqualTo: textAndStatusStack.trailingAnchor, constant: SpicyTheme.Spacing.md),
            actionStack.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -SpicyTheme.Spacing.lg),
            actionStack.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    private func configureIconButton(_ button: UIButton, systemName: String, action: Selector) {
        let image = UIImage(systemName: systemName)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(image, for: .normal)
        button.tintColor = SpicyTheme.Palette.textPrimary
        button.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        button.layer.cornerRadius = SpicyTheme.CornerRadius.pill
        button.addTarget(self, action: action, for: .touchUpInside)
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(greaterThanOrEqualToConstant: SpicyTheme.ControlSizing.minimumTouchTarget),
            button.heightAnchor.constraint(greaterThanOrEqualToConstant: SpicyTheme.ControlSizing.minimumTouchTarget)
        ])
    }

    private func updateResponsiveLayout() {
        let isCompact = traitCollection.horizontalSizeClass == .compact
        subtitleLabel.isHidden = isCompact && traitCollection.preferredContentSizeCategory.isAccessibilityCategory
        actionStack.spacing = isCompact ? SpicyTheme.Spacing.xxs : SpicyTheme.Spacing.xs
    }

    @objc private func closeTapped() { delegate?.spicyHeaderDidTapClose(self) }
    @objc private func minimizeTapped() { delegate?.spicyHeaderDidTapMinimize(self) }
    @objc private func settingsTapped() { delegate?.spicyHeaderDidTapSettings(self) }
    @objc private func accountTapped() { delegate?.spicyHeaderDidTapAccount(self) }
    @objc private func languageTapped() { delegate?.spicyHeaderDidTapLanguage(self) }
}
