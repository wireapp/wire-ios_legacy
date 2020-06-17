//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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
import PassKit
import WireSyncEngine

private let zmLog = ZMSLog(tag: "MessagePresenter")

final class MessagePresenter: NSObject {

    /// Container of the view that hosts popover controller.
    weak var targetViewController: UIViewController?

    /// Controller that would be the modal parent of message details.
    weak var modalTargetController: UIViewController?
    private(set) var waitingForFileDownload = false

    var mediaPlayerController: MediaPlayerController?
    var mediaPlaybackManager: MediaPlaybackManager?
    var videoPlayerObserver: NSObjectProtocol?
    var fileAvailabilityObserver: MessageKeyPathObserver?

    private var documentInteractionController: UIDocumentInteractionController?

    /// init method for injecting MediaPlaybackManager for testing
    ///
    /// - Parameter mediaPlaybackManager: for testing only
    convenience init(mediaPlaybackManager: MediaPlaybackManager? = AppDelegate.shared.mediaPlaybackManager) {
        self.init()

        self.mediaPlaybackManager = mediaPlaybackManager
    }

    func openDocumentController(for message: ZMConversationMessage,
                                targetView: UIView,
                                withPreview preview: Bool) {
        guard let fileURL = message.fileMessageData?.fileURL,
              fileURL.isFileURL,
              !fileURL.path.isEmpty else {
            let errorMessage = "File URL is missing: \(message.fileMessageData?.fileURL.debugDescription ?? "") (\(message.fileMessageData.debugDescription))"
            assert(false, errorMessage)

            zmLog.error(errorMessage)
            ZMUserSession.shared()?.enqueue({
                message.fileMessageData?.requestFileDownload()
            })

            return
        }

        // Need to create temporary hardlink to make sure the UIDocumentInteractionController shows the correct filename
        var tmpPath = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(message.fileMessageData?.filename ?? "").absoluteString

        let path = fileURL.path

        do {
            try FileManager.default.linkItem(atPath: path, toPath: tmpPath)
        } catch {
            zmLog.error("Cannot symlink \(path) to \(tmpPath): \(error)")
            tmpPath = path
        }

        documentInteractionController = UIDocumentInteractionController(url: URL(fileURLWithPath: tmpPath))
        documentInteractionController?.delegate = self
        if (!preview || false == documentInteractionController?.presentPreview(animated: true)),
            let rect = targetViewController?.view.convert(targetView.bounds, from: targetView),
        let view = targetViewController?.view {

            documentInteractionController?.presentOptionsMenu(from: rect, in: view, animated: true)
        }
    }

    func cleanupTemporaryFileLink() {
        guard let url = documentInteractionController?.url else { return }
        do {
            try FileManager.default.removeItem(at: url)
        } catch let linkDeleteError {
            zmLog.error("Cannot delete temporary link \(url): \(linkDeleteError)")
        }
    }

// MARK: - AVPlayerViewController dismissial

    fileprivate func observePlayerDismissial() {
        videoPlayerObserver = NotificationCenter.default.addObserver(forName: .dismissingAVPlayer, object: nil, queue: OperationQueue.main) { _ in
            self.mediaPlayerController?.tearDown()

            UIViewController.attemptRotationToDeviceOrientation()

            if let videoPlayerObserver = self.videoPlayerObserver {
                NotificationCenter.default.removeObserver(videoPlayerObserver)
                self.videoPlayerObserver = nil
            }
        }
    }

    // MARK: - File

    func openFileMessage(_ message: ZMConversationMessage, targetView: UIView) {

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

    func openImageMessage(_ message: ZMConversationMessage,
                          actionResponder delegate: MessageActionResponder) {
        let imageViewController = viewController(forImageMessage: message, actionResponder: delegate)
        if let imageViewController = imageViewController {
            // to allow image rotation, present the image viewer in full screen style
            imageViewController.modalPresentationStyle = .fullScreen
            modalTargetController?.present(imageViewController, animated: true)
        }
    }

    func viewController(forImageMessage message: ZMConversationMessage, actionResponder delegate: MessageActionResponder) -> UIViewController? {
        guard Message.isImage(message),
            message.imageMessageData != nil else {
                return nil
        }

        return imagesViewController(for: message,
                                    actionResponder: delegate,
                                    isPreviewing: false)
    }

    func viewController(forImageMessagePreview message: ZMConversationMessage, actionResponder delegate: MessageActionResponder) -> UIViewController? {
        guard Message.isImage(message),
            message.imageMessageData != nil else {
                return nil
        }

        return imagesViewController(for: message, actionResponder: delegate, isPreviewing: true)
    }

    // MARK: - Pass

    func createAddPassesViewController(fileMessageData: ZMFileMessageData) -> PKAddPassesViewController? {
        guard let fileURL = fileMessageData.fileURL,
            let passData = try? Data.init(contentsOf: fileURL) else {
                return nil
        }

        guard let pass = try? PKPass.init(data: passData) else { return nil }

        if PKAddPassesViewController.canAddPasses() {
            return PKAddPassesViewController(pass: pass)
        } else {
            return nil
        }
    }
}

extension MessagePresenter: UIDocumentInteractionControllerDelegate {
    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        return modalTargetController!
    }

    func documentInteractionControllerDidEndPreview(_ controller: UIDocumentInteractionController) {
        cleanupTemporaryFileLink()
        documentInteractionController = nil
    }

    func documentInteractionControllerDidDismissOpenInMenu(_ controller: UIDocumentInteractionController) {
        cleanupTemporaryFileLink()
        documentInteractionController = nil
    }

    func documentInteractionControllerDidDismissOptionsMenu(_ controller: UIDocumentInteractionController) {
        cleanupTemporaryFileLink()
        documentInteractionController = nil
    }

}
