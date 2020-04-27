// 
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

final class TokenTextAttachment: NSTextAttachment, TokenContainer {
    let token: Token<NSObjectProtocol>

    private unowned let tokenField: TokenField

    var isSelected = false {
        didSet {
            refreshImage()
        }
    }

    init(token: Token<NSObjectProtocol>, tokenField: TokenField) {
        self.token = token
        self.tokenField = tokenField

        super.init(data: nil, ofType: nil)

        refreshImage()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func refreshImage() {
        image = imageForCurrentToken
    }

    private var imageForCurrentToken: UIImage? {
        let imageHeight: CGFloat = ceil(tokenField.fontLineHeight)
        let title = token.title.applying(transform: tokenField.tokenTextTransform)
        // Width cannot be smaller than height
        let tokenMaxWidth: CGFloat = max(ceil(token.maxTitleWidth - tokenField.tokenOffset - imageHeight), imageHeight)
        let shortTitle = shortenedText(forText: title, withAttributes: titleAttributes, toFitMaxWidth: tokenMaxWidth)
        let attributedName = NSAttributedString(string: shortTitle, attributes: titleAttributes)
        let imageSize = CGSize(width: attributedName.size().width, height: imageHeight)
        let delta: CGFloat = ceil((tokenField.font.capHeight - imageHeight) * 0.5)

        bounds = CGRect(x: 0, y: delta, width: imageSize.width, height: imageHeight)

        UIGraphicsBeginImageContextWithOptions(bounds.size, _: false, _: 0)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        context.saveGState()

        if let backgroundColor = backgroundColor {
            context.setFillColor(backgroundColor.cgColor)
        }

        if let borderColor = borderColor {
            context.setStrokeColor(borderColor.cgColor)
        }

        context.setLineJoin(.round)
        context.setLineWidth(1)

        attributedName.draw(at: CGPoint(x: 0, y: -delta + tokenField.tokenTitleVerticalAdjustment))

        let i = UIGraphicsGetImageFromCurrentImageContext()

        context.restoreGState()
        UIGraphicsEndImageContext()

        return i
    }

    // MARK: - String formatting
    private var titleColor: UIColor? {
        if isSelected {
            return tokenField.tokenSelectedTitleColor
        } else {
            return tokenField.tokenTitleColor
        }
    }

    private var backgroundColor: UIColor? {
        if isSelected {
            return tokenField.tokenSelectedBackgroundColor
        } else {
            return tokenField.tokenBackgroundColor
        }
    }

    private var borderColor: UIColor? {
        if isSelected {
            return tokenField.tokenSelectedBorderColor
        } else {
            return tokenField.tokenBorderColor
        }
    }

    private var dotColor: UIColor? {
        return tokenField.dotColor
    }

    private var titleAttributes: [NSAttributedString.Key: Any] {
        guard let titleColor = titleColor else {
            return [:]
        }

        return [
            NSAttributedString.Key.font: tokenField.tokenTitleFont,
            NSAttributedString.Key.foregroundColor: titleColor
        ]
    }

    // MARK: - String shortening
    static let appendixString: String = "…"

    func shortenedText(forText text: String, withAttributes attributes: [NSAttributedString.Key: Any]?, toFitMaxWidth maxWidth: CGFloat) -> String {
        if size(for: text, attributes: attributes).width < maxWidth {
            return text
        }

        return searchForShortenedText(forText: text, withAttributes: attributes, toFitMaxWidth: maxWidth, in: NSRange(location: 0, length: text.count))
    }

    // Search for longest substring, which render width is less than maxWidth

    func searchForShortenedText(forText text: String,
                                withAttributes attributes: [NSAttributedString.Key: Any]?,
                                toFitMaxWidth maxWidth: CGFloat,
                                in range: NSRange) -> String {
        // In other words, search for such number l, that
        // [title substringToIndex:l].width <= maxWidth,
        // and [title substringToIndex:l+1].width > maxWidth;

        // the longer substring is, the longer its width, so
        // we can use binary search here.

        let nsString: NSString = text as NSString

        let shortedTextLength = range.location + range.length / 2
        let shortedText = (nsString.substring(to: shortedTextLength)) + TokenTextAttachment.appendixString
        let shortedText1 = (nsString.substring(to: shortedTextLength + 1)) + TokenTextAttachment.appendixString

        let shortedTextSize = size(for: shortedText, attributes: attributes)
        let shortedText1Size = size(for: shortedText1, attributes: attributes)
        if shortedTextSize.width <= maxWidth && shortedText1Size.width > maxWidth {
            return shortedText
        } else if shortedText1Size.width <= maxWidth {
            // Search in right range
            return searchForShortenedText(forText: text, withAttributes: attributes, toFitMaxWidth: maxWidth, in: NSRange(location: shortedTextLength, length: NSMaxRange(range) - shortedTextLength))
        } else if shortedTextSize.width > maxWidth {
            // Search in left range
            return searchForShortenedText(forText: text, withAttributes: attributes, toFitMaxWidth: maxWidth, in: NSRange(location: range.location, length: shortedTextLength - range.location))
        }

        return text
    }

    func size(for string: String, attributes: [NSAttributedString.Key: Any]?) -> CGSize {
        return NSAttributedString(string: string, attributes: attributes).size()
    }

    // MARK: - Description
    override var description: String {
        return String(format: "<\(type(of: self)): \(self), name \(token.title)>")
    }

    var debugQuickLookObject: UIImage? {
        return image
    }
}
