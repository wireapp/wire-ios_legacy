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
import Down
import WireLinkPreview
import WireUtilities
import WireDataModel

extension NSAttributedString {

    static var paragraphStyle: NSParagraphStyle = {
        return defaultParagraphStyle()
    }()

    static var previewParagraphStyle: NSParagraphStyle {
        return defaultPreviewParagraphStyle()
    }

    static var style: DownStyle = {
        return defaultMarkdownStyle()
    }()

    static var previewStyle: DownStyle = {
        return previewMarkdownStyle()
    }()

    static var linkDataDetector: NSDataDetector? = {
        return try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
    }()

    /// This method needs to be called as soon as the preferredContentSizeCategory is changed
    @objc
    static func invalidateParagraphStyle() {
        paragraphStyle = defaultParagraphStyle()
    }

    /// This method needs to be called as soon as the text color configuration is changed.
    @objc
    static func invalidateMarkdownStyle() {
        style = defaultMarkdownStyle()
        previewStyle = previewMarkdownStyle()
    }

    fileprivate static func defaultParagraphStyle() -> NSParagraphStyle {
        let paragraphStyle = NSMutableParagraphStyle()

        paragraphStyle.minimumLineHeight = 22 * UIFont.wr_preferredContentSizeMultiplier(for: UIApplication.shared.preferredContentSizeCategory)
        paragraphStyle.paragraphSpacing = CGFloat.MessageCell.paragraphSpacing

        return paragraphStyle
    }

    fileprivate static func defaultPreviewParagraphStyle() -> NSParagraphStyle {
        let paragraphStyle = NSMutableParagraphStyle()

        paragraphStyle.paragraphSpacing = 0

        return paragraphStyle
    }

    fileprivate static func previewMarkdownStyle() -> DownStyle {
        let style = DownStyle.preview

        style.baseFontColor = UIColor.from(scheme: .textForeground)
        style.codeColor = style.baseFontColor
        style.h1Color = style.baseFontColor
        style.h2Color = style.baseFontColor
        style.h3Color = style.baseFontColor
        style.quoteColor = style.baseFontColor

        style.baseParagraphStyle = previewParagraphStyle
        style.listItemPrefixColor = style.baseFontColor.withAlphaComponent(0.64)

        return style
    }

    fileprivate static func defaultMarkdownStyle() -> DownStyle {
        let style = DownStyle.normal

        style.baseFont = UIFont.normalLightFont
        style.baseFontColor = UIColor.from(scheme: .textForeground)
        style.baseParagraphStyle = paragraphStyle
        style.listItemPrefixColor = style.baseFontColor.withAlphaComponent(0.64)

        return style
    }

    @objc
    static func formatForPreview(message: ZMTextMessageData, inputMode: Bool, variant: ColorSchemeVariant = ColorScheme.default.variant) -> NSAttributedString {
        var plainText = message.messageText ?? ""

        // Substitute mentions with text markers
        let mentionTextObjects = plainText.replaceMentionsWithTextMarkers(mentions: message.mentions)

        // Perform markdown parsing
        let markdownText = NSMutableAttributedString.markdown(from: plainText, style: previewStyle)

        // Highlight mentions using previously inserted text markers
        markdownText.highlight(mentions: mentionTextObjects, paragraphStyle: nil)

        // Remove trailing link if we show a link preview
        let links = markdownText.links()

        // Do emoji substition (but not inside link or mentions)
        let linkAttachmentRanges = links.compactMap { Range<Int>($0.range) }
        let mentionRanges = mentionTextObjects.compactMap{ $0.range(in: markdownText.string as String)}
        markdownText.replaceEmoticons(excluding: linkAttachmentRanges + mentionRanges)
        markdownText.removeTrailingWhitespace()

        if !inputMode {
            markdownText.changeFontSizeIfMessageContainsOnlyEmoticons(to: 32)
        }

        markdownText.removeAttribute(.link, range: NSRange(location: 0, length: markdownText.length))
        markdownText.addAttribute(.foregroundColor, value: UIColor.from(scheme: .textForeground, variant: variant), range: NSRange(location: 0, length: markdownText.length))
        return markdownText
    }

