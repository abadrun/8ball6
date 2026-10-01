import XCTest
@testable import MrSpicyUI

final class MrSpicyUITests: XCTestCase {
    func testLocalizationKeyParity() {
        let english = Set(SpicyLocalizer.translations[.english]?.keys.map { $0 } ?? [])
        let arabic = Set(SpicyLocalizer.translations[.arabic]?.keys.map { $0 } ?? [])
        XCTAssertFalse(english.isEmpty)
        XCTAssertEqual(english, arabic)
    }

    func testArabicUsesRightToLeftSemantics() {
        XCTAssertEqual(SpicyLanguage.arabic.layoutDirection, .rightToLeft)
        XCTAssertEqual(SpicyLanguage.arabic.semanticContentAttribute, .forceRightToLeft)
    }

    func testRequiredOverlayStatesExist() {
        let states = Set(SpicyOverlayState.allCases)
        XCTAssertTrue(states.isSuperset(of: [.closed, .minimized, .expanded, .modal, .settings, .account, .language, .help, .about, .loading, .error, .success]))
    }

    func testMrSpicyOwnedFeaturesAreDescribedAsFreeAndAdFree() {
        let localizer = SpicyLocalizer(language: .english)
        XCTAssertTrue(localizer.localized(.featureAccessFree).localizedCaseInsensitiveContains("free"))
        XCTAssertTrue(localizer.localized(.proAvailable).localizedCaseInsensitiveContains("available"))
        XCTAssertTrue(localizer.localized(.noAdGating).localizedCaseInsensitiveContains("No MR. SPICY feature"))
        XCTAssertFalse(localizer.localized(.proFeatureSubtitle).localizedCaseInsensitiveContains("payment required"))
        XCTAssertFalse(localizer.localized(.proFeatureSubtitle).localizedCaseInsensitiveContains("watch ad"))
    }
}
