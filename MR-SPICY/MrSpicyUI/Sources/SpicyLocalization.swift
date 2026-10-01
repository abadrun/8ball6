import UIKit

public enum SpicyLanguage: String, CaseIterable, Codable {
    case english = "en"
    case arabic = "ar"

    public var displayName: String {
        switch self {
        case .english: return "English"
        case .arabic: return "العربية"
        }
    }

    public var locale: Locale { Locale(identifier: rawValue) }

    public var layoutDirection: UIUserInterfaceLayoutDirection {
        switch self {
        case .english: return .leftToRight
        case .arabic: return .rightToLeft
        }
    }

    public var semanticContentAttribute: UISemanticContentAttribute {
        switch self {
        case .english: return .forceLeftToRight
        case .arabic: return .forceRightToLeft
        }
    }
}

public enum SpicyLocalizationKey: String, CaseIterable, Codable {
    case appTitle
    case appSubtitle
    case statusReady
    case statusUnavailable
    case statusLoading
    case statusSuccess
    case statusError
    case close
    case minimize
    case settings
    case account
    case language
    case help
    case about
    case done
    case cancel
    case retry
    case loadingTitle
    case loadingDescription
    case successTitle
    case successDescription
    case errorTitle
    case errorDescription
    case disabledTitle
    case disabledDescription
    case appearance
    case animation
    case overlaySizing
    case accessibility
    case version
    case languageEnglish
    case languageArabic
    case languageDescription
    case accountTitle
    case accountSignedOut
    case accountGuest
    case accountUnavailable
    case proTitle
    case proUnknown
    case licenseTitle
    case licenseUnknown
    case automationTitle
    case automationSubtitle
    case queueTitle
    case queueSubtitle
    case proFeatureTitle
    case proFeatureSubtitle
    case licenseFeatureTitle
    case licenseFeatureSubtitle
    case settingsSubtitle
    case accountSubtitle
    case languageSubtitle
    case helpSubtitle
    case aboutSubtitle
    case accessibilityLabelLogo
    case accessibilityHintLogo
    case accessibilityHintClose
    case accessibilityHintMinimize
    case accessibilityHintSettings
    case accessibilityHintAccount
    case accessibilityHintLanguage
    case accessibilityReduceMotion
    case accessibilityDynamicType
    case truthfulStateNote
    case integrationPending
    case buildNotPerformed
    case signingNotPerformed
    case installationNotPerformed
    case featureAccessFree
    case proAvailable
    case noAdGating
    case noArtificialLocks
}

public final class SpicyLocalizer {
    public private(set) var language: SpicyLanguage

    public init(language: SpicyLanguage = .english) {
        self.language = language
    }

    public func setLanguage(_ language: SpicyLanguage) {
        self.language = language
    }

    public func localized(_ key: SpicyLocalizationKey) -> String {
        Self.translations[language]?[key] ?? Self.translations[.english]?[key] ?? key.rawValue
    }