    @objc
    static func format(message: ZMTextMessageData, isObfuscated: Bool) -> NSAttributedString {

        var plainText = message.messageText ?? ""

        guard !isObfuscated else {
            let attributes: [NSAttributedString.Key: Any] = [ .font: UIFont(name: "RedactedScript-Regular", size: 18)!,
                                                               .foregroundColor: UIColor.accent(),
                                                               .paragraphStyle: paragraphStyle]
            return NSAttributedString(string: plainText, attributes: attributes)
        }

        // Substitute mentions with text markers
        let mentionTextObjects = plainText.replaceMentionsWithTextMarkers(mentions: message.mentions)

        // Perform markdown parsing
        let markdownText = NSMutableAttributedString.markdown(from: plainText, style: style)

        // Highlight mentions using previously inserted text markers
        markdownText.highlight(mentions: mentionTextObjects)

        // Remove trailing link if we show a link preview
        if let linkPreview = message.linkPreview {
            markdownText.removeTrailingLink(for: linkPreview)
        }

        // Do emoji substition (but not inside link or mentions)
        let links = markdownText.links()
        let linkAttachmentRanges = links.compactMap { Range<Int>($0.range) }
        let mentionRanges = mentionTextObjects.compactMap{ $0.range(in: markdownText.string as String)}
        let codeBlockRanges =  markdownText.ranges(of: .code).compactMap { Range<Int>($0) }
        markdownText.replaceEmoticons(excluding: linkAttachmentRanges + mentionRanges + codeBlockRanges)

        markdownText.removeTrailingWhitespace()
        markdownText.changeFontSizeIfMessageContainsOnlyEmoticons()

        return markdownText
    }

    func links() -> [URLWithRange] {
        return NSDataDetector.linkDetector?.detectLinksAndRanges(in: self.string, excluding: []) ?? []
    }

}

extension NSMutableAttributedString {

    func replaceEmoticons(excluding excludedRanges: [Range<Int>]) {
        beginEditing(); defer { endEditing() }

        let allowedIndexSet = IndexSet(integersIn: Range<Int>(wholeRange)!, excluding: excludedRanges)

        ///reverse the order of replacing, if we start replace from the beginning, the string may be shorten and other ranges may be invalid.
        for range in allowedIndexSet.rangeView.sorted(by: {$0.lowerBound > $1.lowerBound}) {
            let convertedRange = NSRange(location: range.lowerBound, length: range.upperBound - range.lowerBound)
            mutableString.resolveEmoticonShortcuts(in: convertedRange)
        }
    }

    func changeFontSizeIfMessageContainsOnlyEmoticons(to fontSize: CGFloat = 40) {
        if (string as String).containsOnlyEmojiWithSpaces {
            setAttributes([.font: UIFont.systemFont(ofSize: fontSize)], range: wholeRange)
        }
    }

    func removeTrailingWhitespace() {
        let trailingWhitespaceRange = mutableString.rangeOfCharacter(from: .whitespacesAndNewlines, options: [.anchored, .backwards])

        if trailingWhitespaceRange.location != NSNotFound {
            mutableString.deleteCharacters(in: trailingWhitespaceRange)
        }
    }

    func removeTrailingLink(for linkPreview: LinkMetadata) {
        let text = self.string

        guard
            let linkPreviewRange = text.range(of: linkPreview.originalURLString, options: .backwards, range: nil, locale: nil),
            linkPreviewRange.upperBound == text.endIndex
        else {
            return
        }

        mutableString.replaceCharacters(in: NSRange(linkPreviewRange, in: text), with: "")
    }

}

fileprivate extension String {

    mutating func replaceMentionsWithTextMarkers(mentions: [Mention]) -> [TextMarker<Mention>] {
        return mentions.sorted(by: {
            return $0.range.location > $1.range.location
        }).compactMap({ mention in
            guard let range = Range(mention.range, in: self) else { return nil }

            let name = String(self[range].dropFirst()) // drop @
            let textObject = TextMarker<Mention>(mention, replacementText: name)

            replaceSubrange(range, with: textObject.token)

            return textObject
        })
    }

}
