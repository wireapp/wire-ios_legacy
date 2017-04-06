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
import WireSyncEngine
import WireMessageStrategy


@objc class AnalyticsFileTransferObserver: NSObject {
    let analyticsTracker: AnalyticsTracker = AnalyticsTracker(context: "")
    
    override init() {
        super.init()
        
        NotificationCenter.default.addObserver(self, selector: #selector(AnalyticsFileTransferObserver.uploadFinishedNotification(_:)), name: NSNotification.Name(rawValue: FileUploadRequestStrategyNotification.uploadFinishedNotificationName), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(AnalyticsFileTransferObserver.uploadFailedNotification(_:)), name: NSNotification.Name(rawValue: FileUploadRequestStrategyNotification.uploadFailedNotificationName), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(AnalyticsFileTransferObserver.downloadFinishedNotification(_:)), name: NSNotification.Name(rawValue: AssetDownloadRequestStrategyNotification.downloadFinishedNotificationName), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(AnalyticsFileTransferObserver.downloadFailedNotification(_:)), name: NSNotification.Name(rawValue: AssetDownloadRequestStrategyNotification.downloadFailedNotificationName), object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func uploadFinishedNotification(_ notification: Notification?) {
        guard let message = notification?.object as? ZMConversationMessage,
              let startTime = notification?.userInfo?[FileUploadRequestStrategyNotification.requestStartTimestampKey] as? NSDate,
              let fileMessageData = message.fileMessageData else {
                assert(true)
                return
        }
        
        self.analyticsTracker.tagSucceededFileUpload(
            withSize: fileMessageData.size,
            in: message.conversation,
            fileExtension: (fileMessageData.filename as NSString).pathExtension,
            duration: fabs(startTime.timeIntervalSinceNow)
        )
    }
    
    func uploadFailedNotification(_ notification: Notification?) {
        guard let message = notification?.object as? ZMConversationMessage,
              let fileMessageData = message.fileMessageData else {
                assert(true)
                return
        }
        
        self.analyticsTracker.tagFailedFileUpload(withSize: fileMessageData.size, fileExtension: (fileMessageData.filename as NSString).pathExtension)
    }
    
    func downloadFinishedNotification(_ notification: Notification?) {
        guard let message = notification?.object as? ZMConversationMessage,
            let startTime = notification?.userInfo?[AssetDownloadRequestStrategyNotification.downloadStartTimestampKey] as? NSDate,
            let fileMessageData = message.fileMessageData else {
                assert(true)
                return
        }
        
        self.analyticsTracker.tagSuccededFileDownload(
            withSize: fileMessageData.size, message: message,
            fileExtension: (fileMessageData.filename as NSString).pathExtension,
            duration: fabs(startTime.timeIntervalSinceNow)
        )
    }
    
    func downloadFailedNotification(_ notification: Notification?) {
        guard let message = notification?.object as? ZMConversationMessage,
            let fileMessageData = message.fileMessageData else {
                assert(true)
                return
        }
        
        self.analyticsTracker.tagFailedFileDownload(withSize: fileMessageData.size, fileExtension: (fileMessageData.filename as NSString).pathExtension)
    }
    
}

