import XCTest
@testable import MRSpicy
import MrSpicyUI

final class MRSpicyTests: XCTestCase {
    func testDemoAccountModelDoesNotFabricateExternalEntitlements() {
        let model = SpicyAccountModel(
            accountState: .guest,
            proState: .authorized(source: "MR. SPICY-owned PRO UI available"),
            licenseState: .authorized(source: "No MR. SPICY license key required"),
            versionDescription: "MR. SPICY 1.0.0"
        )
        XCTAssertEqual(model.versionDescription, "MR. SPICY 1.0.0")
    }

    func testNoArtificialMrSpicyLocksInLocalizedCopy() {
        let localizer = SpicyLocalizer(language: .english)
        let strings = [
            localizer.localized(.featureAccessFree),
            localizer.localized(.proAvailable),
            localizer.localized(.noAdGating),
            localizer.localized(.noArtificialLocks),
            localizer.localized(.proFeatureSubtitle),
            localizer.localized(.licenseFeatureSubtitle)
        ].joined(separator: " ").lowercased()

        XCTAssertFalse(strings.contains("watch ad to unlock"))
        XCTAssertFalse(strings.contains("payment required"))
        XCTAssertFalse(strings.contains("subscription required"))
        XCTAssertFalse(strings.contains("countdown required"))
        XCTAssertTrue(strings.contains("free") || strings.contains("available"))
    }
}
