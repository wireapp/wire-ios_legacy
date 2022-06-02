//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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

/// This class facilitates storage and retrieval of feature configs to and from
/// the database.
///
/// Each `Feature` may have a different structure for its configuration, so a json
/// encoded form is what is stored in the database. Use this class to fetch a specific
/// feature as a type that contains a decoded configuration.
///
/// **Note:** fetching features can occur on any context, but updates should only
/// take place on the sync context.

public class FeatureService {

    // MARK: - Properties

    private let context: NSManagedObjectContext

    // MARK: - Life cycle

    public init(context: NSManagedObjectContext) {
        self.context = context
    }

    // MARK: - App lock

    public func fetchAppLock() -> Feature.AppLock {
        guard let feature = Feature.fetch(name: .appLock, context: context),
              let featureConfig = feature.config else {
                  return .init()
              }
        let config = try! JSONDecoder().decode(Feature.AppLock.Config.self, from: featureConfig)
        return.init(status: feature.status, config: config)
    }

    public func storeAppLock(_ appLock: Feature.AppLock) {
        let config = try! JSONEncoder().encode(appLock.config)

        Feature.updateOrCreate(havingName: .appLock, in: context) {
            $0.status = appLock.status
            $0.config = config
        }
    }

    // MARK: - Conference calling

    public func fetchConferenceCalling() -> Feature.ConferenceCalling {
        guard let feature = Feature.fetch(name: .conferenceCalling, context: context) else {
            return .init()
        }
        return .init(status: feature.status)
    }

    public func storeConferenceCalling(_ conferenceCalling: Feature.ConferenceCalling) {
        Feature.updateOrCreate(havingName: .conferenceCalling, in: context) {
            $0.status = conferenceCalling.status
        }

        guard
            needsToNotifyUser(for: .conferenceCalling),
            conferenceCalling.status == .enabled
        else {
            return
        }

        notifyChange(.conferenceCallingIsAvailable)
    }

    // MARK: - File sharing

    public func fetchFileSharing() -> Feature.FileSharing {
        guard let feature = Feature.fetch(name: .fileSharing, context: context) else {
            return .init()
        }

        return .init(status: feature.status)
    }

    public func storeFileSharing(_ fileSharing: Feature.FileSharing) {
        Feature.updateOrCreate(havingName: .fileSharing, in: context) {
            $0.status = fileSharing.status
        }

        guard needsToNotifyUser(for: .fileSharing) else { return }

        switch fileSharing.status {
        case .disabled:
            notifyChange(.fileSharingDisabled)

        case .enabled:
            notifyChange(.fileSharingEnabled)
        }
    }

    // MARK: - Self deleting messages

    public func fetchSelfDeletingMesssages() -> Feature.SelfDeletingMessages {
        guard let feature = Feature.fetch(name: .selfDeletingMessages, context: context),
              let featureConfig = feature.config else {
                  return .init()
              }
        let config = try! JSONDecoder().decode(Feature.SelfDeletingMessages.Config.self, from: featureConfig)
        return .init(status: feature.status, config: config)
    }

    public func storeSelfDeletingMessages(_ selfDeletingMessages: Feature.SelfDeletingMessages) {
        let config = try! JSONEncoder().encode(selfDeletingMessages.config)

        Feature.updateOrCreate(havingName: .selfDeletingMessages, in: context) {
            $0.status = selfDeletingMessages.status
            $0.config = config
        }

        guard needsToNotifyUser(for: .selfDeletingMessages) else { return }

        switch (selfDeletingMessages.status, selfDeletingMessages.config.enforcedTimeoutSeconds) {
        case (.disabled, _):
            notifyChange(.selfDeletingMessagesIsDisabled)

        case (.enabled, let enforcedTimeout) where enforcedTimeout > 0:
            notifyChange(.selfDeletingMessagesIsEnabled(enforcedTimeout: enforcedTimeout))

        case (.enabled, _):
            notifyChange(.selfDeletingMessagesIsEnabled(enforcedTimeout: nil))
        }
    }

    // MARK: - Conversation guest links

