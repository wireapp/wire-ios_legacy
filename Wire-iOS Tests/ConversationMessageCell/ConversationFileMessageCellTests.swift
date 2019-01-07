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

class ConversationFileMessageTests: ConversationCellSnapshotTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        defaultImageCache.cache.removeAllObjects()
        super.tearDown()
    }
    
    func testUploadedCell_fromThisDevice() {
        let message = MockMessageFactory.fileTransferMessage()!
        message.backingFileMessageData.transferState = .uploaded
        message.backingFileMessageData.fileURL = Bundle.main.bundleURL
        
        verify(message: message)
    }
    
    func testUploadedCell_fromOtherDevice() {
        let message = MockMessageFactory.fileTransferMessage()!
        message.backingFileMessageData.transferState = .uploaded
        message.backingFileMessageData.fileURL = nil
        
        verify(message: message)
    }
    
    func testUploadedCell_fromOtherUser() {
        let message = MockMessageFactory.fileTransferMessage()!
        message.sender = MockUser.mockUsers().first!
        message.backingFileMessageData.transferState = .uploaded
        message.backingFileMessageData.fileURL = nil
        
        verify(message: message)
    }
    
    func testUploadedCell_fromThisDevice_longFileName() {
        let message = MockMessageFactory.fileTransferMessage()!
        message.sender = MockUser.mockUsers().first!
        message.backingFileMessageData.transferState = .uploaded
        message.backingFileMessageData.fileURL = Bundle.main.bundleURL
        message.backingFileMessageData.filename = "Etiam lacus elit, tempor at blandit sit amet, faucibus in erat. Mauris faucibus scelerisque mattis.pdf"
        
        verify(message: message)
    }
    
    func testUploadedCell_fromThisDevice_bigFileSize() {
        let message = MockMessageFactory.fileTransferMessage()!
        message.backingFileMessageData.transferState = .uploaded
        message.backingFileMessageData.fileURL = nil
        (message.backingFileMessageData as! MockFileMessageData).size = UInt64(1024 * 1024 * 25)
        
        verify(message: message)
    }
    
    
    func testUploadingCell_fromThisDevice() {
        let message = MockMessageFactory.fileTransferMessage()!
        message.backingFileMessageData.transferState = .uploading
        message.backingFileMessageData.fileURL = Bundle.main.bundleURL
        
        verify(message: message)
    }
    
    func testUploadingCell_fromOtherDevice() {
        let message = MockMessageFactory.fileTransferMessage()!
        message.backingFileMessageData.transferState = .uploading
        message.backingFileMessageData.fileURL = nil
        
        verify(message: message)
    }
    
    func testUploadingCell_fromOtherUser() {
        let message = MockMessageFactory.fileTransferMessage()!
        message.sender = MockUser.mockUsers()?.first!
        message.backingFileMessageData.transferState = .uploading
        message.backingFileMessageData.fileURL = nil
        
        
        verify(message: message)
    }
    
    func testDownloadingCell_fromThisDevice() {
        let message = MockMessageFactory.fileTransferMessage()!
        message.backingFileMessageData.transferState = .downloading
        message.backingFileMessageData.progress = 0.75
        message.backingFileMessageData.fileURL = Bundle.main.bundleURL
        
        verify(message: message)
    }
    
    func testDownloadingCell_fromOtherDevice() {
        let message = MockMessageFactory.fileTransferMessage()!
        message.backingFileMessageData.transferState = .downloading
        message.backingFileMessageData.progress = 0.75
        message.backingFileMessageData.fileURL = nil
        
        verify(message: message)
    }
    
    func testDownloadingCell_fromOtherUser() {
        let message = MockMessageFactory.fileTransferMessage()!
        message.sender = MockUser.mockUsers()?.first!
        message.backingFileMessageData.transferState = .downloading
        message.backingFileMessageData.progress = 0.75
        message.backingFileMessageData.fileURL = nil
        
        verify(message: message)
    }
    
    func testDownloadedCell_fromThisDevice() {
        let message = MockMessageFactory.fileTransferMessage()!
        message.backingFileMessageData.transferState = .downloaded
        message.backingFileMessageData.fileURL = Bundle.main.bundleURL
        
        verify(message: message)
    }
    
    func testDownloadedCell_fromOtherDevice() {
        let message = MockMessageFactory.fileTransferMessage()!
        message.backingFileMessageData.transferState = .downloaded
        message.backingFileMessageData.fileURL = nil
        
        verify(message: message)
    }
    
    func testDownloadedCell_fromOtherUser() {
        let message = MockMessageFactory.fileTransferMessage()!
        message.sender = MockUser.mockUsers()?.first!
        message.backingFileMessageData.transferState = .downloaded
        message.backingFileMessageData.fileURL = nil
        
        verify(message: message)
    }
    
    func testFailedDownloadCell_fromThisDevice() {
        let message = MockMessageFactory.fileTransferMessage()!
        message.backingFileMessageData.transferState = .failedDownload
        message.backingFileMessageData.fileURL = Bundle.main.bundleURL
        
        verify(message: message)
    }
    
    func testFailedDownloadCell_fromOtherDevice() {
        let message = MockMessageFactory.fileTransferMessage()!
        message.backingFileMessageData.transferState = .failedDownload
        message.backingFileMessageData.fileURL = nil
        
        verify(message: message)
    }
    
    func testFailedDownloadCell_fromOtherUser() {
        let message = MockMessageFactory.fileTransferMessage()!
        message.sender = MockUser.mockUsers()?.first!
        message.backingFileMessageData.transferState = .failedDownload
        message.backingFileMessageData.fileURL = nil
        
        verify(message: message)
    }
    
    func testFailedUploadCell_fromThisDevice() {
        let message = MockMessageFactory.fileTransferMessage()!
        message.backingFileMessageData.transferState = .failedUpload
        message.backingFileMessageData.fileURL = Bundle.main.bundleURL
        
        verify(message: message)
    }
    
    func testFailedUploadCell_fromOtherDevice() {
        let message = MockMessageFactory.fileTransferMessage()!
        message.backingFileMessageData.transferState = .failedUpload
        message.backingFileMessageData.fileURL = nil
        
        verify(message: message)
    }
    
    func testFailedUploadCell_fromOtherUser() {
        let message = MockMessageFactory.fileTransferMessage()!
        message.sender = MockUser.mockUsers()?.first!
        message.backingFileMessageData.transferState = .failedUpload
        message.backingFileMessageData.fileURL = nil
        
        verify(message: message)
    }
    
    // MARK : Upload Cancelled
    
    func testCancelledUploadCell_fromThisDevice() {
        let message = MockMessageFactory.fileTransferMessage()!
        message.backingFileMessageData.transferState = .cancelledUpload
        message.backingFileMessageData.fileURL = Bundle.main.bundleURL
        
        verify(message: message)
    }
    
    // MARK : Obfuscated
    
    func testObfuscatedFileTransferCell() {
        let message = MockMessageFactory.fileTransferMessage()!
        message.isObfuscated = true
        message.backingFileMessageData.transferState = .uploaded
        message.backingFileMessageData.fileURL = Bundle.main.bundleURL
        
        verify(message: message)
    }
    
}

