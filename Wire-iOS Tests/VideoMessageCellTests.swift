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


import XCTest
@testable import Wire

class VideoMessageCellTests: ZMSnapshotTestCase {
    
    func cellWithConfig(_ config: ((MockMessage) -> ())?) -> VideoMessageCell {
        
        let fileMessage = MockMessageFactory.fileTransferMessage()
        fileMessage.backingFileMessageData.mimeType = "video/mp4"
        fileMessage.backingFileMessageData.filename = "vacation.mp4"
        fileMessage.backingFileMessageData.previewData = UIImageJPEGRepresentation(imageInTestBundleNamed("unsplash_matterhorn.jpg"), 0.9)
        
        if let config = config {
            config(fileMessage)
        }
        
        let cell = VideoMessageCell(style: .default, reuseIdentifier: "test")
        
        let layoutProperties = ConversationCellLayoutProperties()
        layoutProperties.showSender = true
        layoutProperties.showBurstTimestamp = false
        layoutProperties.showUnreadMarker = false
        
        cell.prepareForReuse()
        cell.layer.speed = 0 // freeze animations for deterministic tests
        cell.bounds = CGRect(x: 0.0, y: 0.0, width: 320.0, height: 9999)
        cell.contentView.bounds = CGRect(x: 0.0, y: 0.0, width: 320, height: 9999)
        
        cell.layoutMargins = UIEdgeInsetsMake(0, CGFloat(WAZUIMagic.floatForIdentifier("content.left_margin")),
                                              0, CGFloat(WAZUIMagic.floatForIdentifier("content.right_margin")))
        
        cell.configureForMessage(fileMessage, layoutProperties: layoutProperties)
        cell.layoutIfNeeded()
        
        let size = cell.systemLayoutSizeFittingSize(CGSize(width: 320.0, height: 0.0) , withHorizontalFittingPriority: UILayoutPriorityRequired, verticalFittingPriority: UILayoutPriorityFittingSizeLevel)
        cell.bounds = CGRect(x: 0.0, y: 0.0, width: size.width, height: size.height)
        cell.layoutIfNeeded()
        return cell
    }
    
    override func setUp() {
        super.setUp()
        self.accentColor = .VividRed
    }
    
    // MARK : Uploaded (File not downloaded)
    
    func testUploadedCell_fromThisDevice() {
        let cell = self.cellWithConfig({
            $0.fileMessageData?.transferState = .Uploaded
            $0.backingFileMessageData.fileURL = Bundle.main.bundleURL
        })
        verify(view: cell)
    }
    
    func testUploadedCell_fromOtherUser() {
        let cell = self.cellWithConfig({
            $0.fileMessageData?.transferState = .Uploaded
            $0.backingFileMessageData.fileURL = .none
            $0.sender = (MockUser.mockUsers()[0] as! ZMUser)
        })
        verify(view: cell)
    }
    
    func testUploadedCell_fromOtherUser_withoutPreview() {
        let cell = self.cellWithConfig({
            $0.backingFileMessageData.previewData = nil
            $0.fileMessageData?.transferState = .Uploaded
            $0.backingFileMessageData.fileURL = .none
            $0.sender = (MockUser.mockUsers()[0] as! ZMUser)
        })
        verify(view: cell)
    }
    
    func testUploadedCell_fromThisDevice_bigFileSize() {
        let cell = self.cellWithConfig({
            $0.fileMessageData?.transferState = .Uploaded
            $0.fileMessageData?.size = 1024 * 1024 * 25
            $0.backingFileMessageData.fileURL = .none
        })
        verify(view: cell)
    }
    
    
    // MARK : Uploading
    
    func testUploadingCell_fromThisDevice() {
        let cell = self.cellWithConfig({
            $0.fileMessageData?.transferState = .Uploading
            $0.fileMessageData?.progress = 0.75
            $0.backingFileMessageData.fileURL = Bundle.main.bundleURL
        })
        verify(view: cell)
    }
    
    func testUploadingCell_fromOtherUser_withoutPreview() {
        let cell = self.cellWithConfig({
            $0.fileMessageData?.transferState = .Uploading
            $0.backingFileMessageData.previewData = nil
            $0.backingFileMessageData.fileURL = .none
            $0.sender = (MockUser.mockUsers()[0] as! ZMUser)
        })
        verify(view: cell)
    }
    