    public func fetchConversationGuestLinks() -> Feature.ConversationGuestLinks {
        guard let feature = Feature.fetch(name: .conversationGuestLinks, context: context) else {
            return .init()
        }
        return .init(status: feature.status)
    }

    public func storeConversationGuestLinks(_ conversationGuestLinks: Feature.ConversationGuestLinks) {
        Feature.updateOrCreate(havingName: .conversationGuestLinks, in: context) {
            $0.status = conversationGuestLinks.status
        }

        guard needsToNotifyUser(for: .conversationGuestLinks) else { return }

        switch conversationGuestLinks.status {
        case .disabled:
            notifyChange(.conversationGuestLinksDisabled)

        case .enabled:
            notifyChange(.conversationGuestLinksEnabled)
        }
    }

    // MARK: - Classified domains

    public func fetchClassifiedDomains() -> Feature.ClassifiedDomains {
        guard
            let feature = Feature.fetch(name: .classifiedDomains, context: context),
            let featureConfig = feature.config
        else {
            return .init()
        }

        let config = try! JSONDecoder().decode(Feature.ClassifiedDomains.Config.self, from: featureConfig)
        return .init(status: feature.status, config: config)
    }

    public func storeClassifiedDomains(_ classifiedDomains: Feature.ClassifiedDomains) {
        let config = try! JSONEncoder().encode(classifiedDomains.config)

        Feature.updateOrCreate(havingName: .classifiedDomains, in: context) {
            $0.status = classifiedDomains.status
            $0.config = config
        }
    }

    // MARK: - Digital signature

    public func fetchDigitalSignature() -> Feature.DigitalSignature {
        guard let feature = Feature.fetch(name: .digitalSignature, context: context) else {
            return .init()
        }

        return .init(status: feature.status)
    }

    public func storeDigitalSignature(_ digitalSignature: Feature.DigitalSignature) {
        Feature.updateOrCreate(havingName: .digitalSignature, in: context) {
            $0.status = digitalSignature.status
        }
    }

    // MARK: - Methods

    func createDefaultConfigsIfNeeded() {
        for name in Feature.Name.allCases where Feature.fetch(name: name, context: context) == nil {
            switch name {
            case .appLock:
                storeAppLock(.init())

            case .conferenceCalling:
                storeConferenceCalling(.init())

            case .fileSharing:
                storeFileSharing(.init())

            case .selfDeletingMessages:
                storeSelfDeletingMessages(.init())

            case .conversationGuestLinks:
                storeConversationGuestLinks(.init())

            case .classifiedDomains:
                storeClassifiedDomains(.init())

            case .digitalSignature:
                storeDigitalSignature(.init())
            }
        }
    }

    func needsToNotifyUser(for featureName: Feature.Name) -> Bool {
        var result = false

        context.performGroupedAndWait {
            let feature = Feature.fetch(name: featureName, context: $0)
            result = feature?.needsToNotifyUser ?? false
        }

        return result
    }

    public func setNeedsToNotifyUser(_ notifyUser: Bool, for featureName: Feature.Name) {
        context.performGroupedAndWait {
            let feature = Feature.fetch(name: featureName, context: $0)
            feature?.needsToNotifyUser = notifyUser
        }
    }

    private func notifyChange(_ change: FeatureChange) {
        NotificationCenter.default.post(name: .featureDidChangeNotification, object: change)
    }

}

extension FeatureService {

    /// A type that represents the possible changes to feature configs.
    ///
    /// These can be used by the ui layer to determine what kind of alert
    /// it needs to display to inform the user of changes.

    public enum FeatureChange {

        case conferenceCallingIsAvailable
        case selfDeletingMessagesIsDisabled
        case selfDeletingMessagesIsEnabled(enforcedTimeout: UInt?)
        case fileSharingEnabled
        case fileSharingDisabled
        case conversationGuestLinksEnabled
        case conversationGuestLinksDisabled

    }

}

extension Notification.Name {

    public static let featureDidChangeNotification = Notification.Name("FeatureDidChangeNotification")

}
