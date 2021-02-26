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

@testable import Wire

import XCTest

final class ConversationFileMessageTests: XCTestCase {

    var message: MockMessage!
    var mockSelfUser: MockUserType!

    override func setUp() {
        super.setUp()

        UIColor.setAccentOverride(.vividRed)

        mockSelfUser = MockUserType.createDefaultSelfUser()
        message = MockMessageFactory.fileTransferMessage(sender: mockSelfUser)
    }

    override func tearDown() {
        message = nil
        mockSelfUser = nil
        MediaAssetCache.defaultImageCache.cache.removeAllObjects()

        super.tearDown()
    }

    func testUploadedCell_fromThisDevice() {
        message.backingFileMessageData.transferState = .uploaded
        message.backingFileMessageData.fileURL = Bundle.main.bundleURL

        verify(message: message)
    }

    func testUploadedCell_fromOtherDevice() {
        message.backingFileMessageData.transferState = .uploaded
        message.backingFileMessageData.fileURL = nil

        verify(message: message)
    }

    func testUploadedCell_fromOtherUser() {
        message.senderUser = SwiftMockLoader.mockUsers().first!
        message.backingFileMessageData.transferState = .uploaded
        message.backingFileMessageData.fileURL = nil

        verify(message: message)
    }

    func testUploadedCell_fromThisDevice_longFileName() {
        message.senderUser = SwiftMockLoader.mockUsers().first!
        message.backingFileMessageData.transferState = .uploaded
        message.backingFileMessageData.fileURL = Bundle.main.bundleURL
        message.backingFileMessageData.filename = "Etiam lacus elit, tempor at blandit sit amet, faucibus in erat. Mauris faucibus scelerisque mattis.pdf"

        verify(message: message)
    }

    func testUploadedCell_fromThisDevice_bigFileSize() {
        message.backingFileMessageData.transferState = .uploaded
        message.backingFileMessageData.fileURL = nil
        (message.backingFileMessageData as! MockFileMessageData).size = UInt64(1024 * 1024 * 25)

        verify(message: message)
    }

    func testUploadingCell_fromThisDevice() {
        message.backingFileMessageData.transferState = .uploading
        message.backingFileMessageData.fileURL = Bundle.main.bundleURL

        verify(message: message)
    }

    func testUploadingCell_fromOtherDevice() {
        message.backingFileMessageData.transferState = .uploading
        message.backingFileMessageData.fileURL = nil

        verify(message: message)
    }

    func testUploadingCell_fromOtherUser() {
        message.senderUser = SwiftMockLoader.mockUsers().first!
        message.backingFileMessageData.transferState = .uploading
        message.backingFileMessageData.fileURL = nil

        verify(message: message)
    }

    func testDownloadingCell_fromThisDevice() {
        message.backingFileMessageData.transferState = .uploaded
        message.backingFileMessageData.downloadState = .downloading
        message.backingFileMessageData.progress = 0.75
        message.backingFileMessageData.fileURL = Bundle.main.bundleURL

        verify(message: message)
    }

    func testDownloadingCell_fromOtherDevice() {
        message.backingFileMessageData.transferState = .uploaded
        message.backingFileMessageData.downloadState = .downloading
        message.backingFileMessageData.progress = 0.75
        message.backingFileMessageData.fileURL = nil

        verify(message: message)
    }

    func testDownloadingCell_fromOtherUser() {
        message.senderUser = SwiftMockLoader.mockUsers().first!
        message.backingFileMessageData.transferState = .uploaded
        message.backingFileMessageData.downloadState = .downloading
        message.backingFileMessageData.progress = 0.75
        message.backingFileMessageData.fileURL = nil

        verify(message: message)
    }

    func testDownloadedCell_fromThisDevice() {
        message.backingFileMessageData.transferState = .uploaded
        message.backingFileMessageData.downloadState = .downloaded
        message.backingFileMessageData.fileURL = Bundle.main.bundleURL

        verify(message: message)
    }

    func testDownloadedCell_fromOtherDevice() {
        message.backingFileMessageData.transferState = .uploaded
        message.backingFileMessageData.downloadState = .downloaded
        message.backingFileMessageData.fileURL = nil

        verify(message: message)
    }

    func testDownloadedCell_fromOtherUser() {
        message.senderUser = SwiftMockLoader.mockUsers().first!
        message.backingFileMessageData.transferState = .uploaded
        message.backingFileMessageData.downloadState = .downloaded
        message.backingFileMessageData.fileURL = nil

        verify(message: message)
    }

    func testDownloadedCell_zeroBytes() {
        let message = MockMessage()
        message.backingFileMessageData = MockFileMessageData()
        message.backingFileMessageData.size = 0
        message.backingFileMessageData.transferState = .uploaded
        message.backingFileMessageData.downloadState = .downloaded

        verify(message: message)
    }

    func testFailedDownloadCell_fromThisDevice() {
        message.backingFileMessageData.transferState = .uploaded
        message.backingFileMessageData.downloadState = .remote
        message.backingFileMessageData.fileURL = Bundle.main.bundleURL

        verify(message: message)
    }

    func testFailedDownloadCell_fromOtherDevice() {
        message.backingFileMessageData.transferState = .uploaded
        message.backingFileMessageData.downloadState = .remote
        message.backingFileMessageData.fileURL = nil

        verify(message: message)
    }

    func testFailedDownloadCell_fromOtherUser() {
        message.senderUser = SwiftMockLoader.mockUsers().first!
        message.backingFileMessageData.transferState = .uploaded
        message.backingFileMessageData.downloadState = .remote
        message.backingFileMessageData.fileURL = nil

        verify(message: message)
    }

    func testFailedUploadCell_fromThisDevice() {
        message.backingFileMessageData.transferState = .uploadingFailed
        message.backingFileMessageData.fileURL = Bundle.main.bundleURL

        verify(message: message)
    }

    func testFailedUploadCell_fromOtherDevice() {
        message.backingFileMessageData.transferState = .uploadingFailed
        message.backingFileMessageData.fileURL = nil

        verify(message: message)
    }

    func testFailedUploadCell_fromOtherUser() {
        message.senderUser = SwiftMockLoader.mockUsers().first!
        message.backingFileMessageData.transferState = .uploadingFailed
        message.backingFileMessageData.fileURL = nil

        verify(message: message)
    }

    // MARK : Upload Cancelled

    func testCancelledUploadCell_fromThisDevice() {
        message.backingFileMessageData.transferState = .uploadingCancelled
        message.backingFileMessageData.fileURL = Bundle.main.bundleURL

        verify(message: message)
    }

    // MARK : Obfuscated

    func testObfuscatedFileTransferCell() {
        message.isObfuscated = true
        message.backingFileMessageData.transferState = .uploaded
        message.backingFileMessageData.fileURL = Bundle.main.bundleURL

        verify(message: message)
    }

}
