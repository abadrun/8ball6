import UIKit
import MrSpicyUI

/// Standalone Xcode demo shell for the MR. SPICY source layer.
///
/// This app is not the original host and is not a final IPA release. It exists
/// so a developer can open `MRSpicy.xcodeproj`, build a clean iOS application
/// target, exercise the reusable MR. SPICY UI, and continue legitimate host
/// integration in an authorized Apple environment.
final class MRSpicyRootViewController: UIViewController {
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let openButton = UIButton(type: .system)
    private let stackView = UIStackView()
    private var overlayController: SpicyOverlayViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = SpicyTheme.Palette.background
        configureText()
        configureLayout()
        presentOverlay(initialState: .expanded)
    }

    private func configureText() {
        titleLabel.text = "MR. SPICY"
        titleLabel.font = SpicyTheme.Typography.title
        titleLabel.textColor = SpicyTheme.Palette.textPrimary
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0

        descriptionLabel.text = "Xcode-ready MR. SPICY demo shell. MR. SPICY-owned features are free, ad-free, and open directly. Host entitlements are not bypassed."
        descriptionLabel.font = SpicyTheme.Typography.body
        descriptionLabel.textColor = SpicyTheme.Palette.textSecondary
        descriptionLabel.adjustsFontForContentSizeCategory = true
        descriptionLabel.textAlignment = .center
        descriptionLabel.numberOfLines = 0

        openButton.setTitle("Open MR. SPICY", for: .normal)
        SpicyTheme.applyPrimaryButtonStyle(to: openButton)
        openButton.addTarget(self, action: #selector(openTapped), for: .touchUpInside)
        openButton.accessibilityLabel = "Open MR. SPICY"
        openButton.accessibilityHint = "Opens the MR. SPICY overlay demo."
    }

    private func configureLayout() {
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = SpicyTheme.Spacing.lg
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(descriptionLabel)
        stackView.addArrangedSubview(openButton)
        view.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.leadingAnchor, constant: SpicyTheme.Spacing.xl),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -SpicyTheme.Spacing.xl),
            stackView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            descriptionLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 520)
        ])
    }

    @objc private func openTapped() {
        if overlayController == nil {
            presentOverlay(initialState: .expanded)
        } else {
            overlayController?.transition(to: .expanded)
        }
    }

    private func presentOverlay(initialState: SpicyOverlayState) {
        let model = SpicyOverlayViewModel(
            state: initialState,
            language: .english,
            accountModel: SpicyAccountModel(
                accountState: .guest,
                proState: .authorized(source: "MR. SPICY-owned PRO UI available"),
                licenseState: .authorized(source: "No MR. SPICY license key required"),
                versionDescription: "MR. SPICY 1.0.0"
            ),
            statusTone: .success
        )
        let overlay = SpicyOverlayViewController(viewModel: model)
        overlay.delegate = self
        addChild(overlay)
        overlay.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(overlay.view)
        NSLayoutConstraint.activate([
            overlay.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlay.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlay.view.topAnchor.constraint(equalTo: view.topAnchor),
            overlay.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        overlay.didMove(toParent: self)
        overlayController = overlay
    }
}

extension MRSpicyRootViewController: SpicyOverlayViewControllerDelegate {
    func spicyOverlay(_ overlay: SpicyOverlayViewController, didChangeState state: SpicyOverlayState) {
        if state == .closed {
            overlay.willMove(toParent: nil)
            overlay.view.removeFromSuperview()
            overlay.removeFromParent()
            overlayController = nil
        }
    }

    func spicyOverlay(_ overlay: SpicyOverlayViewController, didChangeLanguage language: SpicyLanguage) {}
    func spicyOverlay(_ overlay: SpicyOverlayViewController, didRequestFeature category: SpicyFeatureCategory) {}
}
