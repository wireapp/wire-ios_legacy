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

import XCTest
import SnapshotTesting

@testable import Wire

final class AccountViewSnapshotTests: ZMSnapshotTestCase {
    var imageData: Data!

    override func setUp() {
        super.setUp()

        accentColor = .violet
        imageData = UIImage(inTestBundleNamed: "unsplash_matterhorn.jpg", for: AccountViewSnapshotTests.self)!.jpegData(compressionQuality: 0.9)
    }

    override func tearDown() {
        imageData = nil

        super.tearDown()
    }

    func testThatItShowsBasicAccount_Personal() {
        // GIVEN
        let account = Account(userName: "Iggy Pop", userIdentifier: UUID(), teamName: nil, imageData: nil)
        let sut = PersonalAccountView(account: account, displayContext: .accountSelector)!
        sut.overrideUserInterfaceStyle = .light
        // WHEN && THEN
        verify(matching: sut)
    }

    func testThatItShowsBasicAccountSelected_Personal() {
        // GIVEN
        let account = Account(userName: "Iggy Pop", userIdentifier: UUID(), teamName: nil, imageData: nil)
        let sut = PersonalAccountView(account: account, displayContext: .accountSelector)!
        sut.overrideUserInterfaceStyle = .light
        // WHEN 
        sut.selected = true
        // THEN
        verify(matching: sut)
    }

    func testThatItShowsBasicAccountWithPicture_Personal() {
        // GIVEN
        let account = Account(userName: "Iggy Pop", userIdentifier: UUID(), teamName: nil, imageData: imageData)
        let sut = PersonalAccountView(account: account, displayContext: .accountSelector)!
        // WHEN && THEN
        verify(matching: sut)
    }

    func testThatItShowsBasicAccountWithPictureSelected_Personal() {
        // GIVEN
        let account = Account(userName: "Iggy Pop", userIdentifier: UUID(), teamName: nil, imageData: imageData)
        let sut = PersonalAccountView(account: account, displayContext: .accountSelector)!
        // WHEN 
        sut.selected = true
        // THEN
        verify(matching: sut)
    }

    func testThatItShowsBasicAccount_Team() {
        // GIVEN
        let account = Account(userName: "Iggy Pop", userIdentifier: UUID(), teamName: "Wire", imageData: nil)
        let sut = TeamAccountView(account: account, displayContext: .accountSelector)!
        // WHEN && THEN
        verify(matching: sut)
    }

    func testThatItShowsBasicAccountSelected_Team() {
        // GIVEN
        let account = Account(userName: "Iggy Pop", userIdentifier: UUID(), teamName: "Wire", imageData: nil)
        let sut = TeamAccountView(account: account, displayContext: .accountSelector)!
        // WHEN
        sut.selected = true
        // THEN
        verify(matching: sut)
    }

    func testThatItShowsBasicAccountWithPicture_Team() {
        // GIVEN
        let account = Account(userName: "Iggy Pop", userIdentifier: UUID(), teamName: "Wire", imageData: nil, teamImageData: imageData)
        let sut = TeamAccountView(account: account, displayContext: .accountSelector)!
        // WHEN && THEN
        verify(matching: sut)
    }

    func testThatItShowsBasicAccountWithPictureSelected_Team() {
        // GIVEN
        let account = Account(userName: "Iggy Pop", userIdentifier: UUID(), teamName: "Wire", imageData: nil, teamImageData: imageData)
        let sut = TeamAccountView(account: account, displayContext: .accountSelector)!
        // WHEN
        sut.selected = true
        // THEN
        verify(matching: sut)
    }

    // MARK: - unread dot

    func testThatItShowsBasicAccountWithPictureSelected_Team_withUnreadDot() {
        // GIVEN
        let account = Account(userName: "Iggy Pop", userIdentifier: UUID(), teamName: "Wire", imageData: nil, teamImageData: imageData)
        account.unreadConversationCount = 100
        let sut = TeamAccountView(account: account, displayContext: .accountSelector)!
        sut.unreadCountStyle = .current
        sut.overrideUserInterfaceStyle = .light

        // WHEN
        sut.selected = true

        // THEN
        verify(matching: sut)
    }

    func testThatItShowsBasicAccountWithPictureSelected_Personal_withUnreadDot() {
        // GIVEN
        let account = Account(userName: "Iggy Pop", userIdentifier: UUID(), teamName: nil, imageData: imageData)
        account.unreadConversationCount = 100
        let sut = PersonalAccountView(account: account, displayContext: .accountSelector)!
        sut.unreadCountStyle = .current

        // WHEN
        sut.selected = true

        // THEN
        verify(matching: sut)
    }

    func testThatItShowsBasicAccountSelected_Personal_withUnreadDot() {
        // GIVEN
        let account = Account(userName: "Iggy Pop", userIdentifier: UUID(), teamName: nil, imageData: nil)
        account.unreadConversationCount = 100
        let sut = PersonalAccountView(account: account, displayContext: .accountSelector)!
        sut.unreadCountStyle = .current

        // WHEN
        sut.selected = true

        // THEN
        verify(matching: sut)
    }

    func testThatItShowsBasicAccountSelected_Team_withUnreadDot() {
        // GIVEN
        let account = Account(userName: "Iggy Pop", userIdentifier: UUID(), teamName: "Wire", imageData: nil)
        account.unreadConversationCount = 100
        let sut = TeamAccountView(account: account, displayContext: .accountSelector)!
        sut.unreadCountStyle = .current
        sut.selected = true

        // WHEN && THEN
        verify(matching: sut)
    }

    // MARK: - smaller icon for conversation list
    func testThatItShowsBasicAccount_Team_conversationListContext() {
        // GIVEN
        let account = Account(userName: "Iggy Pop", userIdentifier: UUID(), teamName: "Wire", imageData: nil)
        let sut = TeamAccountView(account: account, displayContext: .conversationListHeader)!
        // WHEN && THEN
        verify(matching: sut)
    }
}
