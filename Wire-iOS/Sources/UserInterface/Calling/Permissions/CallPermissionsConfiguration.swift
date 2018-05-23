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

protocol CallPermissionsConfiguration {

    var isPendingAudioPermissionRequest: Bool { get }
    var isPendingVideoPermissionRequest: Bool { get }

    var canAcceptVideoCalls: Bool { get }
    var canAcceptAudioCalls: Bool { get }

    func requestVideoPermissionWithoutWarning(resultHandler: @escaping (Bool) -> Void)
    func requestOrWarnAboutVideoPermission(resultHandler: @escaping (Bool) -> Void)
    func requestOrWarnAboutAudioPermission(resultHandler: @escaping (Bool) -> Void)

}

extension CallPermissionsConfiguration {

    var preferredVideoPlaceholderState: CallVideoPlaceholderState {

        guard !canAcceptVideoCalls else {
            return .hidden
        }

        return isPendingVideoPermissionRequest ? .statusTextHidden : .statusTextDisplayed

    }

    func videoStateIfAllowed(_ requestedState: VideoState) -> VideoState {

        switch requestedState {
        case .paused, .started, .badConnection: return
            canAcceptVideoCalls ? requestedState : .stopped
        case .stopped:
            return .stopped
        }

    }

}
