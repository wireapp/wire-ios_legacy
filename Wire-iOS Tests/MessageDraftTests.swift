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
    let url = try! FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)

    override func setUp() {
        super.setUp()
        try? fileManager.removeItem(at: url.appendingPathComponent("MessageDraftStorage"))
    }

    func testThatItCreatesDraftStorageDirectory() {
        do {
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
            let sut = try MessageDraftStorage(sharedContainerURL: url)
            let lastModified = NSDate()

            // when
            var draft: MessageDraft!
            sut.perform { moc in
                draft = MessageDraft.insertNewObject(in: moc)
                draft.subject = "Italy Trip"
                draft.message = "This is a draft message"
                draft.lastModifiedDate = lastModified
            }

            // then
            let resultsController = sut.resultsController
            try resultsController.performFetch()

            guard let objects = resultsController.fetchedObjects else { return XCTFail("Failed to fetch drafts") }
            XCTAssertEqual(objects.count, 1)
            XCTAssertEqual(objects.first, draft)
        } catch {
            XCTFail("Unexpected error thrown: \(error)")
        }
    }

    func testThatItCanStoreMultipleDraftsAndSortsThemByLastModifiedDate() {
        do {
            // given
            let sut = try MessageDraftStorage(sharedContainerURL: url)
            let now = NSDate()
            let future = now.addingTimeInterval(10)

            // when
            var first: MessageDraft!
            var second: MessageDraft!

            sut.perform { moc in
                first = MessageDraft.insertNewObject(in: moc)
                first.subject = "Italy Trip"
                first.message = "This is a draft message"
                first.lastModifiedDate = future

                second = MessageDraft.insertNewObject(in: moc)
                second.subject = "Message Draft"
                second.lastModifiedDate = now
            }

            // then
            let resultsController = sut.resultsController
            try resultsController.performFetch()

            do {
                guard let objects = resultsController.fetchedObjects else { return XCTFail("Failed to fetch drafts") }
                XCTAssertEqual(objects.count, 2)
                XCTAssertEqual(objects.first, first)
                XCTAssertEqual(objects.last, second)
            }

            // when
            sut.perform { _ in
                second.lastModifiedDate = future.addingTimeInterval(20)
            }

            // then
            try resultsController.performFetch()

            do {
                guard let objects = resultsController.fetchedObjects else { return XCTFail("Failed to fetch drafts") }
                XCTAssertEqual(objects.count, 2)
                XCTAssertEqual(objects.first, second)
                XCTAssertEqual(objects.last, first)
            }
        } catch {
            XCTFail("Unexpected error thrown: \(error)")
        }
    }
    
}
