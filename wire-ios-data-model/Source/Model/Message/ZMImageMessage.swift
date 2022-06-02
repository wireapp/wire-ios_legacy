//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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

extension ZMImageMessage {
    /// Request the download of the image if not already present.
    /// The download will be executed asynchronously. The caller can be notified by observing the message window.
    /// This method can safely be called multiple times, even if the content is already available locally
    public func requestFileDownload() {
        // V2

        // objects with temp ID on the UI must just have been inserted so no need to download
        if objectID.isTemporaryID {
            return
        }

        if let moc = managedObjectContext?.zm_userInterface {
            let note = NotificationInContext(
                name: ZMAssetClientMessage.imageDownloadNotificationName,
                context: moc.notificationContext,
                object: objectID,
                userInfo: nil)
            note.post()
        }
    }
}
