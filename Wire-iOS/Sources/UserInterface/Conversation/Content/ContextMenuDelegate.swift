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

import UIKit
import WireDataModel

protocol ContextMenuDelegate: class {
    var delegate: ConversationMessageCellDelegate? { get }
    var message: ZMConversationMessage? { get }

    @available(iOS 13.0, *)
    func makeContextMenu(title: String, view: UIView) -> UIMenu
}

@available(iOS 13.0, *)
extension ContextMenuDelegate {
    func makeContextMenu(title: String, view: UIView) -> UIMenu {
        let actions = actionController(view: view)?.allMessageMenuElements() ?? []

        return UIMenu(title: title, children: actions)
    }

    private func actionController(view: UIView) -> ConversationMessageActionController? {
        guard let message = message else {
            return nil
        }

        return ConversationMessageActionController(responder: delegate,
                                                   message: message,
                                                   context: .content,
                                                   view: view)
    }

}

@available(iOS 13.0, *)
extension ContextMenuDelegate where Self: LinkViewDelegate {
    func linkPreviewContextMenu(view: UIView) -> UIContextMenuConfiguration? {
        guard let url = url else {
            return nil
        }

        let previewProvider: UIContextMenuContentPreviewProvider = {
            return BrowserViewController(url: url)
        }

        return UIContextMenuConfiguration(identifier: nil,
                                          previewProvider: previewProvider,
                                          actionProvider: { _ in
                                            return self.makeContextMenu(title: url.absoluteString, view: view)
        })

    }
}
