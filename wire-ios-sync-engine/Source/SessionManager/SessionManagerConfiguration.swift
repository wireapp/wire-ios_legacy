//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
//

import UIKit

/// SessionManagerConfiguration is configuration class which can be used when initializing a SessionManager configure
/// change the default behaviour.

@objcMembers
public class SessionManagerConfiguration: NSObject, NSCopying, Codable {

    // MARK: - Properties

    /// If set to true then the session manager will delete account data instead of just asking the user to re-authenticate when the cookie or client gets invalidated.
    ///
    /// The default value of this property is `false`.
    public var wipeOnCookieInvalid: Bool

    /// The `blacklistDownloadInterval` configures at which rate we update the client blacklist
    ///
    /// The default value of this property is `6 hours`
    public var blacklistDownloadInterval: TimeInterval

    /// The `blockOnJailbreakOrRoot` configures if app should lock when the device is jailbroken
    ///
    /// The default value of this property is `false`
    public var blockOnJailbreakOrRoot: Bool

    /// If set to true then the session manager will delete account data on a jailbroken device.
    ///
    /// The default value of this property is `false`
    public var wipeOnJailbreakOrRoot: Bool

    /// `The messageRetentionInterval` if specified will limit how long messages are retained. Messages older than
    /// the the `messageRetentionInterval` will be deleted.
    ///
    /// The default value of this property is `nil`, i.e. messages are kept forever.
    public var messageRetentionInterval: TimeInterval?

    /// If set to true then the session manager will ask to re-authenticate after device reboot.
    ///
    /// The default value of this property is `false`
    public var authenticateAfterReboot: Bool

    /// The `failedPasswordThresholdBeforeWipe` configures the limit of failed password attempts before
    /// which the session manager will delete account data.
    ///
    /// The default value of this property is `nil`, i.e. threshold is ignored
    public var failedPasswordThresholdBeforeWipe: Int?

    /// The `encryptionAtRestEnabledByDefault` configures if the encryption at rest will be enabled by default for all sessions.
    ///
    /// The default value of this property is `false`
    public var encryptionAtRestEnabledByDefault: Bool

    /// Configuration for the app lock feature.
    ///
    /// This is a legacy config, the preferred way is to use the feature config fetched
    /// from the backend. If this is present, only this config will be used.

    public var legacyAppLockConfig: AppLockController.LegacyConfig?

    // MARK: - Init

    public init(
        wipeOnCookieInvalid: Bool = false,
        blacklistDownloadInterval: TimeInterval = 6 * 60 * 60,
        blockOnJailbreakOrRoot: Bool = false,
        wipeOnJailbreakOrRoot: Bool = false,
        messageRetentionInterval: TimeInterval? = nil,
        authenticateAfterReboot: Bool = false,
        failedPasswordThresholdBeforeWipe: Int? = nil,
        encryptionAtRestIsEnabledByDefault: Bool = false,
        legacyAppLockConfig: AppLockController.LegacyConfig? = nil
    ) {
        self.wipeOnCookieInvalid = wipeOnCookieInvalid
        self.blacklistDownloadInterval = blacklistDownloadInterval
        self.blockOnJailbreakOrRoot = blockOnJailbreakOrRoot
        self.wipeOnJailbreakOrRoot = wipeOnJailbreakOrRoot
        self.messageRetentionInterval = messageRetentionInterval
        self.authenticateAfterReboot = authenticateAfterReboot
        self.failedPasswordThresholdBeforeWipe = failedPasswordThresholdBeforeWipe
        self.encryptionAtRestEnabledByDefault = encryptionAtRestIsEnabledByDefault
        self.legacyAppLockConfig = legacyAppLockConfig
    }

    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        wipeOnCookieInvalid = try container.decode(Bool.self, forKey: .wipeOnCookieInvalid)
        blacklistDownloadInterval = try container.decode(TimeInterval.self, forKey: .blacklistDownloadInterval)
        blockOnJailbreakOrRoot = try container.decode(Bool.self, forKey: .blockOnJailbreakOrRoot)
        wipeOnJailbreakOrRoot = try container.decode(Bool.self, forKey: .wipeOnJailbreakOrRoot)
        messageRetentionInterval = try container.decodeIfPresent(TimeInterval.self, forKey: .messageRetentionInterval)
        authenticateAfterReboot = try container.decode(Bool.self, forKey: .authenticateAfterReboot)
        failedPasswordThresholdBeforeWipe = try container.decodeIfPresent(Int.self, forKey: .failedPasswordThresholdBeforeWipe)
        encryptionAtRestEnabledByDefault = try container.decode(Bool.self, forKey: .encryptionAtRestEnabledByDefault)
        legacyAppLockConfig = try container.decodeIfPresent(AppLockController.LegacyConfig.self, forKey: .legacyAppLockConfig)
    }

    // MARK: - Methods

    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = SessionManagerConfiguration(
            wipeOnCookieInvalid: wipeOnCookieInvalid,
            blacklistDownloadInterval: blacklistDownloadInterval,
            blockOnJailbreakOrRoot: blockOnJailbreakOrRoot,
            wipeOnJailbreakOrRoot: wipeOnJailbreakOrRoot,
            messageRetentionInterval: messageRetentionInterval,
            authenticateAfterReboot: authenticateAfterReboot,
            failedPasswordThresholdBeforeWipe: failedPasswordThresholdBeforeWipe,
            encryptionAtRestIsEnabledByDefault: encryptionAtRestEnabledByDefault,
            legacyAppLockConfig: legacyAppLockConfig
        )

        return copy
    }

    public static var defaultConfiguration: SessionManagerConfiguration {
        return SessionManagerConfiguration()
    }

    public static func load(from URL: URL) -> SessionManagerConfiguration? {
        guard let data = try? Data(contentsOf: URL) else { return nil }

        let decoder = JSONDecoder()

        return  try? decoder.decode(SessionManagerConfiguration.self, from: data)
    }
}

// MARK: - Coding Key

extension SessionManagerConfiguration {

    enum CodingKeys: String, CodingKey {

        case wipeOnCookieInvalid
        case blacklistDownloadInterval
        case blockOnJailbreakOrRoot
        case wipeOnJailbreakOrRoot
        case messageRetentionInterval
        case authenticateAfterReboot
        case failedPasswordThresholdBeforeWipe
        case encryptionAtRestEnabledByDefault
        case legacyAppLockConfig

    }

}
