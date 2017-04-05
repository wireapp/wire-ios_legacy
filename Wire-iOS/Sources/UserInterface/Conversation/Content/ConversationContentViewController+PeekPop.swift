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

extension ConversationContentViewController: UIViewControllerPreviewingDelegate {

    @available(iOS 9.0, *)
    public func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let superview = self.view.superview,
              let cellIndexPath = self.tableView.indexPathForRow(at: self.tableView.convert(location, from: superview)),
              let message = self.messageWindow.messages[cellIndexPath.row] as? ZMConversationMessage else {
            return .none
        }
        
        if message.isImage {
            let controller = self.messagePresenter.viewController(forImageMessage: message, actionResponder: self)
            if let cell = tableView.cellForRow(at: cellIndexPath) as? ConversationCell, cell.selectionRect != .zero {
                previewingContext.sourceRect = previewingContext.sourceView.convert(cell.selectionRect, from: cell)
            }
            return controller
        }
        
        return .none
    }

    @available(iOS 9.0, *)
    public func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        self.messagePresenter.modalTargetController?.present(viewControllerToCommit, animated: true, completion: .none)
    }    
}
