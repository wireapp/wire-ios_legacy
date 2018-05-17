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
import AVFoundation

class CallPermissions: CallPermissionsConfiguration {

    var isPendingAudioPermissionRequest: Bool {
        return AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeAudio) == .notDetermined
    }

    var isPendingVideoPermissionRequest: Bool {
        return AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo) == .notDetermined
    }

    var canAcceptAudioCalls: Bool {
        return AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeAudio) == .authorized
    }

    var canAcceptVideoCalls: Bool {
        return AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo) == .authorized
    }

    func requestVideoPermissionWithoutWarning(resultHandler: @escaping (Bool) -> Void) {
        UIApplication.wr_requestVideoAccess(resultHandler)
    }

    func requestOrWarnAboutAudioPermission(resultHandler: @escaping (Bool) -> Void) {
        UIApplication.wr_requestOrWarnAboutMicrophoneAccess(resultHandler)
    }

    func requestOrWarnAboutVideoPermission(resultHandler: @escaping (Bool) -> Void) {
        UIApplication.wr_requestOrWarnAboutVideoAccess(resultHandler)
    }

}
