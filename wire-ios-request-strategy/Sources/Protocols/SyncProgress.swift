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

@objc public enum SyncPhase: Int, CustomStringConvertible, CaseIterable {

    case fetchingLastUpdateEventID
    case fetchingTeams
    case fetchingTeamMembers
    case fetchingTeamRoles
    case fetchingConnections
    case fetchingConversations
    case fetchingUsers
    case fetchingSelfUser
    case fetchingLegalHoldStatus
    case fetchingLabels
    case fetchingMissedEvents
    case done

    public var isLastSlowSyncPhase: Bool {
        return self == Self.lastSlowSyncPhase
    }

    public var isSyncing: Bool {
        return self != .done
    }

    public var nextPhase: SyncPhase {
        return SyncPhase(rawValue: rawValue + 1) ?? .done
    }

    public static var lastSlowSyncPhase: SyncPhase {
        return .fetchingLabels
    }

    public var description: String {
        switch self {
        case .fetchingLastUpdateEventID:
            return "fetchingLastUpdateEventID"
        case .fetchingConnections:
            return "fetchingConnections"
        case .fetchingConversations:
            return "fetchingConversations"
        case .fetchingTeams:
            return "fetchingTeams"
        case .fetchingTeamMembers:
            return "fetchingTeamMembers"
        case .fetchingTeamRoles:
            return "fetchingTeamRoles"
        case .fetchingUsers:
            return "fetchingUsers"
        case .fetchingSelfUser:
            return "fetchingSelfUser"
        case .fetchingLegalHoldStatus:
            return "fetchingLegalHoldStatus"
        case .fetchingLabels:
            return "fetchingLabels"
        case .fetchingMissedEvents:
            return "fetchingMissedEvents"
        case .done:
            return "done"
        }
    }
}

@objc
public protocol SyncProgress {

    var currentSyncPhase: SyncPhase { get }

    func finishCurrentSyncPhase(phase: SyncPhase)
    func failCurrentSyncPhase(phase: SyncPhase)

}
