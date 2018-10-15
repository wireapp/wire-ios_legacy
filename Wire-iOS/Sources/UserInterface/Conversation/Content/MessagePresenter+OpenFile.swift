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

import Foundation
import AVKit

fileprivate let zmLog = ZMSLog(tag: "MessagePresenter")

extension MessagePresenter {

    /// init method for injecting MediaPlaybackManager for testing
    ///
    /// - Parameter mediaPlaybackManager: for testing only
    convenience init(mediaPlaybackManager: MediaPlaybackManager? = AppDelegate.shared().mediaPlaybackManager) {
        self.init()

        self.mediaPlaybackManager = mediaPlaybackManager
    }
}

// MARK: - AVPlayerViewController dismissial
extension MessagePresenter {

    fileprivate func observePlayerDismissial() {
        videoPlayerObserver = NotificationCenter.default.addObserver(forName: .dismissingAVPlayer, object: nil, queue: OperationQueue.main) { notification in
            self.mediaPlayerController?.tearDown()

            UIViewController.attemptRotationToDeviceOrientation()

            if let videoPlayerObserver = self.videoPlayerObserver {
                NotificationCenter.default.removeObserver(videoPlayerObserver)
                self.videoPlayerObserver = nil
            }
        }
    }
}

extension MessagePresenter {

    @objc func openFileMessage(_ message: ZMConversationMessage, targetView: UIView) {

        let fileURL = message.fileMessageData?.fileURL

        if fileURL == nil || fileURL?.isFileURL == nil || fileURL?.path.count == 0 {
            assert(false, "File URL is missing: \(String(describing: fileURL)) (\(String(describing: message.fileMessageData)))")

            zmLog.error("File URL is missing: \(String(describing: fileURL)) (\(String(describing: message.fileMessageData))")
            ZMUserSession.shared()?.enqueueChanges({
                message.fileMessageData?.requestFileDownload()
            })
            return
        }

        _ = message.startSelfDestructionIfNeeded()

        if let fileMessageData = message.fileMessageData, fileMessageData.isPass,
           let addPassesViewController = createAddPassesViewController(fileMessageData: fileMessageData) {
            targetViewController?.present(addPassesViewController, animated: true)

        } else if let fileMessageData = message.fileMessageData, fileMessageData.isVideo,
                  let fileURL = fileURL,
                  let mediaPlaybackManager = mediaPlaybackManager {
            let player = AVPlayer(url: fileURL)
            mediaPlayerController = MediaPlayerController(player: player, message: message, delegate: mediaPlaybackManager)
            let playerViewController = AVPlayerViewController()
            playerViewController.player = player

            observePlayerDismissial()

            targetViewController?.present(playerViewController, animated: true) {
                UIApplication.shared.wr_updateStatusBarForCurrentControllerAnimated(true)
                player.play()
            }
        } else {
            openDocumentController(for: message, targetView: targetView, withPreview: true)
        }
    }
}
