//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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

open class CollectionCell: UICollectionViewCell, Reusable {
    var message: ZMConversationMessage? = .none {
        didSet {
            ZMMessageNotification.removeMessageObserver(for: self.messageObserverToken)
            self.messageObserverToken = ZMMessageNotification.add(self, for: self.message)
            self.updateForMessage(changeInfo: .none)
        }
    }
    
    deinit {
        ZMMessageNotification.removeMessageObserver(for: self.messageObserverToken)
    }
    
    var messageObserverToken: ZMMessageObserverOpaqueToken? = .none

    /// To be implemented in the subclass
    func updateForMessage(changeInfo: MessageChangeInfo?) {
        // no-op
    }
}

extension CollectionCell: ZMMessageObserver {
    public func messageDidChange(_ changeInfo: MessageChangeInfo!) {
        self.updateForMessage(changeInfo: changeInfo)
    }
}
