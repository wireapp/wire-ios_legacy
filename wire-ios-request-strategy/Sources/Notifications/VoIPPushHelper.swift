//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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

public enum VoIPPushHelper {

    enum Key: String {

        case isCallKitAvailable
        case loadedUserSessions
        case isAVSReady
        case knownCalls

    }

    public static var storage: UserDefaults = .standard

    public static var isCallKitAvailable: Bool {
        get {
            storage.bool(forKey: Key.isCallKitAvailable.rawValue)
        }

        set {
            storage.set(newValue, forKey: Key.isCallKitAvailable.rawValue)
        }
    }

    public static func setLoadedUserSessions(accountIDs: [UUID]) {
        loadedUserSessions = accountIDs.map(\.uuidString)
    }

    public static func isUserSessionLoaded(accountID: UUID) -> Bool {
        return loadedUserSessions
            .compactMap(UUID.init(uuidString:))
            .contains(accountID)
    }

    private static var loadedUserSessions: [String] {
        get {
            storage.object(forKey: Key.loadedUserSessions.rawValue) as? [String] ?? []
        }

        set {
            storage.set(newValue, forKey: Key.loadedUserSessions.rawValue)
        }
    }

    public static var isAVSReady: Bool {
        get {
            storage.bool(forKey: Key.isAVSReady.rawValue)
        }

        set {
            storage.set(newValue, forKey: Key.isAVSReady.rawValue)
        }
    }

    public static func setOngoingCalls(conversationIDs: [UUID]) {
        callKitCalls = conversationIDs.map(\.uuidString)
    }

    public static func existsOngoingCallInConversation(withID id: UUID) -> Bool {
        return callKitCalls
            .compactMap(UUID.init(uuidString:))
            .contains(id)
    }

    private static var callKitCalls: [String] {
        get {
            storage.object(forKey: Key.knownCalls.rawValue) as? [String] ?? []
        }

        set {
            storage.set(newValue, forKey: Key.knownCalls.rawValue)
        }
    }

}
