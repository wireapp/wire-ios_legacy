//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

@objc public class SelectableScrollView: UIScrollView, SelectableView {
    public var selectionView: UIView! {
        return self
    }

    public var selectionRect: CGRect {
        return bounds
    }
}

extension FullscreenImageViewController: MessageActionResponder {
    public func perform(action: MessageAction, for message: ZMConversationMessage!, sourceView: UIView!) {
        switch action {
        case .forward,
             .showInConversation,
             .reply:
            dismiss() {
                self.delegate?.perform(action: action, for: message, sourceView: self.scrollView)
            }
        case .openDetails:
            let detailsViewController = MessageDetailsViewController(message: message)
            present(detailsViewController, animated: true)
        default:
            delegate?.perform(action: action, for: message, sourceView: scrollView)
        }
    }
}


extension FullscreenImageViewController {
    @objc(performForAction:)
    func perform(action: MessageAction) {
        delegate?.perform(action: action, for: message, sourceView: view)
    }
}
