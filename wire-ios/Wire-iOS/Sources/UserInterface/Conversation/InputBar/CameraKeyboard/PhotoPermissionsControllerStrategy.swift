//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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
import Photos

final class PhotoPermissionsControllerStrategy: PhotoPermissionsController {

    // `unauthorized` state happens the first time before opening the keyboard,
    // so we don't need to check it for our purposes.

    var isCameraAuthorized: Bool {
        switch AVCaptureDevice.authorizationStatus(for: AVMediaType.video) {
        case .authorized: return true
        default: return false
        }
    }

    var isPhotoLibraryAuthorized: Bool {
        switch PHPhotoLibrary.authorizationStatus() {
        case .authorized: return true
        default: return false
        }
    }

    var areCameraOrPhotoLibraryAuthorized: Bool {
        return isCameraAuthorized || isPhotoLibraryAuthorized
    }

    var areCameraAndPhotoLibraryAuthorized: Bool {
        return isCameraAuthorized && isPhotoLibraryAuthorized
    }
}
