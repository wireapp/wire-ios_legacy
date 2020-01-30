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

final class MessagePresenter: NSObject {
    /// Container of the view that hosts popover controller.
    weak var targetViewController: UIViewController?
    /// Controller that would be the modal parent of message details.
    weak var modalTargetController: UIViewController?
    private(set) var waitingForFileDownload = false
    
    private var mediaPlayerController: MediaPlayerController?
    private var mediaPlaybackManager: MediaPlaybackManager?
    private weak var videoPlayerObserver: NSObjectProtocol?
    private var fileAvailabilityObserver: Any?
    
    private var documentInteractionController: UIDocumentInteractionController?

    func openDocumentController(for message: ZMConversationMessage?, targetView: UIView?, withPreview preview: Bool) {
        if message?.fileMessageData.fileURL == nil || message?.fileMessageData.fileURL.isFileURL() == nil || message?.fileMessageData.fileURL.path.length == 0 {
            if let fileURL = message?.fileMessageData.fileURL, let fileMessageData = message?.fileMessageData {
                assert(false, "File URL is missing: \(fileURL) (\(fileMessageData))")
            }
            ZMLogError("File URL is missing: %@ (%@)", message?.fileMessageData.fileURL, message?.fileMessageData)
            ZMUserSession.shared().enqueueChanges({
                message?.fileMessageData.requestFileDownload()
            })
            return
        }
        
        // Need to create temporary hardlink to make sure the UIDocumentInteractionController shows the correct filename
        var error: Error? = nil
        var tmpPath = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(message?.fileMessageData.filename ?? "").absoluteString
        do {
            try FileManager.default.linkItem(atPath: message?.fileMessageData.fileURL.path ?? "", toPath: tmpPath)
        } catch {
        }
        if nil != error {
            ZMLogError("Cannot symlink %@ to %@: %@", message?.fileMessageData.fileURL.path, tmpPath, error)
            tmpPath = message?.fileMessageData.fileURL.path ?? ""
        }
        
        documentInteractionController = UIDocumentInteractionController(url: URL(fileURLWithPath: tmpPath))
        documentInteractionController.delegate = self
        if !preview || !documentInteractionController.presentPreview(animated: true) {
            
            documentInteractionController.presentOptionsMenu(from: targetViewController.view.convert(targetView?.bounds ?? CGRect.zero, from: targetView), in: targetViewController.view, animated: true)
        }
    }
    
    func cleanupTemporaryFileLink() {
        var linkDeleteError: Error? = nil
        do {
            try FileManager.default.removeItem(at: documentInteractionController.url)
        } catch let linkDeleteError {
        }
        if linkDeleteError != nil {
            ZMLogError("Cannot delete temporary link %@: %@", documentInteractionController.url, linkDeleteError)
        }
    }
    
}

extension MessagePresenter: UIDocumentInteractionControllerDelegate {
    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        return modalTargetController
    }
    
    func documentInteractionControllerWillBeginPreview(_ controller: UIDocumentInteractionController) {
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
