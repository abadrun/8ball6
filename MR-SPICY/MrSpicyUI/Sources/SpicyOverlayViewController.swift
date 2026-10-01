import UIKit

public enum SpicyOverlayState: String, CaseIterable, Codable {
    case closed
    case minimized
    case expanded
    case modal
    case settings
    case account
    case language
    case help
    case about
    case disabled
    case loading
    case error
    case success
}

public struct SpicyOverlayViewModel: Equatable, Codable {
    public var state: SpicyOverlayState
    public var language: SpicyLanguage
    public var accountModel: SpicyAccountModel
    public var featureStates: [SpicyFeatureCategory: SpicyFeaturePresentationState]
    public var statusTone: SpicyStatusTone

    public init(
        state: SpicyOverlayState = .closed,
        language: SpicyLanguage = .english,
        accountModel: SpicyAccountModel = SpicyAccountModel(),
        featureStates: [SpicyFeatureCategory: SpicyFeaturePresentationState] = [:],
        statusTone: SpicyStatusTone = .neutral
    ) {
        self.state = state
        self.language = language
        self.accountModel = accountModel
        self.featureStates = featureStates
        self.statusTone = statusTone
    }
}

public protocol SpicyOverlayViewControllerDelegate: AnyObject {
    func spicyOverlay(_ overlay: SpicyOverlayViewController, didChangeState state: SpicyOverlayState)
    func spicyOverlay(_ overlay: SpicyOverlayViewController, didChangeLanguage language: SpicyLanguage)
    func spicyOverlay(_ overlay: SpicyOverlayViewController, didRequestFeature category: SpicyFeatureCategory)
}

/// Root MR. SPICY overlay controller.
///
/// This controller implements reusable presentation, localization, RTL,
/// accessibility, and state management only. It intentionally does not patch or
/// modify compiled host code and does not implement gameplay automation,
/// entitlement spoofing, payment bypass, ad bypass, or anti-cheat evasion.
public final class SpicyOverlayViewController: UIViewController {
    public weak var delegate: SpicyOverlayViewControllerDelegate?

    public private(set) var viewModel: SpicyOverlayViewModel {
        didSet { render(animated: true) }
    }

    private let localizer: SpicyLocalizer
    private let scrimView = UIControl()
    private let panelView = UIView()
    private let headerView = SpicyHeaderView()
    private let contentContainer = UIView()
    private let featureGrid = UIStackView()
    private let firstFeatureRow = UIStackView()
    private let secondFeatureRow = UIStackView()
    private let accountView = SpicyAccountView()
    private let settingsView = SpicySettingsView()
    private var modalView: SpicyModalView?
    private var featureControls: [SpicyFeatureCategory: SpicyFeatureCircle] = [:]
    private var panelWidthConstraint: NSLayoutConstraint?
    private var panelHeightConstraint: NSLayoutConstraint?
    private var panelBottomConstraint: NSLayoutConstraint?
    private var panelCenterYConstraint: NSLayoutConstraint?

    private let featureDescriptors: [SpicyFeatureDescriptor] = [
        SpicyFeatureDescriptor(category: .automation, titleKey: .automationTitle, subtitleKey: .automationSubtitle, systemImageName: "slider.horizontal.3"),
        SpicyFeatureDescriptor(category: .queue, titleKey: .queueTitle, subtitleKey: .queueSubtitle, systemImageName: "list.bullet.rectangle"),
        SpicyFeatureDescriptor(category: .account, titleKey: .account, subtitleKey: .accountSubtitle, systemImageName: "person.crop.circle"),
        SpicyFeatureDescriptor(category: .pro, titleKey: .proFeatureTitle, subtitleKey: .proFeatureSubtitle, systemImageName: "star.circle"),
        SpicyFeatureDescriptor(category: .license, titleKey: .licenseFeatureTitle, subtitleKey: .licenseFeatureSubtitle, systemImageName: "checkmark.seal"),
        SpicyFeatureDescriptor(category: .settings, titleKey: .settings, subtitleKey: .settingsSubtitle, systemImageName: "gearshape"),
        SpicyFeatureDescriptor(category: .language, titleKey: .language, subtitleKey: .languageSubtitle, systemImageName: "globe"),
        SpicyFeatureDescriptor(category: .help, titleKey: .help, subtitleKey: .helpSubtitle, systemImageName: "questionmark.circle"),
        SpicyFeatureDescriptor(category: .about, titleKey: .about, subtitleKey: .aboutSubtitle, systemImageName: "info.circle")
    ]

