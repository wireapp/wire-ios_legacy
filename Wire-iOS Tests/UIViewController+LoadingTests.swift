//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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
import XCTest
@testable import Wire

final class LoadingViewControllerTests: ZMSnapshotTestCase {
    
    func testThatItShowsLoadingIndicator() {
        // Given
        let sut = UIViewController()
        sut.view.backgroundColor = .white
        sut.view.layer.speed = 0
        sut.view.frame = CGRect(x: 0, y: 0, width: 375, height: 667)
        sut.beginAppearanceTransition(true, animated: false)
        
        // when
        sut.showLoadingView = true
        
        // then
        verifyInAllDeviceSizes(view: sut.view)
    }
    
    func testThatItShowsLoadingIndicatorWithSubtitle() {
        // Given
        let sut = UIViewController()
        sut.view.backgroundColor = .white
        sut.view.layer.speed = 0
        sut.view.frame = CGRect(x: 0, y: 0, width: 375, height: 667)
        sut.beginAppearanceTransition(true, animated: false)
        
        // when
        sut.spinnerView.subtitle = "RESTORING…"
        sut.showLoadingView = true
        
        // then
        verifyInAllDeviceSizes(view: sut.view)
    }
    
}
