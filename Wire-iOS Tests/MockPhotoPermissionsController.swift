//
//  MockPhotoPermissionsController.swift
//  Wire-iOS
//
//  Created by Nicola Giancecchi on 16.01.18.
//  Copyright © 2018 Zeta Project Germany GmbH. All rights reserved.
//

import UIKit
import Foundation
import XCTest
@testable import Wire

class MockPhotoPermissionsController: PhotoPermissionsController {
    
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
