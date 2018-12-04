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

class ConversationCreateOptionsCell: RightIconDetailsCell {
    
    var expanded = false {
        didSet { applyColorScheme(colorSchemeVariant) }
    }
    
    override func setUp() {
        super.setUp()
        // TODO: localize
        title = "Conversation options"
        status = "Allow guests: ON, Read receipts: ON"
        icon = nil
        showSeparator = false
        contentLeadingOffset = 16
    }
    
    
    
    override func applyColorScheme(_ colorSchemeVariant: ColorSchemeVariant) {
        super.applyColorScheme(colorSchemeVariant)
        backgroundColor = .from(scheme: .sectionBackgroundHighlighted, variant: colorSchemeVariant)
        
        let color = UIColor.from(scheme: .sectionText, variant: colorSchemeVariant)
        let image = UIImage(for: .downArrow, iconSize: .tiny, color: color)
        
        if let cgImage = image?.cgImage, let scale = image?.scale, expanded {
            accessory = UIImage(cgImage: cgImage, scale: scale, orientation: .downMirrored)
        } else {
            accessory = UIImage(for: .downArrow, iconSize: .tiny, color: color)
        }
    }
}
