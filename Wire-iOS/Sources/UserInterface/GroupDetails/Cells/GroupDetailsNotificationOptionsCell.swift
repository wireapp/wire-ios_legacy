////
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

class GroupDetailsNotificationOptionsCell: GroupDetailsOptionsCell {
    
    override func setUp() {
        super.setUp()
        accessibilityIdentifier = "cell.groupdetails.notificationsoptions"
        title = "Notifications"
    }
    
    override func configure(with conversation: ZMConversation) {
        guard let status = conversation.mutedMessageTypes.notificationString else {
            return assertionFailure("Invalid muted message type.")
        }
        
        self.status = status
    }
    
    override func applyColorScheme(_ colorSchemeVariant: ColorSchemeVariant) {
        super.applyColorScheme(colorSchemeVariant)
        icon = UIImage(for: .alerts, iconSize: .tiny,
                       color: UIColor(scheme: .textForeground, variant: colorSchemeVariant))
    }

}

extension MutedMessageTypes {
    var notificationString: String? {
        switch self {
        case .none:         return "Everything"
        case .nonMentions:  return "Only Mentions"
        case .all:          return "Nothing"
        default:            return nil
        }
    }
}
