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

private let zmLog = ZMSLog(tag: "Analytics")

protocol CountlyInstance {
    func recordEvent(_ key: String, segmentation: [String: String]?)
    func start(with config: CountlyConfig)

    static func sharedInstance() -> Self
}

extension Countly: CountlyInstance {}

final class AnalyticsCountlyProvider: AnalyticsProvider {

    typealias PendingEvent = (event: String, attribtues: [String: Any])

    // MARK: - Properties

    var countlyInstanceType: CountlyInstance.Type

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

    private(set) var pendingEvents: [PendingEvent] = []

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

    init?(
        countlyInstanceType: CountlyInstance.Type = Countly.self,
        countlyAppKey: String,
        serverURL: URL
    ) {
        guard !countlyAppKey.isEmpty else { return nil }

        self.countlyInstanceType = countlyInstanceType
        self.appKey = countlyAppKey
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
            let userProperties = userProperties(for: user)
        else {
            return
        }

        let config: CountlyConfig = CountlyConfig()
        config.appKey = appKey
        config.host = serverURL.absoluteString
        config.manualSessionHandling = true
        config.deviceID = analyticsIdentifier

        updateCountlyUser(withProperties: userProperties)

        countlyInstanceType.sharedInstance().start(with: config)

        // Changing Device ID after app started
        // ref: https://support.count.ly/hc/en-us/articles/360037753511-iOS-watchOS-tvOS-macOS#section-resetting-stored-device-id
        Countly.sharedInstance().setNewDeviceID(analyticsIdentifier, onServer: true)

        zmLog.info("AnalyticsCountlyProvider \(self) started")

        didInitializeCountly = true

        beginSession()
        tagPendingEvents()
    }

    private func endCountly() {
        endSession()
        clearCountlyUser()
        didInitializeCountly = false
    }

    private func beginSession() {
        Countly.sharedInstance().beginSession()
        isRecording = true
    }

    private func updateSession() {
        guard isRecording else { return }
        Countly.sharedInstance().updateSession()
    }

    private func endSession() {
        Countly.sharedInstance().endSession()
        isRecording = false
    }

    // MARK: - Countly user

    private func userProperties(for user: ZMUser) -> [String: Any]? {
        guard
            let team = user.team,
            let teamId = team.remoteIdentifier
        else {
            return nil
        }

        return [
            "team_team_id": teamId,
            "team_user_type": user.teamRole,
            "team_team_size": team.members.count,
            "user_contacts": team.members.count.logRound()
        ]
    }

    private func updateCountlyUser(withProperties properties: [String: Any]) {
        let convertedAttributes = properties.countlyStringValueDictionary

        for (key, value) in convertedAttributes {
            Countly.user().set(key, value: value)
        }

        Countly.user().save()
    }

    private func clearCountlyUser() {
        let keys = [
            "team_team_id",
            "team_user_type",
            "team_team_size",
            "user_contacts"
        ]

        keys.forEach(Countly.user().unSet)
        Countly.user().save()
    }

    private var shouldTracksEvent: Bool {
        return selfUser?.isTeamMember == true
    }

    // MARK: - Tag events

    func tagEvent(_ event: String,
                  attributes: [String: Any]) {
        //store the event before self user is assigned, send it later when self user is ready.
        guard selfUser != nil else {
            pendingEvents.append(PendingEvent(event, attributes))
            return
        }

        guard shouldTracksEvent else {
            return
        }

        var convertedAttributes = attributes.countlyStringValueDictionary

        convertedAttributes["app_name"] = "ios"
        convertedAttributes["app_version"] = Bundle.main.shortVersionString

        countlyInstanceType.sharedInstance().recordEvent(event, segmentation: convertedAttributes)
    }

    private func tagPendingEvents() {
        for (event, attributes) in pendingEvents {
            tagEvent(event, attributes: attributes)
        }

        pendingEvents.removeAll()
    }

    func setSuperProperty(_ name: String, value: Any?) {
        //TODO
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

extension Int {
    func logRound(factor: Double = 6) -> Int {
        return Int(ceil(pow(2, (floor(factor * log2(Double(self))) / factor))))
    }
}