    public init(viewModel: SpicyOverlayViewModel = SpicyOverlayViewModel()) {
        self.viewModel = viewModel
        self.localizer = SpicyLocalizer(language: viewModel.language)
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
    }

    public required init?(coder: NSCoder) {
        self.viewModel = SpicyOverlayViewModel()
        self.localizer = SpicyLocalizer()
        super.init(coder: coder)
        modalPresentationStyle = .overFullScreen
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
        render(animated: false)
    }

    public override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        updatePanelSizing(animated: false)
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updatePanelSizing(animated: false)
    }

    public func transition(to state: SpicyOverlayState, animated: Bool = true) {
        viewModel.state = state
        render(animated: animated)
        delegate?.spicyOverlay(self, didChangeState: state)
    }

    public func updateAccountModel(_ accountModel: SpicyAccountModel) {
        viewModel.accountModel = accountModel
    }

    public func updateFeatureState(_ state: SpicyFeaturePresentationState, for category: SpicyFeatureCategory) {
        viewModel.featureStates[category] = state
    }

    public func setLanguage(_ language: SpicyLanguage) {
        viewModel.language = language
        localizer.setLanguage(language)
        delegate?.spicyOverlay(self, didChangeLanguage: language)
    }

    private func setupLayout() {
        view.backgroundColor = UIColor.clear
        view.semanticContentAttribute = localizer.language.semanticContentAttribute

        scrimView.translatesAutoresizingMaskIntoConstraints = false
        scrimView.backgroundColor = SpicyTheme.Palette.overlayScrim
        scrimView.alpha = 0
        scrimView.addTarget(self, action: #selector(scrimTapped), for: .touchUpInside)

        panelView.translatesAutoresizingMaskIntoConstraints = false
        SpicyTheme.applyCardStyle(to: panelView, radius: SpicyTheme.CornerRadius.large)
        panelView.backgroundColor = SpicyTheme.Palette.background.withAlphaComponent(SpicyTheme.Overlay.opacity)

        headerView.delegate = self
        settingsView.delegate = self

        contentContainer.translatesAutoresizingMaskIntoConstraints = false
        featureGrid.translatesAutoresizingMaskIntoConstraints = false
        featureGrid.axis = .vertical
        featureGrid.alignment = .fill
        featureGrid.distribution = .fillEqually
        featureGrid.spacing = SpicyTheme.Spacing.md

        [firstFeatureRow, secondFeatureRow].forEach { row in
            row.axis = .horizontal
            row.alignment = .fill
            row.distribution = .fillEqually
            row.spacing = SpicyTheme.Spacing.md
            featureGrid.addArrangedSubview(row)
        }

        view.addSubview(scrimView)
        view.addSubview(panelView)
        panelView.addSubview(headerView)
        panelView.addSubview(contentContainer)
        contentContainer.addSubview(featureGrid)

        buildFeatureControls()

        panelWidthConstraint = panelView.widthAnchor.constraint(lessThanOrEqualToConstant: SpicyTheme.Overlay.maxWidth)
        panelHeightConstraint = panelView.heightAnchor.constraint(greaterThanOrEqualToConstant: 220)
        panelBottomConstraint = panelView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -SpicyTheme.Spacing.lg)
        panelCenterYConstraint = panelView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        panelCenterYConstraint?.priority = .defaultLow

        NSLayoutConstraint.activate([
            scrimView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrimView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrimView.topAnchor.constraint(equalTo: view.topAnchor),
            scrimView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            panelView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            panelView.leadingAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.leadingAnchor, constant: SpicyTheme.Spacing.md),
            panelView.trailingAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -SpicyTheme.Spacing.md),
            panelWidthConstraint!,
            panelHeightConstraint!,
            panelBottomConstraint!,
            panelCenterYConstraint!,
            headerView.leadingAnchor.constraint(equalTo: panelView.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: panelView.trailingAnchor),
            headerView.topAnchor.constraint(equalTo: panelView.topAnchor),
            contentContainer.leadingAnchor.constraint(equalTo: panelView.leadingAnchor, constant: SpicyTheme.Spacing.lg),
            contentContainer.trailingAnchor.constraint(equalTo: panelView.trailingAnchor, constant: -SpicyTheme.Spacing.lg),
            contentContainer.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: SpicyTheme.Spacing.md),
            contentContainer.bottomAnchor.constraint(equalTo: panelView.bottomAnchor, constant: -SpicyTheme.Spacing.lg),
            featureGrid.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            featureGrid.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
            featureGrid.topAnchor.constraint(equalTo: contentContainer.topAnchor),
            featureGrid.bottomAnchor.constraint(lessThanOrEqualTo: contentContainer.bottomAnchor)
        ])
    }

    private func buildFeatureControls() {
        featureControls.removeAll()
        firstFeatureRow.arrangedSubviews.forEach { $0.removeFromSuperview() }
        secondFeatureRow.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for (index, descriptor) in featureDescriptors.enumerated() {
            let control = SpicyFeatureCircle()
            control.addTarget(self, action: #selector(featureTapped(_:)), for: .touchUpInside)
            control.tag = index
            let defaultState = SpicyFeaturePresentationState(
                isSelected: false,
                isActive: descriptor.isImplementedByDefault,
                isDisabled: !descriptor.isImplementedByDefault,
                statusTone: descriptor.isImplementedByDefault ? .neutral : .warning
            )
            control.configure(
                descriptor: descriptor,
                state: viewModel.featureStates[descriptor.category] ?? defaultState,
                localizer: localizer
            )
            featureControls[descriptor.category] = control
            (index < 5 ? firstFeatureRow : secondFeatureRow).addArrangedSubview(control)
        }
    }

    private func render(animated: Bool) {
        localizer.setLanguage(viewModel.language)
        view.semanticContentAttribute = localizer.language.semanticContentAttribute
        headerView.configure(
            localizer: localizer,
            configuration: SpicyHeaderConfiguration(
                subtitle: .appSubtitle,
                statusText: statusTextKey(for: viewModel.state),
                statusTone: tone(for: viewModel.state),
                showsClose: true,
                showsMinimize: viewModel.state != .minimized,
                showsSettings: true,
                showsAccount: true,
                showsLanguage: true
            )
        )
        buildFeatureControls()
        updateContent(for: viewModel.state)
        updatePanelSizing(animated: animated)
        applyVisibility(animated: animated)
        localizer.applySemanticDirection(to: view)
    }

    private func updateContent(for state: SpicyOverlayState) {
        removeAllContentExceptFeatureGrid()
        modalView?.removeFromSuperview()
        modalView = nil

        switch state {
        case .settings:
            settingsView.configure(localizer: localizer)
            embedContent(settingsView)
        case .account:
            accountView.configure(model: viewModel.accountModel, localizer: localizer)
            embedContent(accountView)
        case .language:
            presentInformationalModal(title: .language, icon: "globe", description: .languageDescription, state: .normal)
        case .help:
            presentInformationalModal(title: .help, icon: "questionmark.circle", description: .truthfulStateNote, state: .normal)
        case .about:
            presentInformationalModal(title: .about, icon: "info.circle", description: .integrationPending, state: .normal)
        case .loading:
            presentInformationalModal(title: .loadingTitle, icon: "hourglass", description: .loadingDescription, state: .loading)
        case .error:
            presentInformationalModal(title: .errorTitle, icon: "exclamationmark.triangle", description: .errorDescription, state: .error)
        case .success:
            presentInformationalModal(title: .successTitle, icon: "checkmark.circle", description: .successDescription, state: .success)
        case .disabled:
            presentInformationalModal(title: .disabledTitle, icon: "nosign", description: .disabledDescription, state: .disabled)
        case .closed, .minimized, .expanded, .modal:
            featureGrid.isHidden = state == .minimized || state == .closed
        }
    }

    private func removeAllContentExceptFeatureGrid() {
        contentContainer.subviews.forEach { subview in
            if subview !== featureGrid { subview.removeFromSuperview() }
        }
        if featureGrid.superview == nil { contentContainer.addSubview(featureGrid) }
        featureGrid.isHidden = false
        featureGrid.translatesAutoresizingMaskIntoConstraints = false
        if featureGrid.constraints.isEmpty {
            NSLayoutConstraint.activate([
                featureGrid.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
                featureGrid.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
                featureGrid.topAnchor.constraint(equalTo: contentContainer.topAnchor),
                featureGrid.bottomAnchor.constraint(lessThanOrEqualTo: contentContainer.bottomAnchor)
            ])
        }
    }

    private func embedContent(_ content: UIView) {
        featureGrid.isHidden = true
        content.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.addSubview(content)
        NSLayoutConstraint.activate([
            content.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
            content.topAnchor.constraint(equalTo: contentContainer.topAnchor),
            content.bottomAnchor.constraint(lessThanOrEqualTo: contentContainer.bottomAnchor)
        ])
    }

    private func presentInformationalModal(
        title: SpicyLocalizationKey,
        icon: String,
        description: SpicyLocalizationKey,
        state: SpicyModalState
    ) {
        featureGrid.isHidden = true
        let modal = SpicyModalView()
        modal.delegate = self
        modal.configure(
            SpicyModalConfiguration(
                titleKey: title,
                iconSystemName: icon,
                descriptionKey: description,
                primaryActionKey: .done,
                secondaryActionKey: nil,
                state: state
            ),
            localizer: localizer
        )
        contentContainer.addSubview(modal)
        NSLayoutConstraint.activate([
            modal.leadingAnchor.constraint(greaterThanOrEqualTo: contentContainer.leadingAnchor),
            modal.trailingAnchor.constraint(lessThanOrEqualTo: contentContainer.trailingAnchor),
            modal.centerXAnchor.constraint(equalTo: contentContainer.centerXAnchor),
            modal.topAnchor.constraint(equalTo: contentContainer.topAnchor),
            modal.bottomAnchor.constraint(lessThanOrEqualTo: contentContainer.bottomAnchor)
        ])
        modalView = modal
    }

    private func updatePanelSizing(animated: Bool) {
        let isCompact = traitCollection.horizontalSizeClass == .compact || view.bounds.width < 430
        let landscape = view.bounds.width > view.bounds.height
        panelWidthConstraint?.constant = viewModel.state == .minimized ? SpicyTheme.Overlay.minimizedWidth : (isCompact ? SpicyTheme.Overlay.compactMaxWidth : SpicyTheme.Overlay.maxWidth)
        panelHeightConstraint?.constant = viewModel.state == .minimized ? SpicyTheme.Overlay.minimizedHeight : (landscape ? 220 : 360)
        panelBottomConstraint?.constant = landscape ? -SpicyTheme.Spacing.sm : -SpicyTheme.Spacing.lg

        let changes = { self.view.layoutIfNeeded() }
        if animated {
            UIView.animate(
                withDuration: SpicyTheme.Animation.duration(SpicyTheme.Animation.standard),
                delay: 0,
                usingSpringWithDamping: SpicyTheme.Animation.damping,
                initialSpringVelocity: SpicyTheme.Animation.initialVelocity,
                options: [.beginFromCurrentState, .allowUserInteraction],
                animations: changes
            )
        } else {
            changes()
        }
    }

    private func applyVisibility(animated: Bool) {
        let isClosed = viewModel.state == .closed
        let isMinimized = viewModel.state == .minimized
        let changes = {
            self.scrimView.alpha = isClosed || isMinimized ? 0 : 1
            self.panelView.alpha = isClosed ? 0 : 1
            self.headerView.alpha = isClosed ? 0 : 1
            self.contentContainer.alpha = isMinimized ? 0 : 1
            self.panelView.transform = isClosed ? CGAffineTransform(scaleX: 0.92, y: 0.92) : .identity
        }
        if animated {
            UIView.animate(
                withDuration: SpicyTheme.Animation.duration(SpicyTheme.Animation.standard),
                delay: 0,
                options: [.beginFromCurrentState, .allowUserInteraction],
                animations: changes
            )
        } else {
            changes()
        }
        view.accessibilityElementsHidden = isClosed
    }

    private func statusTextKey(for state: SpicyOverlayState) -> SpicyLocalizationKey {
        switch state {
        case .loading: return .statusLoading
        case .success: return .statusSuccess
        case .error: return .statusError
        case .disabled: return .statusUnavailable
        case .closed: return .statusUnavailable
        default: return .statusReady
        }
    }

    private func tone(for state: SpicyOverlayState) -> SpicyStatusTone {
        switch state {
        case .loading: return .active
        case .success: return .success
        case .error: return .error
        case .disabled: return .warning
        case .closed: return .neutral
        default: return viewModel.statusTone
        }
    }

    @objc private func scrimTapped() { transition(to: .minimized) }

    @objc private func featureTapped(_ sender: SpicyFeatureCircle) {
        guard sender.tag >= 0, sender.tag < featureDescriptors.count else { return }
        let category = featureDescriptors[sender.tag].category
        delegate?.spicyOverlay(self, didRequestFeature: category)
        switch category {
        case .settings: transition(to: .settings)
        case .account: transition(to: .account)
        case .language: transition(to: .language)
        case .help: transition(to: .help)
        case .about: transition(to: .about)
        case .automation:
            transition(to: .modal)
            presentInformationalModal(title: .automationTitle, icon: "slider.horizontal.3", description: .automationSubtitle, state: .normal)
        case .pro:
            transition(to: .modal)
            presentInformationalModal(title: .proFeatureTitle, icon: "star.circle", description: .proFeatureSubtitle, state: .success)
        case .license:
            transition(to: .modal)
            presentInformationalModal(title: .licenseFeatureTitle, icon: "checkmark.seal", description: .licenseFeatureSubtitle, state: .success)
        case .queue:
            transition(to: .modal)
            presentInformationalModal(title: .queueTitle, icon: "list.bullet.rectangle", description: .queueSubtitle, state: .normal)
        }
    }
}