    func testUploadingCell_fromOtherUser() {
        let cell = self.cellWithConfig({
            $0.fileMessageData?.transferState = .Uploading
            $0.backingFileMessageData.fileURL = .none
            $0.sender = (MockUser.mockUsers()[0] as! ZMUser)
        })
        verify(view: cell)
    }
    
    // MARK : Downloading
    
    func testDownloadingCell_fromThisDevice() {
        let cell = self.cellWithConfig({
            $0.fileMessageData?.transferState = .Downloading
            $0.fileMessageData?.progress = 0.75
            $0.backingFileMessageData.fileURL = Bundle.main.bundleURL
        })
        verify(view: cell)
    }
    
    func testDownloadingCell_fromOtherUser() {
        let cell = self.cellWithConfig({
            $0.fileMessageData?.transferState = .Downloading
            $0.backingFileMessageData.fileURL = .none
            $0.fileMessageData?.progress = 0.75
            $0.sender = (MockUser.mockUsers()[0] as! ZMUser)
        })
        verify(view: cell)
    }
    
    // MARK : Downloaded
    
    func testDownloadedCell_fromThisDevice() {
        let cell = self.cellWithConfig({
            $0.fileMessageData?.transferState = .Downloaded
            $0.backingFileMessageData.fileURL = Bundle.main.bundleURL
        })
        verify(view: cell)
    }
    
    func testDownloadedCell_fromOtherUser() {
        let cell = self.cellWithConfig({
            $0.fileMessageData?.transferState = .Downloaded
            $0.backingFileMessageData.fileURL = .none
            $0.sender = (MockUser.mockUsers()[0] as! ZMUser)
        })
        verify(view: cell)
    }
    
    // MARK : Download Failed
    
    func testFailedDownloadCell_fromThisDevice() {
        let cell = self.cellWithConfig({
            $0.fileMessageData?.transferState = .FailedDownload
            $0.backingFileMessageData.fileURL = Bundle.main.bundleURL
        })
        verify(view: cell)
    }
    
    func testFailedDownloadCell_fromOtherUser() {
        let cell = self.cellWithConfig({
            $0.fileMessageData?.transferState = .FailedDownload
            $0.backingFileMessageData.fileURL = .none
            $0.sender = (MockUser.mockUsers()[0] as! ZMUser)
        })
        verify(view: cell)
    }
    
    // MARK : Upload Failed
    
    func testFailedUploadCell_fromThisDevice() {
        let cell = self.cellWithConfig({
            $0.fileMessageData?.transferState = .FailedUpload
            $0.backingFileMessageData.fileURL = Bundle.main.bundleURL
        })
        verify(view: cell)
    }
    
    func testFailedUploadCell_fromOtherUser() {
        let cell = self.cellWithConfig({
            $0.fileMessageData?.transferState = .FailedUpload
            $0.backingFileMessageData.fileURL = .none
            $0.sender = (MockUser.mockUsers()[0] as! ZMUser)
        })
        verify(view: cell)
    }
    
    // MARK : Upload Cancelled
    
    func testCancelledUploadCell_fromThisDevice() {
        let cell = cellWithConfig {
            $0.fileMessageData?.transferState = .CancelledUpload
            $0.backingFileMessageData.fileURL = Bundle.main.bundleURL
        }
        
        verify(view: cell)
    }
    
    func testCancelledUploadCell_fromOtherUser() {
        let cell = cellWithConfig {
            $0.fileMessageData?.transferState = .CancelledUpload
            $0.backingFileMessageData.fileURL = .none
            $0.sender = (MockUser.mockUsers()[0] as! ZMUser)
        }
        
        verify(view: cell)
    }
    
    // MARK: No Duration
    
    func testDownloadedCell_fromThisDevice_NoDuration() {
        verify(view: cellWithConfig {
            $0.fileMessageData?.transferState = .Downloaded
            $0.backingFileMessageData.fileURL = NSBundle.mainBundle().bundleURL
            $0.backingFileMessageData?.durationMilliseconds = 0
        })
    }
    
}
