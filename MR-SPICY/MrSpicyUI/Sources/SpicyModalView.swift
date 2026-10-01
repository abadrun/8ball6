import UIKit

public enum SpicyModalState: Equatable, Codable {
    case normal
    case loading
    case success
    case error
    case disabled
}

public struct SpicyModalConfiguration: Equatable {
    public var titleKey: SpicyLocalizationKey
    public var iconSystemName: String
    public var descriptionKey: SpicyLocalizationKey
    public var primaryActionKey: SpicyLocalizationKey?
    public var secondaryActionKey: SpicyLocalizationKey?
    public var state: SpicyModalState

    public init(
        titleKey: SpicyLocalizationKey,
        iconSystemName: String,
        descriptionKey: SpicyLocalizationKey,
        primaryActionKey: SpicyLocalizationKey? = .done,
        secondaryActionKey: SpicyLocalizationKey? = .cancel,
        state: SpicyModalState = .normal
    ) {
        self.titleKey = titleKey
        self.iconSystemName = iconSystemName
        self.descriptionKey = descriptionKey
        self.primaryActionKey = primaryActionKey
        self.secondaryActionKey = secondaryActionKey
        self.state = state
    }
}

public protocol SpicyModalViewDelegate: AnyObject {
    func spicyModalDidTapPrimary(_ modal: SpicyModalView)
    func spicyModalDidTapSecondary(_ modal: SpicyModalView)
    func spicyModalDidTapClose(_ modal: SpicyModalView)
}

public final class SpicyModalView: UIView {
    public weak var delegate: SpicyModalViewDelegate?

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let stack = UIStackView()
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    private let actionStack = UIStackView()
    private let primaryButton = UIButton(type: .system)
    private let secondaryButton = UIButton(type: .system)
    private let closeButton = UIButton(type: .system)

    private var localizer = SpicyLocalizer()
    private var configuration: SpicyModalConfiguration?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    public func configure(_ configuration: SpicyModalConfiguration, localizer: SpicyLocalizer) {
        self.configuration = configuration
        self.localizer = localizer
        titleLabel.text = localizer.localized(configuration.titleKey)
        descriptionLabel.text = localizer.localized(configuration.descriptionKey)
        iconView.image = UIImage(systemName: configuration.iconSystemName)
        primaryButton.setTitle(configuration.primaryActionKey.map { localizer.localized($0) }, for: .normal)
        secondaryButton.setTitle(configuration.secondaryActionKey.map { localizer.localized($0) }, for: .normal)
        primaryButton.isHidden = configuration.primaryActionKey == nil
        secondaryButton.isHidden = configuration.secondaryActionKey == nil
        accessibilityViewIsModal = true
        accessibilityLabel = titleLabel.text
        accessibilityHint = descriptionLabel.text
        localizer.applySemanticDirection(to: self)
        applyState(configuration.state, animated: false)
    }

    public func setState(_ state: SpicyModalState, animated: Bool = true) {
        guard var configuration else { return }
        configuration.state = state
        self.configuration = configuration
        applyState(state, animated: animated)
    }

