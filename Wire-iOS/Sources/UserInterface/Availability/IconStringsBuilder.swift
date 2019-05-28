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
        return iconString(with: icon == nil ? [] : [icon!], title: title, interactive: interactive, color: color)
    }
    
    static func iconString(with icons: [NSTextAttachment], title: String, interactive: Bool, color: UIColor) -> NSAttributedString {
        
        var components: [NSAttributedString] = []
        
        // Adds shield/legalhold/availability/etc. icons
        icons.forEach { components.append(NSAttributedString(attachment: $0)) }

        // Adds the title
        components.append(title.attributedString)
        
        // Adds the down arrow if the view is interactive
        if interactive {
            components.append(NSAttributedString(attachment: .downArrow(color: color)))
        }
        
        // Mirror elements if in a RTL layout
        if !UIApplication.isLeftToRightLayout {
            components.reverse()
        }
        
        // Create a padding object and combine the final attributed string
        let padding = NSAttributedString(attachment: .padding)
        let title = components.joined(separator: padding)
        
        return title && color
    }
}

fileprivate extension NSTextAttachment {
    static var padding: NSTextAttachment {
        let attachment = NSTextAttachment()
        attachment.bounds = CGRect(x: 0, y: 0, width: 7, height: 7)
        return attachment
    }
}
