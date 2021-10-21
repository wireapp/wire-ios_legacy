////
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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
import MobileCoreServices
import Down
import UIKit
import WireSyncEngine

extension Notification.Name {
    static let MarkdownTextViewDidChangeActiveMarkdown = Notification.Name("MarkdownTextViewDidChangeActiveMarkdown")
}

final class MarkdownTextView: NextResponderTextView, PerformClipboardAction {

    enum ListType {
        case number, bullet
        var prefix: String { return self == .number ? "1. " : "- " }
    }

    // MARK: - Properties

    /// The style used to apply attributes.
    var style: DownStyle

    /// The parser used to convert attributed text into markdown syntax.
    private let parser = AttributedStringParser()

    /// The main backing store
    let markdownTextStorage: MarkdownTextStorage

    /// The string containing markdown syntax for the corresponding
    /// attributed text.
    var preparedText: (String, [Mention]) {
        let markdownText = parser.parse(attributedString: attributedText)
        let mentions = self.mentions(from: markdownText)
        let markdownTextWithMentions = replaceMentionAttachmentsWithPlainText(in: markdownText)

        return (markdownTextWithMentions as String, mentions)
    }

    @objc
    func setDraftMessage(_ draft: DraftMessage) {
        setText(draft.text, withMentions: draft.mentions)
    }

    override func canPerformAction(_ action: Selector,
                                   withSender sender: Any?) -> Bool {
        switch action {
        case #selector(UIResponderStandardEditActions.paste(_:)),
             #selector(UIResponderStandardEditActions.cut(_:)),
             #selector(UIResponderStandardEditActions.copy(_:)):

            let pasteboard = UIPasteboard.general
            guard shouldAllowPerformAction(isText: pasteboard.hasText,
                                         isClipboardEnabled: SecurityFlags.clipboard.isEnabled,
                                         canFilesBeShared: canFilesBeShared) else { return false }
            fallthrough
        default:
            return super.canPerformAction(action, withSender: sender)
        }
    }

    func setText(_ newText: String, withMentions mentions: [Mention]) {
        let mutable = NSMutableAttributedString(string: newText, attributes: currentAttributes)

        // We reverse to maintain correct ranges for subsequent inserts.
        for mention in mentions.reversed() {
            let attachment = MentionTextAttachment(user: mention.user)
            let attributedString = NSAttributedString(attachment: attachment) && typingAttributes
            mutable.replaceCharacters(in: mention.range, with: attributedString)
        }

        attributedText = mutable
    }

    private func mentions(from attributedText: NSAttributedString) -> [Mention] {
        var locationOffset = 0
        let mentions: [Mention] = mentionAttachmentsWithRange(from: attributedText).map { tuple in
            let (attachment, range) = tuple
            let length = attachment.attributedText.string.utf16.count
            let adjustedRange = NSRange(location: range.location + locationOffset, length: length)
            locationOffset += length - 1 // Adjust for the length 1 attachment that we replaced.

            return Mention(range: adjustedRange, user: attachment.user)
        }
        return mentions
    }

    private func replaceMentionAttachmentsWithPlainText(in attributedText: NSAttributedString) -> String {
        let textWithPlainTextMentions = NSMutableString(string: attributedText.string)

        // We reverse to maintain correct ranges for subsequent inserts.
        let mentionRanges = mentionAttachmentsWithRange(from: attributedText).map({ attachment, range in
            (range, attachment.attributedText.string)
        }).reversed()

        mentionRanges.forEach(textWithPlainTextMentions.replaceCharacters)

        return textWithPlainTextMentions as String
    }

    private func mentionAttachmentsWithRange(from attributedText: NSAttributedString) -> [(MentionTextAttachment, NSRange)] {
        var result = [(MentionTextAttachment, NSRange)]()
        attributedText.enumerateAttributes(in: attributedText.wholeRange, options: []) { attributes, range, _ in
            if let attachment = attributes[.attachment] as? MentionTextAttachment {
                result.append((attachment, range))
            }
        }
        return result
    }

