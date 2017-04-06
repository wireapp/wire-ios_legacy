//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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
import SafariServices


private var lastPreviewURL: URL?


extension ConversationContentViewController: UIViewControllerPreviewingDelegate {

    @available(iOS 9.0, *)
    public func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let superview = self.view.superview,
              let cellIndexPath = self.tableView.indexPathForRow(at: self.tableView.convert(location, from: superview)),
              let message = self.messageWindow.messages[cellIndexPath.row] as? ZMConversationMessage else {
            return .none
        }

        lastPreviewURL = nil
        var controller: UIViewController?

        if message.isText, let url = message.textMessageData?.linkPreview?.openableURL as URL? {
            lastPreviewURL = url
            controller = SFSafariViewController(url: url)
        } else if message.isImage {
            controller = self.messagePresenter.viewController(forImageMessage: message, actionResponder: self)
        }

        if nil != controller, let cell = tableView.cellForRow(at: cellIndexPath) as? ConversationCell, cell.selectionRect != .zero {
            previewingContext.sourceRect = previewingContext.sourceView.convert(cell.selectionRect, from: cell.selectionView)
        }

        return controller
    }

    @available(iOS 9.0, *)
    public func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        // In case the user has set a 3rd party application to open the URL we do not 
        // want to commit the view controller but instead open the url.
        guard lastPreviewURL == nil || lastPreviewURL?.hasThirdPartyPreference() == false else { lastPreviewURL?.open(); return  }
        self.messagePresenter.modalTargetController?.present(viewControllerToCommit, animated: true, completion: .none)
    }

}