    public func formattedNumber(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.locale = language.locale
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    public func applySemanticDirection(to view: UIView) {
        view.semanticContentAttribute = language.semanticContentAttribute
        for subview in view.subviews {
            applySemanticDirection(to: subview)
        }
    }

    public static let translations: [SpicyLanguage: [SpicyLocalizationKey: String]] = [
        .english: [
            .appTitle: "MR. SPICY",
            .appSubtitle: "Customization layer",
            .statusReady: "Ready",
            .statusUnavailable: "Unavailable",
            .statusLoading: "Loading",
            .statusSuccess: "Completed",
            .statusError: "Needs attention",
            .close: "Close",
            .minimize: "Minimize",
            .settings: "Settings",
            .account: "Account",
            .language: "Language",
            .help: "Help",
            .about: "About",
            .done: "Done",
            .cancel: "Cancel",
            .retry: "Retry",
            .loadingTitle: "Preparing MR. SPICY",
            .loadingDescription: "The customization interface is preparing legitimate UI state.",
            .successTitle: "Action completed",
            .successDescription: "The requested UI action finished successfully.",
            .errorTitle: "Action unavailable",
            .errorDescription: "This action requires a legitimate host integration or authorization that is not currently available.",
            .disabledTitle: "Feature disabled",
            .disabledDescription: "This control is visual-only until a valid integration supplies real state.",
            .appearance: "Appearance",
            .animation: "Animation",
            .overlaySizing: "Overlay sizing",
            .accessibility: "Accessibility",
            .version: "Version",
            .languageEnglish: "English",
            .languageArabic: "Arabic",
            .languageDescription: "Choose the interface language. Arabic uses true right-to-left layout.",
            .accountTitle: "Account and license",
            .accountSignedOut: "No account data is connected.",
            .accountGuest: "Guest mode. No paid entitlement is assumed.",
            .accountUnavailable: "Account state is unavailable from the current environment.",
            .proTitle: "PRO status",
            .proUnknown: "MR. SPICY PRO is available for MR. SPICY-owned UI. No external entitlement is assumed.",
            .licenseTitle: "License",
            .licenseUnknown: "No MR. SPICY license key is required. External host license state is not assumed.",
            .automationTitle: "Automation",
            .automationSubtitle: "Opens directly as MR. SPICY UI; no gameplay automation is implemented.",
            .queueTitle: "Queue",
            .queueSubtitle: "Local presentation state only.",
            .proFeatureTitle: "PRO",
            .proFeatureSubtitle: "Available. No payment, ad, countdown, subscription, or license key is required for MR. SPICY PRO UI.",
            .licenseFeatureTitle: "License",
            .licenseFeatureSubtitle: "MR. SPICY-owned features do not require a license key; external host state is not fabricated.",
            .settingsSubtitle: "Language, appearance, accessibility",
            .accountSubtitle: "Truthful account and entitlement state",
            .languageSubtitle: "English and Arabic RTL",
            .helpSubtitle: "Usage and limitations",
            .aboutSubtitle: "Version and build status",
            .accessibilityLabelLogo: "MR. SPICY logo",
            .accessibilityHintLogo: "Decorative branding for the customization interface.",
            .accessibilityHintClose: "Closes the MR. SPICY overlay.",
            .accessibilityHintMinimize: "Minimizes the overlay while keeping it available.",
            .accessibilityHintSettings: "Opens MR. SPICY settings.",
            .accessibilityHintAccount: "Shows truthful account and license information.",
            .accessibilityHintLanguage: "Opens language selection.",
            .accessibilityReduceMotion: "Reduce Motion is respected for overlay transitions.",
            .accessibilityDynamicType: "Text supports Dynamic Type where UIKit is available.",
            .truthfulStateNote: "MR. SPICY never fabricates account, PRO, license, signing, installation, or compatibility state.",
            .integrationPending: "Integration pending legitimate host build environment.",
            .buildNotPerformed: "Build not performed in the current environment.",
            .signingNotPerformed: "Signing not performed in the current environment.",
            .installationNotPerformed: "Installation test not performed.",
            .featureAccessFree: "MR. SPICY-owned features are free and open directly.",
            .proAvailable: "MR. SPICY PRO is available without artificial locks.",
            .noAdGating: "No MR. SPICY feature requires watching an advertisement.",
            .noArtificialLocks: "No MR. SPICY payment, subscription, license-key, trial, countdown, or ad unlock is added."
        ],
        .arabic: [
            .appTitle: "MR. SPICY",
            .appSubtitle: "طبقة تخصيص",
            .statusReady: "جاهز",
            .statusUnavailable: "غير متاح",
            .statusLoading: "جارٍ التحميل",
            .statusSuccess: "اكتمل",
            .statusError: "يتطلب الانتباه",
            .close: "إغلاق",
            .minimize: "تصغير",
            .settings: "الإعدادات",
            .account: "الحساب",
            .language: "اللغة",
            .help: "المساعدة",
            .about: "حول",
            .done: "تم",
            .cancel: "إلغاء",
            .retry: "إعادة المحاولة",
            .loadingTitle: "جارٍ تجهيز MR. SPICY",
            .loadingDescription: "يتم تجهيز واجهة التخصيص باستخدام حالة واجهة مشروعة.",
            .successTitle: "اكتمل الإجراء",
            .successDescription: "انتهى إجراء الواجهة المطلوب بنجاح.",
            .errorTitle: "الإجراء غير متاح",
            .errorDescription: "يتطلب هذا الإجراء تكاملاً مشروعاً مع المضيف أو تفويضاً غير متاح حالياً.",
            .disabledTitle: "الميزة معطلة",
            .disabledDescription: "هذا التحكم مرئي فقط حتى يوفّر تكامل صالح حالة حقيقية.",
            .appearance: "المظهر",
            .animation: "الحركة",
            .overlaySizing: "حجم الطبقة",
            .accessibility: "إمكانية الوصول",
            .version: "الإصدار",
            .languageEnglish: "الإنجليزية",
            .languageArabic: "العربية",
            .languageDescription: "اختر لغة الواجهة. تستخدم العربية تخطيطاً حقيقياً من اليمين إلى اليسار.",
            .accountTitle: "الحساب والترخيص",
            .accountSignedOut: "لا توجد بيانات حساب متصلة.",
            .accountGuest: "وضع ضيف. لا يتم افتراض أي استحقاق مدفوع.",
            .accountUnavailable: "حالة الحساب غير متاحة من البيئة الحالية.",
            .proTitle: "حالة PRO",
            .proUnknown: "واجهة MR. SPICY PRO متاحة لميزات MR. SPICY. لا يتم افتراض أي استحقاق خارجي.",
            .licenseTitle: "الترخيص",
            .licenseUnknown: "لا تتطلب ميزات MR. SPICY مفتاح ترخيص. لا يتم افتراض حالة ترخيص خارجية.",
            .automationTitle: "الأتمتة",
            .automationSubtitle: "تفتح مباشرة كواجهة MR. SPICY؛ لا توجد أتمتة للّعب.",
            .queueTitle: "قائمة الانتظار",
            .queueSubtitle: "حالة عرض محلية فقط.",
            .proFeatureTitle: "PRO",
            .proFeatureSubtitle: "متاح. لا يلزم دفع أو إعلان أو عدّ تنازلي أو اشتراك أو مفتاح ترخيص لواجهة MR. SPICY PRO.",
            .licenseFeatureTitle: "الترخيص",
            .licenseFeatureSubtitle: "لا تتطلب ميزات MR. SPICY مفتاح ترخيص؛ ولا يتم اختلاق حالة المضيف الخارجية.",
            .settingsSubtitle: "اللغة والمظهر وإمكانية الوصول",
            .accountSubtitle: "حالة حساب واستحقاق صادقة",
            .languageSubtitle: "الإنجليزية والعربية RTL",
            .helpSubtitle: "الاستخدام والقيود",
            .aboutSubtitle: "الإصدار وحالة البناء",
            .accessibilityLabelLogo: "شعار MR. SPICY",
            .accessibilityHintLogo: "علامة مرئية لواجهة التخصيص.",
            .accessibilityHintClose: "يغلق طبقة MR. SPICY.",
            .accessibilityHintMinimize: "يصغّر الطبقة مع إبقائها متاحة.",
            .accessibilityHintSettings: "يفتح إعدادات MR. SPICY.",
            .accessibilityHintAccount: "يعرض معلومات الحساب والترخيص بصدق.",
            .accessibilityHintLanguage: "يفتح اختيار اللغة.",
            .accessibilityReduceMotion: "يتم احترام خيار تقليل الحركة في انتقالات الطبقة.",
            .accessibilityDynamicType: "يدعم النص Dynamic Type عند توفر UIKit.",
            .truthfulStateNote: "لا يختلق MR. SPICY حالة الحساب أو PRO أو الترخيص أو التوقيع أو التثبيت أو التوافق.",
            .integrationPending: "التكامل ينتظر بيئة بناء مضيف مشروعة.",
            .buildNotPerformed: "لم يتم البناء في البيئة الحالية.",
            .signingNotPerformed: "لم يتم التوقيع في البيئة الحالية.",
            .installationNotPerformed: "لم يتم اختبار التثبيت.",
            .featureAccessFree: "ميزات MR. SPICY مملوكة له وهي مجانية وتفتح مباشرة.",
            .proAvailable: "واجهة MR. SPICY PRO متاحة بدون أقفال مصطنعة.",
            .noAdGating: "لا تتطلب أي ميزة من MR. SPICY مشاهدة إعلان.",
            .noArtificialLocks: "لا يضيف MR. SPICY دفعاً أو اشتراكاً أو مفتاح ترخيص أو تجربة مؤقتة أو عدّاً تنازلياً أو فتحاً بإعلان."
        ]
    ]
}
