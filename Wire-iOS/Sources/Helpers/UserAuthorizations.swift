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
import Photos

open class UserAuthorizations {
    
    
    static var camera: Bool {
        switch AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo) {
            case .authorized: return true
            default: return false
        }
    }
    
    static var photoLibrary: Bool {
        switch PHPhotoLibrary.authorizationStatus() {
            case .authorized: return true
            default: return false
        }
    }
    
    static var cameraOrPhotoLibrary: Bool {
        return camera || photoLibrary
    }
}
