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

protocol CallPermissionsConfiguration: class {
    var canAcceptAudioCalls: Bool { get }
    var isPendingAudioPermissionRequest: Bool { get }

    var canAcceptVideoCalls: Bool { get }
    var isPendingVideoPermissionRequest: Bool { get }

    func requestVideoPermissionWithoutWarning(resultHandler: @escaping (Bool) -> Void)
    func requestOrWarnAboutVideoPermission(resultHandler: @escaping (Bool) -> Void)
    func requestOrWarnAboutAudioPermission(resultHandler: @escaping (Bool) -> Void)

    func isEqual(to other: CallPermissionsConfiguration) -> Bool
}

extension CallPermissionsConfiguration where Self: Equatable {
    func isEqualTo(_ other: CallPermissionsConfiguration) -> Bool {
        return self == other as? Self
    }

    func asEquatable() -> AnyCallPermissionsConfiguration {
        return AnyCallPermissionsConfiguration(self)
    }
}

extension CallPermissionsConfiguration {

    var isAudioDisabledForever: Bool {
        return canAcceptAudioCalls == false && isPendingAudioPermissionRequest == false
    }

    var isVideoDisabledForever: Bool {
        return canAcceptVideoCalls == false && isPendingVideoPermissionRequest == false
    }

    var preferredVideoPlaceholderState: CallVideoPlaceholderState {
        guard !canAcceptVideoCalls else { return .hidden }
        return isPendingVideoPermissionRequest ? .statusTextHidden : .statusTextDisplayed
    }

}

func == (lhs: CallPermissionsConfiguration,
         rhs: CallPermissionsConfiguration) -> Bool {
    return lhs.canAcceptAudioCalls == rhs.canAcceptAudioCalls &&
           lhs.isPendingAudioPermissionRequest == rhs.isPendingAudioPermissionRequest &&
           lhs.canAcceptVideoCalls == rhs.canAcceptVideoCalls &&
           lhs.isPendingVideoPermissionRequest == rhs.isPendingVideoPermissionRequest
}

final class AnyCallPermissionsConfiguration: CallPermissionsConfiguration, Equatable {
    func isEqual(to other: CallPermissionsConfiguration) -> Bool {
        return self == other as? Self
    }

    init(_ state: CallPermissionsConfiguration) {
        self.value = state
    }

    var canAcceptAudioCalls: Bool { return value.canAcceptAudioCalls }
    var isPendingAudioPermissionRequest: Bool { return value.isPendingAudioPermissionRequest }

    var canAcceptVideoCalls: Bool { return value.canAcceptVideoCalls }
    var isPendingVideoPermissionRequest: Bool { return value.isPendingVideoPermissionRequest }

    func requestVideoPermissionWithoutWarning(resultHandler: @escaping (Bool) -> Void) {
        value.requestVideoPermissionWithoutWarning(resultHandler: resultHandler)
    }

    func requestOrWarnAboutVideoPermission(resultHandler: @escaping (Bool) -> Void) {
        value.requestOrWarnAboutVideoPermission(resultHandler: resultHandler)
    }

    func requestOrWarnAboutAudioPermission(resultHandler: @escaping (Bool) -> Void) {
        value.requestOrWarnAboutAudioPermission(resultHandler: resultHandler)
    }

    private let value: CallPermissionsConfiguration

    static func ==(lhs: AnyCallPermissionsConfiguration, rhs: AnyCallPermissionsConfiguration) -> Bool {
        return lhs.value.isEqual(to: rhs.value)
        }
}