    /// Set when newline is entered, used for auto list item creation.
    private var newlineFlag = false

    /// The current attributes to be applied when typing.
    fileprivate var currentAttributes: [NSAttributedString.Key: Any] = [:]

    /// The currently active markdown. This determines which attributes
    /// are applied when typing.
    fileprivate(set) var activeMarkdown = Markdown.none {
        didSet {
            if oldValue != activeMarkdown {
                currentAttributes = attributes(for: activeMarkdown)
                markdownTextStorage.currentMarkdown = activeMarkdown
                typingAttributes = currentAttributes
                NotificationCenter.default.post(name: .MarkdownTextViewDidChangeActiveMarkdown, object: self)
            }
        }
    }

    override func cut(_ sender: Any?) {
        guard let selectedTextRange = selectedTextRange else { return }

        let copiedAttributedText = attributedText.attributedSubstring(from: selectedRange)
        let copiedAttributedTextPlainText = replaceMentionAttachmentsWithPlainText(in: copiedAttributedText)

        UIPasteboard.general.setValue(copiedAttributedTextPlainText, forPasteboardType: kUTTypeUTF8PlainText as String)

        replace(selectedTextRange, withText: "")
    }

    override func copy(_ sender: Any?) {
        let copiedAttributedText = attributedText.attributedSubstring(from: selectedRange)
        let copiedAttributedTextPlainText = replaceMentionAttachmentsWithPlainText(in: copiedAttributedText)

        UIPasteboard.general.setValue(copiedAttributedTextPlainText, forPasteboardType: kUTTypeUTF8PlainText as String)
    }

    public override var selectedTextRange: UITextRange? {
        didSet { activeMarkdown = self.markdownAtSelection() }
    }

    // MARK: - Range Helpers

    fileprivate var currentLineRange: NSRange? {
        guard selectedRange.location != NSNotFound else { return nil }
        return (text as NSString).lineRange(for: selectedRange)
    }

    private var currentLineTextRange: UITextRange? {
        return currentLineRange?.textRange(in: self)
    }

    private var previousLineRange: NSRange? {
        guard let range = currentLineRange, range.location > 0 else { return nil }
        return (text as NSString).lineRange(for: NSRange(location: range.location - 1, length: 0))
    }

    private var previousLineTextRange: UITextRange? {
        return previousLineRange?.textRange(in: self)
    }

    // MARK: - Init

    convenience init() {
        self.init(with: DownStyle.normal)
    }