extension SpicyOverlayViewController: SpicyHeaderViewDelegate {
    public func spicyHeaderDidTapClose(_ header: SpicyHeaderView) { transition(to: .closed) }
    public func spicyHeaderDidTapMinimize(_ header: SpicyHeaderView) { transition(to: .minimized) }
    public func spicyHeaderDidTapSettings(_ header: SpicyHeaderView) { transition(to: .settings) }
    public func spicyHeaderDidTapAccount(_ header: SpicyHeaderView) { transition(to: .account) }
    public func spicyHeaderDidTapLanguage(_ header: SpicyHeaderView) { transition(to: .language) }
}

extension SpicyOverlayViewController: SpicySettingsViewDelegate {
    public func spicySettingsView(_ view: SpicySettingsView, didSelect kind: SpicySettingKind) {
        switch kind {
        case .language: transition(to: .language)
        case .account: transition(to: .account)
        case .help: transition(to: .help)
        case .about, .version: transition(to: .about)
        case .appearance, .animation, .overlaySizing, .accessibility:
            transition(to: .modal)
            presentInformationalModal(title: kind.titleKey, icon: kind.iconName, description: .integrationPending, state: .normal)
        }
    }
}

extension SpicyOverlayViewController: SpicyModalViewDelegate {
    public func spicyModalDidTapPrimary(_ modal: SpicyModalView) {
        if viewModel.state == .language {
            setLanguage(viewModel.language == .english ? .arabic : .english)
            transition(to: .expanded)
        } else {
            transition(to: .expanded)
        }
    }

    public func spicyModalDidTapSecondary(_ modal: SpicyModalView) { transition(to: .expanded) }
    public func spicyModalDidTapClose(_ modal: SpicyModalView) { transition(to: .expanded) }
}
