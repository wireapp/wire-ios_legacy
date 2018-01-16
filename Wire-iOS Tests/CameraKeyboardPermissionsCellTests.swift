//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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
import XCTest
import Photos
import Cartography
import AVFoundation
@testable import Wire

final class CameraKeyboardPermissionsCellTests: ZMSnapshotTestCase {

    var sut: CameraKeyboardPermissionsCell!
    
    override func setUp() {
        //self.recordMode = true
        self.sut = CameraKeyboardPermissionsCell()
    }
    
    @discardableResult func prepareForSnapshot(_ size: CGSize = CGSize(width: 320, height: 216)) -> UIView {
        
        let container = UIView()
        self.sut.frame = CGRect(origin: .zero, size: size)
        container.addSubview(self.sut)
            
        constrain(container, self.sut) { container, view in
            container.height == size.height
            container.width == size.width
            view.edges == container.edges
        }
            
        container.setNeedsLayout()
        container.layoutIfNeeded()
        return container
    }
    
    func testAccessCamera() {
        // given
        
        // when
        self.sut.configure(deniedAuthorization: .camera)
        let view = self.prepareForSnapshot()
        
        // then
        self.verify(view: view)
    }
    
    func testAccessPhotos() {
        // given
        
        // when
        self.sut.configure(deniedAuthorization: .photos)
        let view = self.prepareForSnapshot()
        
        // then
        self.verify(view: view)
    }
    
    
    func testAccessCameraAndPhotos() {
        // given
        
        // when
        self.sut.configure(deniedAuthorization: .cameraAndPhotos)
        let view = self.prepareForSnapshot()
        
        // then
        self.verify(view: view)
    }

}
