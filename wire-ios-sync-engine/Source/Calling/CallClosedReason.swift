//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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
import avs

/**
 * Reasons why a call can be terminated.
 */

public enum CallClosedReason: Int32 {

    /// Ongoing call was closed by remote or self user
    case normal
    /// Incoming call was canceled by remote
    case canceled
    /// Incoming call was answered on another device
    case anweredElsewhere
    /// Incoming call was rejected on another device
    case rejectedElsewhere
    /// Outgoing call timed out
    case timeout
    /// Ongoing call lost media and was closed
    case lostMedia
    /// Call was closed because of internal error in AVS
    case internalError
    /// Call was closed due to a input/output error (couldn't access microphone)
    case inputOutputError
    /// Call left by the selfUser but continues until everyone else leaves or AVS closes it
    case stillOngoing
    /// Call was dropped due to the security level degrading
    case securityDegraded
    /// Call was closed because the client version is blacklisted for that call
    case outdatedClient
    /// Call was closed due to an error in data channel connection
    case datachannel
    /// Call timed out
    case timeoutECONN
    /// Call was closed because no one joined
    case noOneJoined
    /// Call was closed because everyone left
    case everyoneLeft
    /// Call was closed for an unknown reason. This is most likely a bug.
    case unknown

    // MARK: - Briding

    /**
     * Creates the call closed reason from the AVS flag.
     * - parameter wcall_reason: The flag
     * - returns: The decoded reason, or `.unknown` if the flag couldn't be processed.
     */

    init(wcall_reason: Int32) {
        switch wcall_reason {
        case WCALL_REASON_NORMAL:
            self = .normal
        case WCALL_REASON_CANCELED:
            self = .canceled
        case WCALL_REASON_ANSWERED_ELSEWHERE:
            self = .anweredElsewhere
        case WCALL_REASON_REJECTED:
            self = .rejectedElsewhere
        case WCALL_REASON_TIMEOUT:
            self = .timeout
        case WCALL_REASON_LOST_MEDIA:
            self = .lostMedia
        case WCALL_REASON_ERROR:
            self = .internalError
        case WCALL_REASON_IO_ERROR:
            self = .inputOutputError
        case WCALL_REASON_STILL_ONGOING:
            self = .stillOngoing
        case WCALL_REASON_OUTDATED_CLIENT:
            self = .outdatedClient
        case WCALL_REASON_TIMEOUT_ECONN:
            self = .timeoutECONN
        case WCALL_REASON_DATACHANNEL:
            self = .datachannel
        case WCALL_REASON_NOONE_JOINED:
            self = .noOneJoined
        case WCALL_REASON_EVERYONE_LEFT:
            self = .everyoneLeft
        default:
            self = .unknown
        }
    }

    /// The raw flag for the call end.
    var wcall_reason: Int32 {
        switch self {
        case .normal:
            return WCALL_REASON_NORMAL
        case .canceled:
            return WCALL_REASON_CANCELED
        case .anweredElsewhere:
            return WCALL_REASON_ANSWERED_ELSEWHERE
        case .rejectedElsewhere:
            return WCALL_REASON_REJECTED
        case .timeout:
            return WCALL_REASON_TIMEOUT
        case .lostMedia:
            return WCALL_REASON_LOST_MEDIA
        case .internalError:
            return WCALL_REASON_ERROR
        case .inputOutputError:
            return WCALL_REASON_IO_ERROR
        case .stillOngoing:
            return WCALL_REASON_STILL_ONGOING
        case .securityDegraded:
            return WCALL_REASON_ERROR
        case .outdatedClient:
            return WCALL_REASON_OUTDATED_CLIENT
        case .timeoutECONN:
            return WCALL_REASON_TIMEOUT_ECONN
        case .datachannel:
            return WCALL_REASON_DATACHANNEL
        case .noOneJoined:
            return WCALL_REASON_NOONE_JOINED
        case .everyoneLeft:
            return WCALL_REASON_EVERYONE_LEFT
        case .unknown:
            return WCALL_REASON_ERROR
        }
    }
}
