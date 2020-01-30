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

    func openDocumentController(for message: ZMConversationMessage?, targetView: UIView, withPreview preview: Bool) {
    }
}

extension MessagePresenter: UIDocumentInteractionControllerDelegate {
}
