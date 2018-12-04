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

protocol ConversationOptionsConfigurable {
    func configure(with conversation: ZMConversation)
}


// a ConversationOptionsCell that with a disclosure indicator on the right
typealias GroupDetailsDisclosureOptionsCell = ConversationOptionsConfigurable & DisclosureCell

class DisclosureCell: RightIconDetailsCell {
    override func applyColorScheme(_ colorSchemeVariant: ColorSchemeVariant) {
        super.applyColorScheme(colorSchemeVariant)
        let sectionTextColor = UIColor.from(scheme: .sectionText, variant: colorSchemeVariant)
        accessory = UIImage(for: .disclosureIndicator, iconSize: .like, color: sectionTextColor)
    }
}
