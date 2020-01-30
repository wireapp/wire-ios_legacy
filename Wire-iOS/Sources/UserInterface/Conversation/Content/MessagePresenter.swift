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

private let zmLog = ZMSLog(tag: "MessagePresenter")

final class MessagePresenter: NSObject {
    
    /// Container of the view that hosts popover controller.
    @objc
    weak var targetViewController: UIViewController?
    
    /// Controller that would be the modal parent of message details.
    @objc
    weak var modalTargetController: UIViewController?
    private(set) var waitingForFileDownload = false
    
    var mediaPlayerController: MediaPlayerController?
    var mediaPlaybackManager: MediaPlaybackManager?
    var videoPlayerObserver: NSObjectProtocol?
    var fileAvailabilityObserver: MessageKeyPathObserver?
    
    private var documentInteractionController: UIDocumentInteractionController?
    
    func openDocumentController(for message: ZMConversationMessage,
                                targetView: UIView,
                                withPreview preview: Bool) {
        let fileURL = message.fileMessageData?.fileURL
        
        if fileURL == nil ||
            fileURL?.isFileURL == false ||
            fileURL?.path.isEmpty == true {
            
            let errorMessage = "File URL is missing: \(fileURL?.debugDescription) (\(message.fileMessageData.debugDescription))"
            assert(false, errorMessage)
            
            zmLog.error(errorMessage)
            ZMUserSession.shared()?.enqueueChanges({
                message.fileMessageData?.requestFileDownload()
            })
            return
        }
        
        // Need to create temporary hardlink to make sure the UIDocumentInteractionController shows the correct filename
        var tmpPath = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(message.fileMessageData?.filename ?? "").absoluteString
        
        if let path = fileURL?.path {
            do {
                try FileManager.default.linkItem(atPath: path, toPath: tmpPath)
            } catch {
                zmLog.error("Cannot symlink \(path) to \(tmpPath): \(error)")
                tmpPath = path
            }
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
