//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

import Foundation
import WireDataModel
import WireSyncEngine

private let zmLog = ZMSLog(tag: "Analytics")

final class Analytics: NSObject {

    var provider: AnalyticsProvider?

    private var callingTracker: AnalyticsCallingTracker?
    private var decryptionFailedObserver: AnalyticsDecryptionFailedObserver?
    private var userObserverToken: Any?

    static var shared: Analytics!

    required init(optedOut: Bool) {
        zmLog.info("Analytics initWithOptedOut: \(optedOut)")
        provider = optedOut ? nil : AnalyticsProviderFactory.shared.analyticsProvider()

        super.init()

        setupObserver()
    }

    private func setupObserver() {
         NotificationCenter.default.addObserver(self, selector: #selector(userSessionDidBecomeAvailable(_:)), name: Notification.Name.ZMUserSessionDidBecomeAvailable, object: nil)
    }

    @objc
    private func userSessionDidBecomeAvailable(_ note: Notification?) {
        callingTracker = AnalyticsCallingTracker(analytics: self)
        selfUser = SelfUser.provider?.selfUser

        decryptionFailedObserver = AnalyticsDecryptionFailedObserver(analytics: self)
    }

    var selfUser: UserType? {
        get {
            return provider?.selfUser
        }

        set {
            provider?.selfUser = newValue

            if let user = newValue, let userSession = ZMUserSession.shared() {
                userObserverToken = UserChangeInfo.add(observer: self, for: user, in: userSession)
            } else {
                userObserverToken = nil
            }
        }
    }

    func tagEvent(_ event: String,
                  attributes: [String: Any]) {
        guard let attributes = attributes as? [String: NSObject] else { return }

        tagEvent(event, attributes: attributes)
    }

    // MARK: - OTREvents
    func tagCannotDecryptMessage(withAttributes userInfo: [String: Any],
                                 conversation: ZMConversation?) {
        var attributes: [String: Any] = conversation?.attributesForConversation ?? [:]

        attributes.merge(userInfo, strategy: .preferNew)
        tagEvent("e2ee.failed_message_decryption", attributes: attributes)
    }
}

extension Analytics: AnalyticsType {
    func setPersistedAttributes(_ attributes: [String: NSObject]?, for event: String) {
        // no-op
    }

    func persistedAttributes(for event: String) -> [String: NSObject]? {
        // no-op
        return nil
    }

    /// Record an event with no attributes
    func tagEvent(_ event: String) {
        provider?.tagEvent(event, attributes: [:])
    }

    /// Record an event with optional attributes.
    /// - Parameters:
    ///   - event: event to tag
    ///   - attributes: attributes of the event
    func tagEvent(_ event: String, attributes: [String: NSObject]) {
        provider?.tagEvent(event, attributes: attributes)
    }
}

extension Analytics: ZMUserObserver {

    func userDidChange(_ changeInfo: UserChangeInfo) {
        guard
            changeInfo.user.isSelfUser,
            changeInfo.analyticsIdentifierChanged
        else {
            return
        }

        selfUser = nil
        selfUser = changeInfo.user
    }

}
