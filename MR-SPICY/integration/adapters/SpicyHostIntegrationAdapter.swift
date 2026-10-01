import Foundation

/// Minimal source-level integration contract for an authorized host project.
///
/// This adapter deliberately exposes only truthful UI state. It does not patch
/// Mach-O binaries, bypass signing, manipulate gameplay, spoof entitlements,
/// bypass ads, bypass payments, or communicate fabricated server state.
public protocol SpicyHostIntegrationAdapter: AnyObject {
    var hostBundleIdentifier: String { get }
    var hostVersion: String { get }
    var hostBuild: String { get }

    func currentAccountState() -> SpicyHostAccountSnapshot
    func currentEntitlementState() -> SpicyHostEntitlementSnapshot
    func currentLicenseState() -> SpicyHostLicenseSnapshot
}

public struct SpicyHostAccountSnapshot: Codable, Equatable {
    public enum State: String, Codable { case unavailable, signedOut, guest, authorized, error }
    public var state: State
    public var displayName: String?
    public var reason: String?

    public init(state: State = .unavailable, displayName: String? = nil, reason: String? = nil) {
        self.state = state
        self.displayName = displayName
        self.reason = reason
    }
}

public struct SpicyHostEntitlementSnapshot: Codable, Equatable {
    public enum State: String, Codable { case unknown, inactive, authorized, expired, unavailable }
    public var state: State
    public var source: String?
    public var reason: String?

    public init(state: State = .unknown, source: String? = nil, reason: String? = nil) {
        self.state = state
        self.source = source
        self.reason = reason
    }
}

public typealias SpicyHostLicenseSnapshot = SpicyHostEntitlementSnapshot

public final class SpicyNoopHostIntegrationAdapter: SpicyHostIntegrationAdapter {
    public let hostBundleIdentifier: String
    public let hostVersion: String
    public let hostBuild: String

    public init(hostBundleIdentifier: String, hostVersion: String, hostBuild: String) {
        self.hostBundleIdentifier = hostBundleIdentifier
        self.hostVersion = hostVersion
        self.hostBuild = hostBuild
    }

    public func currentAccountState() -> SpicyHostAccountSnapshot {
        SpicyHostAccountSnapshot(state: .unavailable, reason: "No authorized host runtime bridge is connected.")
    }

    public func currentEntitlementState() -> SpicyHostEntitlementSnapshot {
        SpicyHostEntitlementSnapshot(state: .unknown, reason: "No entitlement verification result is available.")
    }

    public func currentLicenseState() -> SpicyHostLicenseSnapshot {
        SpicyHostLicenseSnapshot(state: .unknown, reason: "No license activation result is available.")
    }
}
