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

fileprivate let zmLog = ZMSLog(tag: "MessagePresenter")

// create an extension of AVPlayerViewController
extension AVPlayerViewController {
    override open var prefersStatusBarHidden: Bool {
        get {
            return true;
        }
    }

    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        guard self.isBeingDismissed else {
            return
        }

        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "DismissingAVPlayer"), object: self)
    }
}

extension MessagePresenter {
    @objc func playerDismissed(notification: Notification) {
        mediaPlayerController?.tearDown()

        if let rotationAwareNavigationController = targetViewController as? RotationAwareNavigationController {
            rotationAwareNavigationController.isPresentingPlayer = false
        }

        UIViewController.attemptRotationToDeviceOrientation()

            if let rotationAwareNavigationController = self.targetViewController as? RotationAwareNavigationController {
                if let collectionViewController = (rotationAwareNavigationController.topViewController! as! KeyboardAvoidingViewController).viewController as? CollectionsViewController {
                    collectionViewController.isPresentingPlayer = false
                }
            }

        ///TODO
//        NotificationCenter.default.remove
    }

    func observePlayerDismissial() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(playerDismissed(notification:)),
                                               name: NSNotification.Name(rawValue: "DismissingAVPlayer"),
                                               object: nil)

    }

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
                  let mediaPlaybackManager = AppDelegate.shared().mediaPlaybackManager {
            let player = AVPlayer(url: fileURL)
            mediaPlayerController = MediaPlayerController(player: player, message: message, delegate: mediaPlaybackManager)
            let playerViewController = AVPlayerViewController()
            playerViewController.player = player

            if let rotationAwareNavigationController = targetViewController as? RotationAwareNavigationController {
                rotationAwareNavigationController.isPresentingPlayer = true
            }

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
