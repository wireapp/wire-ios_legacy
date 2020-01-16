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
    @objc
    convenience init(mediaPlaybackManager: MediaPlaybackManager? = AppDelegate.shared.mediaPlaybackManager) {
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
        
        if !message.isFileDownloaded() {
            message.fileMessageData?.requestFileDownload()
            
            fileAvailabilityObserver = MessageKeyPathObserver(message: message, keypath: \.fileAvailabilityChanged) { [weak self] (message) in
                guard message.isFileDownloaded() else { return }
            
                self?.openFileMessage(message, targetView: targetView)
            }
            
            return
        }

        guard let fileURL = message.fileMessageData?.fileURL else { return }

        _ = message.startSelfDestructionIfNeeded()

        if let fileMessageData = message.fileMessageData, fileMessageData.isPass,
           let addPassesViewController = createAddPassesViewController(fileMessageData: fileMessageData) {
            targetViewController?.present(addPassesViewController, animated: true)

        } else if let fileMessageData = message.fileMessageData, fileMessageData.isVideo,
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

    /// Target view must be container in @c targetViewController's view.
    ///
    /// - Parameters:
    ///   - message: message to open
    ///   - targetView: target view when opens the message
    ///   - delegate: the receiver of action callbacks for the message. Currently only forward and reveal in conversation actions are supported.
    func open(_ message: ZMConversationMessage, targetView: UIView, actionResponder delegate: MessageActionResponder) {
        fileAvailabilityObserver = nil
        modalTargetController?.view.window?.endEditing(true)

        if Message.isLocation(message) {
            openLocationMessage(message)
        } else if Message.isFileTransfer(message) {
            openFileMessage(message, targetView: targetView)
        } else if Message.isImage(message) {
            openImageMessage(message, actionResponder: delegate)
        } else if let openableURL = message.textMessageData?.linkPreview?.openableURL {
            openableURL.open()
        }
    }

    func openLocationMessage(_ message: ZMConversationMessage) {
        if let locationMessageData = message.locationMessageData {
            Message.openInMaps(locationMessageData)
        }
    }

    func openImageMessage(_ message: ZMConversationMessage, actionResponder delegate: MessageActionResponder) {
        let imageViewController = viewController(forImageMessage: message, actionResponder: delegate)
        if let imageViewController = imageViewController {
            modalTargetController?.present(imageViewController, animated: true)
        }
    }

    func viewController(forImageMessage message: ZMConversationMessage, actionResponder delegate: MessageActionResponder) -> UIViewController? {
        guard Message.isImage(message),
              message.imageMessageData != nil else {
            return nil
        }

        return imagesViewController(for: message, actionResponder: delegate, isPreviewing: false)
    }

    func viewController(forImageMessagePreview message: ZMConversationMessage, actionResponder delegate: MessageActionResponder) -> UIViewController? {
        guard Message.isImage(message),
            message.imageMessageData != nil else {
                return nil
        }

        return imagesViewController(for: message, actionResponder: delegate, isPreviewing: true)
    }

}
