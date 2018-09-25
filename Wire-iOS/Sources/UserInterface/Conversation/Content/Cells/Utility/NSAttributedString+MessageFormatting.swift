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
import WireExtensionComponents
import WireLinkPreview


extension NSAttributedString {
    
    static var paragraphStyle: NSParagraphStyle = {
        return defaultParagraphStyle()
    }()
    
    static var style: DownStyle = {
        return defaultMarkdownStyle()
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
    }
    
    fileprivate static func defaultParagraphStyle() -> NSParagraphStyle {
        let paragraphStyle = NSMutableParagraphStyle()
        
        paragraphStyle.minimumLineHeight = 22 * UIFont.wr_preferredContentSizeMultiplier(for: UIApplication.shared.preferredContentSizeCategory)
        paragraphStyle.paragraphSpacing = 8
        
        return paragraphStyle
    }
    
    fileprivate static func defaultMarkdownStyle() -> DownStyle {
        let style = DownStyle.normal
        
        style.baseFont = UIFont.normalLightFont
        style.baseFontColor = UIColor(scheme: .textForeground)
        style.baseParagraphStyle = paragraphStyle
        style.listItemPrefixColor = style.baseFontColor.withAlphaComponent(0.64)
        
        return style
    }
    
    @objc
    static func format(message: ZMTextMessageData, isObfuscated: Bool, linkAttachment: UnsafeMutablePointer<LinkAttachment>?) -> NSAttributedString {
        
        var plainText = message.messageText ?? ""
        
        guard !isObfuscated else {
            let attributes: [NSAttributedString.Key : Any] = [ .font : UIFont(name: "RedactedScript-Regular", size: 18)!,
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
        var linkAttachments = markdownText.linksAttachments()
        if let linkPreview = message.linkPreview {
            linkAttachments = markdownText.removeTrailingLink(for: linkPreview, linkAttachments: linkAttachments)
        }
        
        // Do emoji substition (but not inside link or mentions)
        let linkAttachmentRanges = linkAttachments.compactMap { Range<Int>($0.range) }
        let mentionRanges = mentionTextObjects.compactMap{ $0.range(in: markdownText.string as String)}
        markdownText.replaceEmoticons(excluding: linkAttachmentRanges + mentionRanges)
        
        if let firstKnownLinkAttachment = linkAttachments.first(where: { $0.type != .none }) {
            linkAttachment?.initialize(to: firstKnownLinkAttachment)
        }
        
        markdownText.removeTrailingWhitespace()
        markdownText.changeFontSizeIfMessageContainsOnlyEmoticons()

        
        return markdownText
    }
    
    func linksAttachments() -> [LinkAttachment] {
        guard let matches = type(of: self).linkDataDetector?.matches(in: self.string, options: [], range: wholeRange) else { return [] }
        
        return matches.compactMap { match in
            guard let url = match.url else { return nil }
            self.attributedSubstring(from: match.range)
            return LinkAttachment(url: url, range: match.range, string: attributedSubstring(from: match.range).string)
        }
    }
    
}

extension NSMutableAttributedString {
    
    func replaceEmoticons(excluding excludedRanges: [Range<Int>]) {
        beginEditing(); defer { endEditing() }
        
        var excludedIndexSet = IndexSet()
        var includedIndexSet = IndexSet()
        
        excludedRanges.forEach { excludedIndexSet.insert(integersIn: $0) }
        includedIndexSet.insert(integersIn: Range<Int>(wholeRange)!)
        
        let allowedIndexSet = includedIndexSet.symmetricDifference(excludedIndexSet)
        
        _ = allowedIndexSet
        
        for range in allowedIndexSet.rangeView {
            let range = NSRange(location: range.startIndex, length: range.endIndex - range.startIndex)
            self.mutableString.resolveEmoticonShortcuts(in: range)
        }
    }
    
    func changeFontSizeIfMessageContainsOnlyEmoticons() {
        if string.containsOnlyEmojiWithSpaces {
            setAttributes([.font: UIFont.systemFont(ofSize: 40)], range: wholeRange)
        }
    }
    
    func removeTrailingWhitespace() {
        let trailingWhitespaceRange = mutableString.rangeOfCharacter(from: .whitespacesAndNewlines, options: [.anchored, .backwards])
        
        if trailingWhitespaceRange.location != NSNotFound {
            mutableString.deleteCharacters(in: trailingWhitespaceRange)
        }
    }
    
    func removeTrailingLink(for linkPreview: LinkPreview, linkAttachments: [LinkAttachment]) -> [LinkAttachment] {
    
        // Don't remove trailing link if we embed content
        guard linkAttachments.first?.type == LinkAttachmentType.none,
              linkPreview.originalURLString.lowercased() != "giphy.com", // Don't remove giphy links
              let linkPreviewAttachment = linkAttachments.reversed().first(where: { $0.string == linkPreview.originalURLString }),
              linkPreviewAttachment.range.upperBound == self.length
        else {
            return linkAttachments
        }
        
        self.mutableString.replaceCharacters(in: linkPreviewAttachment.range, with: "")
        return linkAttachments.filter({ $0 != linkPreviewAttachment })
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
