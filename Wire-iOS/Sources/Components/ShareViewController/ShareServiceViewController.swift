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
import WireExtensionComponents

class ShareServiceViewController: ShareViewController<ServiceConversation,Service> {
    
    // MARK: - Actions
    
    public var onServiceDismiss: ((ShareServiceViewController, Bool, AddBotResult?)->())?
    
    override public func onCloseButtonPressed(sender: AnyObject?) {
        self.onServiceDismiss?(self, false, nil)
    }
    
    override public func onSendButtonPressed(sender: AnyObject?) {
        if self.selectedDestinations.count > 0 {
            self.shareable.share(to: Array(self.selectedDestinations), completion: { (result) in
                self.onServiceDismiss?(self, true, result)
            })
        }
    }
}
