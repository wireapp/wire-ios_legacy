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
import UIKit
import WireSyncEngine
import Cartography
import Classy

extension ConversationCell {
    
    func prepareLayoutForPreview(message: ZMMessage? = nil) -> CGFloat {
        let layoutProperties = ConversationCellLayoutProperties()
        layoutProperties.showSender = false
        layoutProperties.showUnreadMarker = false
        layoutProperties.showBurstTimestamp = false
        layoutProperties.topPadding = 0
        layoutProperties.alwaysShowDeliveryState = false
        
        self.configure(for: message, layoutProperties: layoutProperties)
        
        constrain(self, self.contentView) { cell, contentView in
            contentView.edges == cell.edges
        }
        
        self.toolboxView.removeFromSuperview()
        self.likeButton.isHidden = true
        self.isUserInteractionEnabled = false
        self.setSelected(false, animated: false)
        self.contentLayoutMargins = .zero
        
        return PreviewHeightCalculator.compressedSizeForView(self)
    }
}
