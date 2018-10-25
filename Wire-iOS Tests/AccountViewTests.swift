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

class AccountViewTests: ZMSnapshotTestCase {
    override func setUp() {
        super.setUp()
        accentColor = .violet
    }
    
    func testThatItShowsBasicAccount_Personal() {
        // GIVEN
        let account = Account(userName: "Iggy Pop", userIdentifier: UUID(), teamName: nil, imageData: nil)
        let sut = PersonalAccountView(account: account)
        // WHEN && THEN
        self.verify(view: sut.snapshotView())
    }

    func testThatItShowsBasicAccountSelected_Personal() {
        // GIVEN
        let account = Account(userName: "Iggy Pop", userIdentifier: UUID(), teamName: nil, imageData: nil)
        let sut = PersonalAccountView(account: account)
        // WHEN 
        sut.selected = true
        // THEN
        self.verify(view: sut.snapshotView())
    }
    
    func testThatItShowsBasicAccountWithPicture_Personal() {
        // GIVEN
        let account = Account(userName: "Iggy Pop", userIdentifier: UUID(), teamName: nil, imageData: self.image(inTestBundleNamed: "unsplash_matterhorn.jpg").jpegData(compressionQuality: 0.9))
        let sut = PersonalAccountView(account: account)
        // WHEN && THEN
        self.verify(view: sut.snapshotView())
    }
    
    func testThatItShowsBasicAccountWithPictureSelected_Personal() {
        // GIVEN
        let account = Account(userName: "Iggy Pop", userIdentifier: UUID(), teamName: nil, imageData: self.image(inTestBundleNamed: "unsplash_matterhorn.jpg").jpegData(compressionQuality: 0.9))
        let sut = PersonalAccountView(account: account)
        // WHEN 
        sut.selected = true
        // THEN
        self.verify(view: sut.snapshotView())
    }
    
    func testThatItShowsBasicAccount_Team() {
        // GIVEN
        let account = Account(userName: "Iggy Pop", userIdentifier: UUID(), teamName: "Wire", imageData: nil)
        let sut = TeamAccountView(account: account)
        // WHEN && THEN
        self.verify(view: sut.snapshotView())
    }
    
    func testThatItShowsBasicAccountSelected_Team() {
        // GIVEN
        let account = Account(userName: "Iggy Pop", userIdentifier: UUID(), teamName: "Wire", imageData: nil)
        let sut = TeamAccountView(account: account)
        // WHEN
        sut.selected = true
        // THEN
        self.verify(view: sut.snapshotView())
    }
    
    func testThatItShowsBasicAccountWithPicture_Team() {
        // GIVEN
        let account = Account(userName: "Iggy Pop", userIdentifier: UUID(), teamName: "Wire", imageData: nil, teamImageData: self.image(inTestBundleNamed: "unsplash_matterhorn.jpg").jpegData(compressionQuality: 0.9))
        let sut = TeamAccountView(account: account)
        // WHEN && THEN
        self.verify(view: sut.snapshotView())
    }
    
    func testThatItShowsBasicAccountWithPictureSelected_Team() {
        // GIVEN
        let account = Account(userName: "Iggy Pop", userIdentifier: UUID(), teamName: "Wire", imageData: nil, teamImageData: self.image(inTestBundleNamed: "unsplash_matterhorn.jpg").jpegData(compressionQuality: 0.9))
        let sut = TeamAccountView(account: account)
        // WHEN
        sut.selected = true
        // THEN
        self.verify(view: sut.snapshotView())
    }
}

fileprivate extension UIView {
    func snapshotView() -> UIView {
        self.layer.speed = 0
        self.setNeedsLayout()
        self.layoutIfNeeded()
        return self
    }
}
