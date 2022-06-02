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
@testable import Wire

extension MediaState.SpeakerState {
    static let deselectedCanBeToggled = MediaState.SpeakerState(isEnabled: false, canBeToggled: true)
    static let selectedCanBeToggled = MediaState.SpeakerState(isEnabled: true, canBeToggled: true)
    static let deselectedCanNotBeToggled = MediaState.SpeakerState(isEnabled: false, canBeToggled: false)
    static let selectedCanNotBeToggled = MediaState.SpeakerState(isEnabled: true, canBeToggled: false)
}

class MockCallPermissions: CallPermissionsConfiguration {

    var isPendingAudioPermissionRequest: Bool = true
    var isPendingVideoPermissionRequest: Bool = true

    var canAcceptVideoCalls: Bool = false
    var canAcceptAudioCalls: Bool = false

    func requestOrWarnAboutVideoPermission(resultHandler: @escaping (Bool) -> Void) {
        resultHandler(canAcceptVideoCalls)
    }

    func requestVideoPermissionWithoutWarning(resultHandler: @escaping (Bool) -> Void) {
        resultHandler(canAcceptVideoCalls)
    }

    func requestOrWarnAboutAudioPermission(resultHandler: @escaping (Bool) -> Void) {
        resultHandler(canAcceptAudioCalls)
    }

}

// MARK: - Factories

extension MockCallPermissions {

    static var videoDeniedForever: MockCallPermissions {
        let permissions = MockCallPermissions()
        permissions.canAcceptVideoCalls = false
        permissions.isPendingVideoPermissionRequest = false
        return permissions
    }

    static var videoPendingApproval: MockCallPermissions {
        let permissions = MockCallPermissions()
        permissions.canAcceptVideoCalls = false
        permissions.isPendingVideoPermissionRequest = true
        return permissions
    }

    static var videoAllowedForever: MockCallPermissions {
        let permissions = MockCallPermissions()
        permissions.canAcceptVideoCalls = true
        permissions.isPendingVideoPermissionRequest = false
        return permissions
    }

}

// MARK: - Utilities

extension CallPermissionsConfiguration {

    func mediaStateIfAllowed(_ preferredState: MediaState) -> MediaState {

        if case .sendingVideo = preferredState {
            guard canAcceptVideoCalls else {
                return .notSendingVideo(speakerState: .deselectedCanBeToggled)
            }
        }

        return preferredState

    }

}
