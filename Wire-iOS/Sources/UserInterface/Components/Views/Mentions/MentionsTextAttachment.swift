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

/// The purpose of this subclass of NSTextAttachment is to render a mention in the input bar.
/// It also keeps a reference to the `UserType` describing the User being mentioned.
final class MentionTextAttachment: NSTextAttachment {
    
    // Color used for the mention
    let color: UIColor

    /// The text the attachment renders, this is the name passed to init prefixed with an "@".
    var attributedText: NSAttributedString
    
    /// Font used for the mention, this gets updated when from the underlying text storage
    var font: UIFont {
        didSet {
            guard font != oldValue else { return }
            refreshImage()
        }
    }
    
    /// The user being mentioned.
    let user: UserType
    
    init(user: UserType, color: UIColor = .accent()) {
        self.font = .normalLightFont
        self.color = color
        self.user = user
        self.attributedText = type(of: self).attributedMentionString(user: user, font: font, color: color)
        
        super.init(data: nil, ofType: nil)
        
        refreshImage()
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func refreshImage() {
        attributedText = type(of: self).attributedMentionString(user: user, font: font, color: color)
        image = imageForName()
    }

    private func imageForName() -> UIImage? {
        bounds = attributedText.boundingRect(with: .max, options: [], context: nil)
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0)
        
        attributedText.draw(at: .zero)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
    private class func attributedMentionString(user: UserType, font: UIFont, color: UIColor) -> NSAttributedString {
        // Replace all spaces with non-breaking space to avoid wrapping when displaying mention
        let nameWithNonBreakingSpaces = user.name?.replacingOccurrences(of: " ", with: " ")
        return "@" + (nameWithNonBreakingSpaces ?? "") && font && color
    }
    
    private func updateFont(textContainer: NSTextContainer?, characterIndex charIndex: Int) {
        guard let font = textContainer?.layoutManager?.textStorage?.attribute(.font, at: charIndex, effectiveRange: nil) as? UIFont else {return }
        self.font = font
    }
    
    override func attachmentBounds(for textContainer: NSTextContainer?, proposedLineFragment lineFrag: CGRect, glyphPosition position: CGPoint, characterIndex charIndex: Int) -> CGRect {
        updateFont(textContainer: textContainer, characterIndex: charIndex)
        
        return super.attachmentBounds(for: textContainer, proposedLineFragment: lineFrag, glyphPosition: position, characterIndex: charIndex)
    }
    
}

fileprivate extension CGSize {
    static let max = CGSize(width: .max, height: .max)
}
