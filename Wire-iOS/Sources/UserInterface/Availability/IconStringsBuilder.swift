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

public class IconStringsBuilder {
    
    // Logic for composing attributed strings with:
    // - an icon (optional)
    // - a title
    // - an down arrow for tappable strings (optional)
    // - and, obviously, a color
    
    static func iconString(with icon: NSTextAttachment?, title: String, interactive: Bool, color: UIColor) -> NSAttributedString {
        
        var title = title.attributedString
        
        if interactive {
            title += "  " + NSAttributedString(attachment: .downArrow(color: color))
        }
        
        if let icon = icon {
            title = NSAttributedString(attachment: icon) + "  " + title
        }
        
        return title && color
    }
}

