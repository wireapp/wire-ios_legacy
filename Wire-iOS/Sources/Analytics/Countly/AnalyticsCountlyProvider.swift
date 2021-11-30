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
import Countly
import WireSyncEngine
import WireDataModel

private let zmLog = ZMSLog(tag: "Analytics")

final class AnalyticsCountlyProvider: AnalyticsProvider {

    typealias PendingEvent = (event: String, attributes: [String: Any])

    // MARK: - Properties

    private let countly: CountlyInterface
    private let countlyUser: CountlyUserInterface

    /// The Countly application to which events will be sent.

    private let appKey: String

    /// The url of the server hosting the Countly application.

    private let serverURL: URL

    /// Whether a recording session is in progress.

    private var isRecording: Bool = false {
        didSet {
            guard isRecording != oldValue else { return }

            if isRecording {
                updateTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in self.updateSession() }
            } else {
                updateTimer?.invalidate()
                updateTimer = nil
            }
        }
    }

    /// Whether the Countly instance has been configured and started.

    private var didInitializeCountly: Bool = false

    /// Events that have been tracked before Countly has begun.

    private(set) var pendingEvents = [AnalyticsEvent]()

    var isOptedOut: Bool {
        didSet {
            if !isOptedOut {
                endSession()
            } else if let user = selfUser as? ZMUser {
                startCountly(for: user)
            }
        }
    }

    var selfUser: UserType? {
        didSet {
            endCountly()
            guard let user = selfUser as? ZMUser else { return }
            startCountly(for: user)
        }
    }

    private var updateTimer: Timer?

    // MARK: - Life cycle

    init?(countly: CountlyInterface = Countly.sharedInstance(),
          countlyUser: CountlyUserInterface = Countly.user(),
          appKey: String,
          serverURL: URL) {

        guard !appKey.isEmpty else { return nil }

        self.countly = countly
        self.countlyUser = countlyUser
        self.appKey = appKey
        self.serverURL = serverURL
        isOptedOut = false
        setupApplicationNotifications()
    }

    deinit {
        zmLog.info("AnalyticsCountlyProvider \(self) deallocated")
    }

    // MARK: - Session management

    private func startCountly(for user: ZMUser) {
        guard
            !isOptedOut,
            !isRecording,
            user.isTeamMember,
            let analyticsIdentifier = user.analyticsIdentifier,
            let userAttributes = user.analyticsAttributes
        else {
            return
        }

        let config: CountlyConfig = CountlyConfig()
        config.appKey = appKey
        config.host = serverURL.absoluteString
        config.manualSessionHandling = true
        config.deviceID = analyticsIdentifier

        countlyUser.update(with: userAttributes)

        countly.start(with: config)

        // Changing Device ID after app started
        // ref: https://support.count.ly/hc/en-us/articles/360037753511-iOS-watchOS-tvOS-macOS#section-resetting-stored-device-id
        countly.setNewDeviceID(analyticsIdentifier, onServer: true)

        zmLog.info("AnalyticsCountlyProvider \(self) started")

        didInitializeCountly = true

        beginSession()
        tagPendingEvents()
    }

    private func endCountly() {
        endSession()
        countlyUser.reset()
        didInitializeCountly = false
    }

    private func beginSession() {
        countly.beginSession()
        isRecording = true
    }

    private func updateSession() {
        guard isRecording else { return }
        countly.updateSession()
    }

    private func endSession() {
        countly.endSession()
        isRecording = false
    }

    private var shouldTracksEvent: Bool {
        return selfUser?.isTeamMember == true
    }

    // MARK: - Tag events

    func tagEvent(_ event: AnalyticsEvent) {
        guard selfUser != nil else {
            pendingEvents.append(event)
            return
        }

        guard shouldTracksEvent else { return }

        var segmentation = event.attributes
        segmentation[.appName] = "ios"
        segmentation[.appVersion] = Bundle.main.shortVersionString

        countly.recordEvent(event.name, segmentation: segmentation.rawValue)
    }

    func tagEvent(_ event: String, attributes: [String: Any]) {
        // TODO: [John] Delete this
    }

    private func tagPendingEvents() {
        pendingEvents.forEach(tagEvent)
        pendingEvents.removeAll()
    }

    func setSuperProperty(_ name: String, value: Any?) {
        // TODO
    }

    func flush(completion: Completion?) {
        completion?()
    }

    private var observerTokens = [Any]()
}

// MARK: - Application state observing

extension AnalyticsCountlyProvider: ApplicationStateObserving {

    func addObserverToken(_ token: NSObjectProtocol) {
        observerTokens.append(token)
    }

    func applicationDidBecomeActive() {
        guard didInitializeCountly else { return }
        beginSession()
    }

    func applicationDidEnterBackground() {
        guard isRecording else { return }
        endSession()
    }
}

// MARK: - Helpers

extension Dictionary where Key == String, Value == Any {

    private func countlyValue(rawValue: Any) -> String {
        if let boolValue = rawValue as? Bool {
            return boolValue ? "True" : "False"
        }

        if let teamRole = rawValue as? TeamRole {
            switch teamRole {
            case .partner:
                return "external"
            case .member, .admin, .owner:
                return "member"
            case .none:
                return "wireless"
            }
        }

        return "\(rawValue)"
    }

    var countlyStringValueDictionary: [String: String] {
        let convertedAttributes: [String: String] = [String: String](uniqueKeysWithValues:
            map { key, value in (key, countlyValue(rawValue: value)) })

        return convertedAttributes
    }
}

// TODO: [John] Delete

extension Int {
    func logRound(factor: Double = 6) -> Int {
        return Int(ceil(pow(2, (floor(factor * log2(Double(self))) / factor))))
    }
}

private extension ZMUser {

    var analyticsAttributes: CountlyUserAttributes? {
        guard
            let team = team,
            let teamId = team.remoteIdentifier
        else {
            return nil
        }

        return [
            .teamId: teamId,
            .teamRole: teamRole,
            .teamSize: team.members.count.rounded(byFactor: 6),
            // FIXME: This should be the number of contacts, not team size.
            .userContactsCount: team.members.count.rounded(byFactor: 6)
        ]
    }

}
