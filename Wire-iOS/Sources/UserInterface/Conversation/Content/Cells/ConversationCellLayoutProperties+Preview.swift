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

import UIKit

extension ConversationCellLayoutProperties {
    static let preview: ConversationCellLayoutProperties = {
        let properties = ConversationCellLayoutProperties()
        properties.showSender = false
        properties.showUnreadMarker = false
        properties.showBurstTimestamp = false
        properties.topPadding = 0
        properties.alwaysShowDeliveryState = false
        return properties
    }()
}
