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
@testable import Wire


class MessageDraftTests: XCTestCase {

    let fileManager = FileManager.default

    func testThatItCreatesDraftStorageDirectory() {
        do {
            // given
            let url = try fileManager.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)

            // when
            _ = try MessageDraftStorage(sharedContainerURL: url)

            // then
            var isDirectory = ObjCBool(booleanLiteral: false)
            withUnsafeMutablePointer(to: &isDirectory) {
                XCTAssert(FileManager.default.fileExists(atPath: url.appendingPathComponent("MessageDraftStorage").path, isDirectory: $0))
            }
            XCTAssert(isDirectory.boolValue)
        } catch {
            XCTFail("Unexpected error thrown: \(error)")
        }
    }

    func testThatItCanStoreAndRetrieveADraft() {
        do {
            // given
            let url = try fileManager.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let sut = try MessageDraftStorage(sharedContainerURL: url)
            let draft = MessageDraft(subject: "iOS Release", message: "Hey everyone, this is a draft message!")

            // when
            try sut.store([draft])

            // then
            let storedDrafts = try sut.storedDrafts()
            XCTAssertEqual([draft], storedDrafts)
        } catch {
            XCTFail("Unexpected error thrown: \(error)")
        }
    }

    func testThatItCanStoreMultipleDraftsAndSortsThemByLastModifiedDate() {
        do {
            // given
            let url = try fileManager.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let sut = try MessageDraftStorage(sharedContainerURL: url)
            let now = Date()
            let drafts = [
                MessageDraft(subject: "iOS Release", message: "Hey everyone, this is a draft message!", lastModified: now),
                MessageDraft(subject: "Italy trip", message: nil, lastModified: now.addingTimeInterval(5)),
                MessageDraft(subject: nil, message: "Need to come up with a subject for this one...", lastModified: now.addingTimeInterval(10))
            ]

            // when
            try sut.store(drafts)

            // then
            let storedDrafts = try sut.storedDrafts()
            XCTAssertEqual(drafts, storedDrafts)
        } catch {
            XCTFail("Unexpected error thrown: \(error)")
        }
    }

}