    init(with style: DownStyle) {
        self.style = style
        // create the storage stack
        self.markdownTextStorage = MarkdownTextStorage()
        let layoutManager = NSLayoutManager()
        self.markdownTextStorage.addLayoutManager(layoutManager)
        let textContainer = NSTextContainer()
        layoutManager.addTextContainer(textContainer)
        super.init(frame: .zero, textContainer: textContainer)

        currentAttributes = attributes(for: activeMarkdown)
        typingAttributes = currentAttributes

        NotificationCenter.default.addObserver(self, selector: #selector(textViewDidChange), name: UITextView.textDidChangeNotification, object: nil)
        setupGestureRecognizer()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public Interface

    /// Updates the color of the text.
    func updateTextColor(base: UIColor?) {
        let baseColor = base ?? UIColor.from(scheme: .textForeground)
        self.textColor = baseColor
        self.style.baseFontColor = baseColor
    }

    /// Clears active markdown & updates typing attributes.
    @objc
    func resetMarkdown() { activeMarkdown = .none }

    /// Call this method before the text view changes to give it a chance
    /// to perform any work.
    func respondToChange(_ text: String, inRange range: NSRange) {
        if text == "\n" || text == "\r" {
            newlineFlag = true
            if activeMarkdown.containsHeader {
                resetMarkdown()
            }
        }

        typingAttributes = currentAttributes
    }

    // MARK: - Private Interface

    /// Called after each text change has been committed. We use this opportunity
    /// to insert new list items in the case a newline was entered, as well as
    /// to validate any potential list items on the currently selected line.
    @objc private func textViewDidChange() {

        if newlineFlag {
            // flip immediately to avoid infinity
            newlineFlag = false

            guard
                let prevlineRange = previousLineRange,
                let prevLineTextRange = previousLineTextRange,
                let selection = selectedTextRange
                else { return }

            if isEmptyListItem(at: prevlineRange) {
                // the delete last line
                replaceText(in: prevLineTextRange, with: "", restoringSelection: selection)
            } else if let type = listType(in: prevlineRange) {
                // insert list item at current line
                insertListItem(type: type)
            }
        }

        validateListItemAtCaret()
    }

    // MARK: Markdown Querying

    /// Returns the markdown at the current selected range. If this is a position
    /// or the selected range contains only a single type of markdown, this
    /// markdown is returned. Otherwise none is returned.
    private func markdownAtSelection() -> Markdown {
        guard selectedRange.length > 0 else { return markdownAtCaret() }
        let markdownInSelection = markdown(in: selectedRange)
        if markdownInSelection.count == 1 {
            return markdownInSelection.first!
        }
        return .none
    }

    /// Returns the markdown for the current caret position. We actually get the
    /// markdown for the position behind the caret unless the caret is at the
    /// start of a line. We do this so the user can, for instance, move the
    /// caret at the end of a bold word and continue typing in bold.
    private func markdownAtCaret() -> Markdown {
        guard let range = currentLineRange else { return .none }
        return markdown(at: max(range.location, selectedRange.location - 1))
    }

    /// Returns the markdown at the given location.
    private func markdown(at location: Int) -> Markdown {
        guard location >= 0 && markdownTextStorage.length > location else { return .none }
        let markdown = markdownTextStorage.attribute(.markdownID, at: location, effectiveRange: nil) as? Markdown
        return markdown ?? .none
    }

    /// Returns a set containing all markdown combinations present in the given
    /// range.
    fileprivate func markdown(in range: NSRange) -> Set<Markdown> {
        var result = Set<Markdown>()
        markdownTextStorage.enumerateAttribute(.markdownID, in: range, options: []) { md, _, _ in
            result.insert(md as? Markdown ?? .none)
        }
        return result
    }

    // MARK: - Attribute Manipulation

    /// Returns the attributes for the given markdown.
    private func attributes(for markdown: Markdown) -> [NSAttributedString.Key: Any] {

        // the idea is to query for specific markdown & adjust the attributes
        // incrementally

        var font = style.baseFont
        var color = style.baseFontColor
        let paragraphyStyle = style.baseParagraphStyle

        // if we will bolden the font, it should initially have no weight
        // (inserting bold trait to light system font has no effect)
        if markdown.containsHeader || markdown.contains(.bold) {
            font = font.withoutLightWeight
        }

        // code should be processed first since it has it's own font.
        if markdown.contains(.code) {
            font = style.codeFont
            if let codeColor = style.codeColor { color = codeColor }
        }

        // then we process headers b/c changing the font
        // size clears the bold/italic traits
        if let header = markdown.headerValue {
            if let headerSize = style.headerSize(for: header) {
                font = font.withSize(headerSize).bold
            }
            if let headerColor = style.headerColor(for: header) {
                color = headerColor
            }
        }

        if markdown.contains(.bold) {
            font = font.bold
        }

        if markdown.contains(.italic) {
            font = font.italic
        }

        return [
            .markdownID: markdown,
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraphyStyle
        ]
    }

    /// Adds the given markdown (and the associated attributes) to the given
    /// range.
    fileprivate func add(_ markdown: Markdown, to range: NSRange) {
        updateAttributes(in: range) { $0.union(markdown) }
    }

    /// Removes the given markdown (and the associated attributes) from the given
    /// range.
    fileprivate func remove(_ markdown: Markdown, from range: NSRange) {
        updateAttributes(in: range) { $0.subtracting(markdown) }
    }

    /// Updates all attributes in the given range by transforming markdown tags
    /// using the transformation function, then refetching the attributes for
    /// the transformed values and setting the new attributes.
    private func updateAttributes(in range: NSRange, using transform: (Markdown) -> Markdown) {
        var exisitngMarkdownRanges = [(Markdown, NSRange)]()
        markdownTextStorage.enumerateAttribute(.markdownID, in: range, options: []) { md, mdRange, _ in
            if let md = md as? Markdown { exisitngMarkdownRanges.append((md, mdRange)) }
        }

        for (md, mdRange) in exisitngMarkdownRanges {
            let updatedAttributes = attributes(for: transform(md))
            markdownTextStorage.addAttributes(updatedAttributes, range: mdRange)
        }
    }

    // MARK: - List Regex

    private lazy var emptyListItemRegex: NSRegularExpression = {
        let pattern = "^((\\d+\\.)|[•*+-])[\\t ]*$"
        return try! NSRegularExpression(pattern: pattern, options: .anchorsMatchLines)
    }()

    private lazy var orderedListItemRegex: NSRegularExpression = {
        // group 1: prefix, group 2: number, group 3: content
        return try! NSRegularExpression(pattern: "^((\\d+)\\.\\ )(.*$)", options: .anchorsMatchLines)
    }()

    private lazy var unorderedListItemRegex: NSRegularExpression = {
        // group 1: prefix, group 2: bullet, group 3: content
        return try! NSRegularExpression(pattern: "^(([•*+-])\\ )(.*$)", options: .anchorsMatchLines)
    }()

    // MARK: - List Methods

    /// Scans the string in the line containing the caret for a list item. If
    /// one is found, the appropriate markdown ID is applied.
    private func validateListItemAtCaret() {
        guard let lineRange = currentLineRange else { return }
        validateListItem(in: lineRange)
    }

    /// Scans the string in the given range for a list item. If one is found,
    /// the appropriate markdown ID is applied.
    private func validateListItem(in range: NSRange) {
        remove([.oList, .uList], from: range)
        orderedListItemRegex.enumerateMatches(in: text, options: [], range: range) { match, _, _ in
            if let matchRange = match?.range { add(.oList, to: matchRange) }
        }
        unorderedListItemRegex.enumerateMatches(in: text, options: [], range: range) { match, _, _ in
            if let matchRange = match?.range { add(.uList, to: matchRange) }
        }

        activeMarkdown = markdownAtCaret()
    }

    /// Returns true if an empty list item is present in the given range.
    private func isEmptyListItem(at range: NSRange) -> Bool {
        return emptyListItemRegex.numberOfMatches(in: text, options: [], range: range) != 0
    }

    /// Returns the list type in the given range, if it exists.
    private func listType(in range: NSRange) -> ListType? {
        if numberPrefix(at: range) != nil { return .number } else if bulletPrefix(at: range) != nil { return .bullet } else { return nil }
    }

    /// Returns the range of the list prefix in the given range, if it exists.
    private func rangeOfListPrefix(at range: NSRange) -> NSRange? {
        if let match = orderedListItemRegex.firstMatch(in: text, options: [], range: range) {
            if match.range(at: 1).location != NSNotFound {
                return match.range(at: 1)
            }
        }

        if let match = unorderedListItemRegex.firstMatch(in: text, options: [], range: range) {
            if match.range(at: 1).location != NSNotFound {
                return match.range(at: 1)
            }
        }

        return nil
    }

    /// Returns the number prefix in the given range, if it exists.
    private func numberPrefix(at range: NSRange) -> Int? {
        if let match = orderedListItemRegex.firstMatch(in: text, options: [], range: range) {
            let num = markdownTextStorage.attributedSubstring(from: match.range(at: 2)).string
            return Int(num)
        }
        return nil
    }

    /// Returns the bullet prefix in the given range, if it exists.
    private func bulletPrefix(at range: NSRange) -> String? {
        if let match = unorderedListItemRegex.firstMatch(in: text, options: [], range: range) {
            let bullet = markdownTextStorage.attributedSubstring(from: match.range(at: 2)).string
            return bullet
        }
        return nil
    }

    /// Returns the next list prefix by first trying to match a previous
    /// list item, otherwise returns the default prefix.
    private func nextListPrefix(type: ListType) -> String {
        guard let previousLine = previousLineRange else { return type.prefix }
        switch type {
        case .number: return "\((numberPrefix(at: previousLine) ?? 0) + 1). "
        case .bullet: return "\(bulletPrefix(at: previousLine) ?? "-") "
        }
    }

    /// Inserts a list prefix with the given type on the current line.
    fileprivate func insertListItem(type: ListType) {

        // remove existing list item if it exists
        removeListItem()

        guard
            let lineRange = currentLineRange,
            let selection = selectedTextRange,
            let lineStart = NSRange(location: lineRange.location, length: 0).textRange(in: self)
            else { return }

        let prefix = nextListPrefix(type: type)

        // insert prefix with no md
        typingAttributes = attributes(for: .none)
        replaceText(in: lineStart, with: prefix, restoringSelection: selection)
        typingAttributes = currentAttributes

        // add list md to whole line
        guard let newLineRange = currentLineRange else { return }
        add(type == .number ? .oList : .uList, to: newLineRange)
    }

    /// Removes the list prefix from the current line.
    fileprivate func removeListItem() {
        guard
            let lineRange = currentLineRange,
            let prefixRange = rangeOfListPrefix(at: lineRange)?.textRange(in: self),
            var selection = selectedTextRange
            else { return }

        // if the selection is within the prefix range, change selection
        // to be at start of list content
        if offset(from: selection.start, to: prefixRange.end) > 0 {
            selection = textRange(from: prefixRange.end, to: prefixRange.end)!
        }

        replaceText(in: prefixRange, with: "", restoringSelection: selection)

        // remove list md from whole line
        guard let newLineRange = currentLineRange else { return }
        remove([.oList, .uList], from: newLineRange)
    }

    /// Replaces the range with the text and attempts to restore the selection.
    private func replaceText(in range: UITextRange, with text: String, restoringSelection selection: UITextRange) {
        replace(range, withText: text)

        // calculate the new selection
        let oldLength = offset(from: range.start, to: range.end)
        let newLength = (text as NSString).length
        let delta = newLength - oldLength

        // attempt to restore the selection
        guard
            let start = position(from: selection.start, offset: delta),
            let end = position(from: selection.end, offset: delta),
            let restoredSelection = textRange(from: start, to: end)
            else { return }

        selectedTextRange = restoredSelection
    }
}

// MARK: - MarkdownBarViewDelegate

extension MarkdownTextView: MarkdownBarViewDelegate {

    func markdownBarView(_ view: MarkdownBarView, didSelectMarkdown markdown: Markdown, with sender: IconButton) {
        // there must be a selection
        guard selectedRange.location != NSNotFound else { return }

        switch markdown {
        case .h1, .h2, .h3:
            // apply header to the whole line
            if let range = currentLineRange {
                // remove any existing header styles before adding new header
                let otherHeaders = ([.h1, .h2, .h3] as Markdown).subtracting(markdown)
                activeMarkdown.subtract(otherHeaders)
                remove(otherHeaders, from: range)
                add(markdown, to: range)
            }

        case .oList:
            insertListItem(type: .number)

        case .uList:
            insertListItem(type: .bullet)

        case .code:
            // selecting code deselects bold & italic
            remove([.bold, .italic], from: selectedRange)
            activeMarkdown.subtract([.bold, .italic])

        case .bold, .italic:
            // selecting bold or italic deselects code
            remove(.code, from: selectedRange)
            activeMarkdown.subtract(.code)

        default:
            break
        }

        if selectedRange.length > 0 {
            // if multiple md in selection, remove all inline md before
            // applying the new md
            if self.markdown(in: selectedRange).count > 1 {
                remove([.bold, .italic, .code], from: selectedRange)
            }

            add(markdown, to: selectedRange)
        }

        activeMarkdown.insert(markdown)
    }

    func markdownBarView(_ view: MarkdownBarView, didDeselectMarkdown markdown: Markdown, with sender: IconButton) {
        // there must be a selection
        guard selectedRange.location != NSNotFound else { return }

        switch markdown {
        case .h1, .h2, .h3:
            // remove header from the whole line
            if let range = currentLineRange {
                remove(markdown, from: range)
            }

        case .oList, .uList:
            removeListItem()

        default:
            break
        }

        if selectedRange.length > 0 {
            remove(markdown, from: selectedRange)
        }

        activeMarkdown.subtract(markdown)
    }
}

// MARK: - Helpers

extension MarkdownTextView {

    /// Whether files can be shared and received
    private var canFilesBeShared: Bool {
        guard let session = ZMUserSession.shared() else { return true }
        return session.fileSharingFeature.status == .enabled
    }

}

// MARK: - DownStyle Presets

extension DownStyle {
    /// The style used within the conversation system message cells.
    static var systemMessage: DownStyle = {
        let style = DownStyle()
        style.baseFont = FontSpec(.medium, .none).font!
        style.baseFontColor = UIColor.from(scheme: .textForeground)
        style.codeFont = UIFont(name: "Menlo", size: style.baseFont.pointSize) ?? style.baseFont
        style.baseParagraphStyle = ParagraphStyleDescriptor.paragraphSpacing(CGFloat.MessageCell.paragraphSpacing).style
        style.listItemPrefixSpacing = 8
        style.renderOnlyValidLinks = false
        return style
    }()

    /// The style used within the conversation message cells.
    static var normal: DownStyle = {
        let style = DownStyle()
        style.baseFont = FontSpec(.normal, .light).font!
        style.baseFontColor = UIColor.from(scheme: .textForeground)
        style.codeFont = UIFont(name: "Menlo", size: style.baseFont.pointSize) ?? style.baseFont
        style.baseParagraphStyle = NSParagraphStyle.default
        style.listItemPrefixSpacing = 8
        return style
    }()

    /// The style used within search components.
    static var search: DownStyle = {
        let style = DownStyle()
        style.baseFont = FontSpec(.normal, .light).font!
        style.baseFontColor = UIColor.from(scheme: .textForeground, variant: .dark)
        style.codeFont = UIFont(name: "Menlo", size: style.baseFont.pointSize) ?? style.baseFont
        style.baseParagraphStyle = NSParagraphStyle.default
        style.listItemPrefixSpacing = 8
        return style
    }()

    /// The style used within the input bar.
    static var compact: DownStyle = {
        let style = DownStyle()
        style.baseFont = FontSpec(.normal, .light).font!
        style.baseFontColor = UIColor.from(scheme: .textForeground)
        style.codeFont = UIFont(name: "Menlo", size: style.baseFont.pointSize) ?? style.baseFont
        style.baseParagraphStyle = NSParagraphStyle.default
        style.listItemPrefixSpacing = 8

        // headers all same size
        style.h1Size = style.baseFont.pointSize
        style.h2Size = style.h1Size
        style.h3Size = style.h1Size
        return style
    }()

    /// The style used for the reply compose preview.
    static var preview: DownStyle = {
        let style = DownStyle()
        style.baseFont = UIFont.systemFont(ofSize: 14, contentSizeCategory: .medium, weight: .light)
        style.baseFontColor = UIColor.from(scheme: .textForeground)
        style.codeFont = UIFont(name: "Menlo", size: style.baseFont.pointSize) ?? style.baseFont
        style.baseParagraphStyle = NSParagraphStyle.default
        style.listItemPrefixSpacing = 8

        // headers all same size
        style.h1Size = style.baseFont.pointSize
        style.h2Size = style.h1Size
        style.h3Size = style.h1Size
        return style
    }()
}

// MARK: - Helper Extensions

private extension NSRange {

    func textRange(in textInput: UITextInput) -> UITextRange? {
        guard
            let start = textInput.position(from: textInput.beginningOfDocument, offset: location),
            let end = textInput.position(from: start, offset: length),
            let range = textInput.textRange(from: start, to: end)
            else { return nil }

        return range
    }
}

private extension UIPasteboard {

    var hasText: Bool {
        /// Image copied from browser can be both NSString and UIImage
        return hasStrings && !hasImages
    }

}