    private func setup() {
        translatesAutoresizingMaskIntoConstraints = false
        SpicyTheme.applyCardStyle(to: self, radius: SpicyTheme.CornerRadius.large)
        backgroundColor = SpicyTheme.Palette.modalBackground

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = false
        scrollView.keyboardDismissMode = .interactive

        contentView.translatesAutoresizingMaskIntoConstraints = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = SpicyTheme.Spacing.lg

        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = SpicyTheme.Palette.textPrimary
        closeButton.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        closeButton.layer.cornerRadius = SpicyTheme.CornerRadius.pill
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        closeButton.accessibilityTraits = .button

        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.tintColor = SpicyTheme.Palette.saffron
        iconView.contentMode = .scaleAspectFit

        titleLabel.font = SpicyTheme.Typography.title
        titleLabel.textColor = SpicyTheme.Palette.textPrimary
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .natural

        descriptionLabel.font = SpicyTheme.Typography.body
        descriptionLabel.textColor = SpicyTheme.Palette.textSecondary
        descriptionLabel.adjustsFontForContentSizeCategory = true
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textAlignment = .natural

        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = SpicyTheme.Palette.saffron

        actionStack.axis = .horizontal
        actionStack.alignment = .fill
        actionStack.distribution = .fillEqually
        actionStack.spacing = SpicyTheme.Spacing.md
        SpicyTheme.applyPrimaryButtonStyle(to: primaryButton)
        SpicyTheme.applySecondaryButtonStyle(to: secondaryButton)
        primaryButton.addTarget(self, action: #selector(primaryTapped), for: .touchUpInside)
        secondaryButton.addTarget(self, action: #selector(secondaryTapped), for: .touchUpInside)

        stack.addArrangedSubview(iconView)
        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(descriptionLabel)
        stack.addArrangedSubview(activityIndicator)
        stack.addArrangedSubview(actionStack)
        actionStack.addArrangedSubview(secondaryButton)
        actionStack.addArrangedSubview(primaryButton)

        addSubview(scrollView)
        addSubview(closeButton)
        scrollView.addSubview(contentView)
        contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            widthAnchor.constraint(lessThanOrEqualToConstant: SpicyTheme.ControlSizing.modalMaxWidth),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: SpicyTheme.Spacing.xl),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -SpicyTheme.Spacing.xl),
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: SpicyTheme.Spacing.xxl),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -SpicyTheme.Spacing.xxl),
            iconView.widthAnchor.constraint(equalToConstant: SpicyTheme.IconSizing.large),
            iconView.heightAnchor.constraint(equalToConstant: SpicyTheme.IconSizing.large),
            closeButton.widthAnchor.constraint(greaterThanOrEqualToConstant: SpicyTheme.ControlSizing.minimumTouchTarget),
            closeButton.heightAnchor.constraint(greaterThanOrEqualToConstant: SpicyTheme.ControlSizing.minimumTouchTarget),
            closeButton.topAnchor.constraint(equalTo: topAnchor, constant: SpicyTheme.Spacing.sm),
            closeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -SpicyTheme.Spacing.sm)
        ])
    }

    private func applyState(_ state: SpicyModalState, animated: Bool) {
        let changes = {
            switch state {
            case .normal:
                self.iconView.tintColor = SpicyTheme.Palette.saffron
                self.primaryButton.isEnabled = true
                self.secondaryButton.isEnabled = true
                self.activityIndicator.stopAnimating()
            case .loading:
                self.iconView.tintColor = SpicyTheme.Palette.saffron
                self.primaryButton.isEnabled = false
                self.secondaryButton.isEnabled = false
                self.activityIndicator.startAnimating()
            case .success:
                self.iconView.tintColor = SpicyTheme.Palette.success
                self.primaryButton.isEnabled = true
                self.secondaryButton.isEnabled = true
                self.activityIndicator.stopAnimating()
            case .error:
                self.iconView.tintColor = SpicyTheme.Palette.error
                self.primaryButton.isEnabled = true
                self.secondaryButton.isEnabled = true
                self.activityIndicator.stopAnimating()
            case .disabled:
                self.iconView.tintColor = SpicyTheme.Palette.disabledText
                self.primaryButton.isEnabled = false
                self.secondaryButton.isEnabled = true
                self.activityIndicator.stopAnimating()
            }
        }

        guard animated else {
            changes()
            return
        }
        UIView.transition(
            with: self,
            duration: SpicyTheme.Animation.duration(SpicyTheme.Animation.standard),
            options: [.transitionCrossDissolve, .beginFromCurrentState],
            animations: changes
        )
    }

    @objc private func primaryTapped() { delegate?.spicyModalDidTapPrimary(self) }
    @objc private func secondaryTapped() { delegate?.spicyModalDidTapSecondary(self) }
    @objc private func closeTapped() { delegate?.spicyModalDidTapClose(self) }
}
