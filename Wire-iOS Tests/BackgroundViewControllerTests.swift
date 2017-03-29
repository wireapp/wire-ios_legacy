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

import Foundation
import XCTest
@testable import Wire

class BackgroundViewControllerTests: CoreDataSnapshotTestCase {
    
    override func setUp() {
        super.setUp()
        selfUser.accentColorValue = .violet
        accentColor = .violet
    }

    func testThatItShowsUserWithoutImage() {
        // GIVEN
        selfUser.imageMediumData = .none
        let sut = BackgroundViewController(user: selfUser, userSession: .none)
        // WHEN & THEN
        self.verifyInIPhoneSize(view: sut.view)
    }
    
    func testThatItShowsUserWithImage() {
        // GIVEN
        selfUser.imageMediumData = UIImagePNGRepresentation(image(inTestBundleNamed: "unsplash_matterhorn.jpg"))
        let sut = BackgroundViewController(user: selfUser, userSession: .none)
        // WHEN & THEN
        self.verifyInIPhoneSize(view: sut.view)
    }
    
    func testThatItUpdatesForUserAccentColorUpdate_fromAccentColor() {
        // GIVEN
        selfUser.imageMediumData = .none
        let sut = BackgroundViewController(user: selfUser, userSession: .none)
        _ = sut.view
        // WHEN
        selfUser.accentColorValue = .brightOrange
        sut.updateFor(imageMediumDataChanged: false, accentColorValueChanged: true)
        
        // THEN
        self.verifyInIPhoneSize(view: sut.view)
    }
    
    func testThatItUpdatesForUserAccentColorUpdate_fromUserImageRemoved() {
        // GIVEN
        selfUser.imageMediumData = UIImagePNGRepresentation(image(inTestBundleNamed: "unsplash_matterhorn.jpg"))
        let sut = BackgroundViewController(user: selfUser, userSession: .none)
        _ = sut.view
        // WHEN
        selfUser.imageMediumData = .none
        selfUser.accentColorValue = .brightOrange
        sut.updateFor(imageMediumDataChanged: true, accentColorValueChanged: true)
        // THEN
        self.verifyInIPhoneSize(view: sut.view)
    }
    
    func testThatItUpdatesForUserAccentColorUpdate_fromUserImage() {
        // GIVEN
        selfUser.imageMediumData = UIImagePNGRepresentation(image(inTestBundleNamed: "unsplash_matterhorn.jpg"))
        let sut = BackgroundViewController(user: selfUser, userSession: .none)
        _ = sut.view
        // WHEN
        selfUser.accentColorValue = .brightOrange
        sut.updateFor(imageMediumDataChanged: true, accentColorValueChanged: true)
        // THEN
        self.verifyInIPhoneSize(view: sut.view)
    }
    
    func testThatItUpdatesForUserImageUpdate_fromAccentColor() {
        // GIVEN
        selfUser.imageMediumData = .none
        let sut = BackgroundViewController(user: selfUser, userSession: .none)
        _ = sut.view
        // WHEN
        selfUser.imageMediumData = UIImagePNGRepresentation(image(inTestBundleNamed: "unsplash_burger.jpg"))
        sut.updateFor(imageMediumDataChanged: true, accentColorValueChanged: false)
        // THEN
        self.verifyInIPhoneSize(view: sut.view)
    }
    
    func testThatItUpdatesForUserImageUpdate_fromUserImage() {
        // GIVEN
        selfUser.imageMediumData = UIImagePNGRepresentation(image(inTestBundleNamed: "unsplash_matterhorn.jpg"))
        let sut = BackgroundViewController(user: selfUser, userSession: .none)
        _ = sut.view
        // WHEN
        selfUser.imageMediumData = UIImagePNGRepresentation(image(inTestBundleNamed: "unsplash_burger.jpg"))
        sut.updateFor(imageMediumDataChanged: true, accentColorValueChanged: false)
        // THEN
        self.verifyInIPhoneSize(view: sut.view)
    }
}
