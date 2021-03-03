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

import UIKit
import Foundation
import XCTest
@testable import Wire

final class MockPhotoPermissionsController: PhotoPermissionsController {

    private var camera = false
    private var library = false

    init(camera: Bool, library: Bool) {
        self.camera = camera
        self.library = library
    }

    var isCameraAuthorized: Bool {
        return camera
    }

    var isPhotoLibraryAuthorized: Bool {
        return library
    }

    var areCameraOrPhotoLibraryAuthorized: Bool {
        return camera || library
    }

    var areCameraAndPhotoLibraryAuthorized: Bool {
        return camera && library
    }

}
