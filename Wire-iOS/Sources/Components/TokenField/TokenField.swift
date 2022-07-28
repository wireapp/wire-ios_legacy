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

import UIKit
import WireSystem
import WireCommonComponents

private let zmLog = ZMSLog(tag: "TokenField")

final class TokenField: UIView {
    let accessoryButtonSize: CGFloat = 32

    weak var delegate: TokenFieldDelegate?

    let textView = SearchTextView(style: .default)
    let accessoryButton: IconButton = IconButton()

    var hasAccessoryButton = false {
        didSet {
            guard oldValue != hasAccessoryButton else { return }

            accessoryButton.isHidden = !hasAccessoryButton
            updateExcludePath()
        }
    }

    private(set) var filterText: String = ""

    // MARK: - Appearance

    var toLabelText: String? {
        didSet {
            guard oldValue != toLabelText else { return }
            updateTextAttributes()
        }
    }

    var font: UIFont = FontSpec(.normal, .regular).font! {
        didSet {
            guard oldValue != font else { return }
            updateTokenAttachments()
        }
    }

    // Dynamic Type is disabled for now until the separator dots
    // vertical alignment has been fixed for larger fonts.
    let tokenTitleFont: UIFont = FontSpec(.small, .regular).font!

    var tokenTitleColor: UIColor = UIColor.white {
        didSet {
            guard oldValue != tokenTitleColor else { return }
            updateTokenAttachments()
        }
    }
    var tokenSelectedTitleColor: UIColor = UIColor(red: 0.103, green: 0.382, blue: 0.691, alpha: 1) {
        didSet {
            guard oldValue != tokenSelectedTitleColor else { return }

            updateTokenAttachments()
        }
    }
    var tokenBackgroundColor: UIColor = UIColor(red: 0.118, green: 0.467, blue: 0.745, alpha: 1) {
        didSet {
            guard oldValue != tokenBackgroundColor else { return }

            updateTokenAttachments()
        }
    }

    var tokenSelectedBackgroundColor: UIColor = UIColor.white {
        didSet {
            guard oldValue != tokenSelectedBackgroundColor else { return }

            updateTokenAttachments()
        }
    }

    var tokenBorderColor: UIColor = UIColor(red: 0.118, green: 0.467, blue: 0.745, alpha: 1) {
        didSet {
            guard oldValue != tokenBorderColor else { return }

            updateTokenAttachments()
        }
    }

    var tokenSelectedBorderColor: UIColor = UIColor(red: 0.118, green: 0.467, blue: 0.745, alpha: 1) {
        didSet {
            guard oldValue != tokenSelectedBorderColor else { return }

            updateTokenAttachments()
        }
    }

    var dotColor: UIColor = ColorScheme.default.color(named: .textDimmed)
    var tokenTextTransform: TextTransform = .upper
    var tokenOffset: CGFloat = 0 {
        didSet {
            guard tokenOffset != oldValue else {
                return
            }

            updateExcludePath()
            updateTokenAttachments()
        }
    }
    /* horisontal distance between tokens, and btw "To:" and first token */
    var tokenTitleVerticalAdjustment: CGFloat = 1 {
        didSet {
            guard oldValue != tokenTitleVerticalAdjustment else { return }

            updateTokenAttachments()
        }
    }

    // Utils

    /// rect for excluded path in textView text container
    var excludedRect = CGRect.zero {
        didSet {
            guard oldValue != excludedRect else { return }

            updateExcludePath()
        }
    }

    private(set) var userDidConfirmInput = false

    private var accessoryButtonTopMargin: NSLayoutConstraint!
    private var accessoryButtonRightMargin: NSLayoutConstraint!

    private var toLabel: UILabel = UILabel()
    private var toLabelLeftMargin: NSLayoutConstraint!
    private var toLabelTopMargin: NSLayoutConstraint!

    private(set) var tokens = [Token<NSObjectProtocol>]()
    private var textAttributes: [NSAttributedString.Key: Any] {
        let inputParagraphStyle = NSMutableParagraphStyle()
        inputParagraphStyle.lineSpacing = lineSpacing

        return [.font: font,
                .foregroundColor: textView.textColor ?? .clear,
                .paragraphStyle: inputParagraphStyle]
    }

    // Collapse

    /* in not collapsed state; in collapsed state - 1 line; default to NSUIntegerMax */
    var isCollapsed = false

    // MARK: - Init
    init() {
        super.init(frame: .zero)
        setup()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setup() {
        setupSubviews()
        setupConstraints()
        setupStyle()
    }

    private func setupConstraints() {
        let views = [
            "textView": textView,
            "toLabel": toLabel,
            "button": accessoryButton
        ]
        let metrics = [
            "left": textView.textContainerInset.left,
            "top": textView.textContainerInset.top,
            "right": textView.textContainerInset.right,
            "bSize": accessoryButtonSize,
            "bTop": accessoryButtonTop,
            "bRight": accessoryButtonRight
        ]

        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[textView]|", options: [], metrics: nil, views: views))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[textView]|", options: [], metrics: nil, views: views))
        accessoryButtonRightMargin = NSLayoutConstraint.constraints(withVisualFormat: "H:[button]-(bRight)-|", options: [], metrics: metrics, views: views)[0]
        accessoryButtonTopMargin = NSLayoutConstraint.constraints(withVisualFormat: "V:|-(bTop)-[button]", options: [], metrics: metrics, views: views)[0]
        addConstraints([accessoryButtonRightMargin, accessoryButtonTopMargin])
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:[button(bSize)]", options: [], metrics: metrics, views: views))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[button(bSize)]", options: [], metrics: metrics, views: views))

        toLabelLeftMargin = NSLayoutConstraint.constraints(withVisualFormat: "H:|-(left)-[toLabel]", options: [], metrics: metrics, views: views)[0]
        toLabelTopMargin = NSLayoutConstraint.constraints(withVisualFormat: "V:|-(top)-[toLabel]", options: [], metrics: metrics, views: views)[0]
        textView.addConstraints([toLabelLeftMargin, toLabelTopMargin])

        updateTextAttributes()
    }

    // MARK: - Appearance

    var lineSpacing: CGFloat = 8 {
        didSet {
            guard oldValue != lineSpacing else {
                return
            }

            updateTextAttributes()
        }
    }

    // MARK: - UIView overrides

    override var intrinsicContentSize: CGSize {
        let height = textView.contentSize.height
        let maxHeight = fontLineHeight * CGFloat(numberOfLines) + lineSpacing * CGFloat(numberOfLines - 1) + textView.textContainerInset.top + textView.textContainerInset.bottom
        let minHeight = fontLineHeight + textView.textContainerInset.top + textView.textContainerInset.bottom

        return CGSize(width: UIView.noIntrinsicMetric, height: isCollapsed ? minHeight: max(min(height, maxHeight), minHeight))
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        var anyTokenUpdated = false
        for token in tokens where token.maxTitleWidth == 0 {
            updateMaxTitleWidth(for: token)
            anyTokenUpdated = true
        }

        if anyTokenUpdated {
            updateTokenAttachments()
            let wholeRange = NSRange(location: 0, length: textView.attributedText.length)
            textView.layoutManager.invalidateLayout(forCharacterRange: wholeRange, actualCharacterRange: nil)
        }
    }

    override var isFirstResponder: Bool {
        return textView.isFirstResponder
    }

    override var canBecomeFirstResponder: Bool {
        return textView.canBecomeFirstResponder
    }

    override var canResignFirstResponder: Bool {
        return textView.canResignFirstResponder
    }

    override func becomeFirstResponder() -> Bool {
        setCollapsed(false, animated: true)
        return textView.becomeFirstResponder()
    }

    override func resignFirstResponder() -> Bool {
        super.resignFirstResponder()
        return textView.resignFirstResponder()
    }

    // MARK: - Interface

    func addToken(forTitle title: String,
                  representedObject object: NSObjectProtocol) {
        let token = Token(title: title, representedObject: object)
        addToken(token)
    }

    func addToken(_ token: Token<NSObjectProtocol>) {
        guard !tokens.contains(token) else {
            return
        }

        tokens.append(token)

        updateMaxTitleWidth(for: token)

        if !isCollapsed {
            textView.attributedText = string(forTokens: tokens)
            // Calling -insertText: forces textView to update its contentSize, while other public methods do not.
            // Broken contentSize leads to broken scrolling to bottom of input field.
            textView.insertText("")

            delegate?.tokenField(self, changedFilterTextTo: "")

            invalidateIntrinsicContentSize()

            // Move the cursor to the end of the input field
            textView.selectedRange = NSRange(location: textView.text.utf16.count, length: 0)

            // autoscroll to the end of the input field
            setNeedsLayout()
            updateLayout()
            scrollToBottomOfInputField()
        } else {
            textView.attributedText = collapsedString
            invalidateIntrinsicContentSize()
        }
    }

    func updateMaxTitleWidth(for token: Token<NSObjectProtocol>) {
        var tokenMaxSizeWidth = textView.textContainer.size.width
        if tokens.isEmpty {
            tokenMaxSizeWidth -= toLabel.frame.size.width + (hasAccessoryButton ? accessoryButton.frame.size.width : 0) + tokenOffset
        } else if tokens.count == 1 {
            tokenMaxSizeWidth -= hasAccessoryButton ? accessoryButton.frame.size.width : 0
        }

        token.maxTitleWidth = tokenMaxSizeWidth
    }

    // searches by isEqual:
    func token(forRepresentedObject object: NSObjectProtocol) -> Token<NSObjectProtocol>? {
        return tokens.first(where: { $0.representedObject == HashBox(value: object)})
    }

    private func scrollToBottomOfInputField() {
        if textView.contentSize.height > textView.bounds.size.height {
            textView.setContentOffset(CGPoint(x: 0, y: textView.contentSize.height - textView.bounds.size.height), animated: true)
        } else {
            textView.contentOffset = .zero
        }
    }

    var numberOfLines: Int = Int.max {
        didSet {
            if oldValue != numberOfLines {
                invalidateIntrinsicContentSize()
            }
        }
    }

    func setCollapsed(_ collapsed: Bool, animated: Bool = false) {
        guard isCollapsed != collapsed, !tokens.isEmpty else {
            return
        }

        isCollapsed = collapsed

        let animationBlock = {
            self.invalidateIntrinsicContentSize()
            self.layoutIfNeeded()
        }

        let compeltionBlock: ((Bool) -> Void)? = {[weak self] _ in

            guard let weakSelf = self else { return }

            if weakSelf.isCollapsed {
                weakSelf.textView.attributedText = weakSelf.collapsedString
                weakSelf.invalidateIntrinsicContentSize()
                UIView.animate(withDuration: 0.2, animations: {
                    weakSelf.textView.setContentOffset(CGPoint.zero, animated: false)
                })
            } else {
                weakSelf.textView.attributedText = weakSelf.string(forTokens: weakSelf.tokens)
                weakSelf.invalidateIntrinsicContentSize()
                if weakSelf.textView.attributedText.length > 0 {
                    weakSelf.textView.selectedRange = NSRange(location: weakSelf.textView.attributedText.length, length: 0)
                    UIView.animate(withDuration: 0.2, animations: {
                        weakSelf.textView.scrollRangeToVisible(weakSelf.textView.selectedRange)
                    })
                }
            }
        }

        if animated {
            UIView.animate(withDuration: 0.25, animations: animationBlock, completion: compeltionBlock)
        } else {
            animationBlock()
            compeltionBlock?(true)
        }
    }

    // MARK: - Layout
    var fontLineHeight: CGFloat {
        return font.lineHeight
    }

    private var accessoryButtonTop: CGFloat {
        return textView.textContainerInset.top + (fontLineHeight - accessoryButtonSize) / 2 - textView.contentOffset.y
    }

    private var accessoryButtonRight: CGFloat {
        return textView.textContainerInset.right
    }

    private func updateLayout() {
        if toLabelText?.isEmpty == false {
            toLabelLeftMargin.constant = textView.textContainerInset.left
            toLabelTopMargin.constant = textView.textContainerInset.top
        }
        if hasAccessoryButton {
            accessoryButtonRightMargin.constant = accessoryButtonRight
            accessoryButtonTopMargin.constant = accessoryButtonTop
        }
        layoutIfNeeded()
    }

    // MARK: - Utility
    var collapsedString: NSAttributedString? {
        let collapsedText = " ...".localized

        return NSAttributedString(string: collapsedText, attributes: textAttributes)
    }

    /// clean filter text other then NSTextAttachment
    func clearFilterText() {
        guard let text = textView.text else { return }

        guard let attachmentCharacter = UnicodeScalar.textAttachmentCharacter,
            let firstCharacterIndex = text.unicodeScalars.firstIndex(where: { $0 != attachmentCharacter && !CharacterSet.whitespaces.contains($0) }) else {
                return
        }

        filterText = ""

        let rangeToDelete = firstCharacterIndex..<text.endIndex
        let nsRange = textView.text.nsRange(from: rangeToDelete)

        textView.textStorage.beginEditing()
        textView.textStorage.deleteCharacters(in: nsRange)
        textView.textStorage.endEditing()
        textView.insertText("")
        textView.resignFirstResponder()

        invalidateIntrinsicContentSize()
        layoutIfNeeded()
    }

    private func updateTextAttributes() {
        textView.typingAttributes = textAttributes
        textView.textStorage.beginEditing()
        textView.textStorage.addAttributes(textAttributes, range: NSRange(location: 0, length: textView.textStorage.length))
        textView.textStorage.endEditing()

        if let toLabelText = toLabelText {
            toLabel.attributedText = NSMutableAttributedString(string: toLabelText, attributes: textAttributes)
        } else {
            toLabel.text = ""
        }

        updateExcludePath()
    }

    private func updateExcludePath() {
        updateLayout()

        var exclusionPaths: [UIBezierPath] = []

        if excludedRect.equalTo(CGRect.zero) == false {
            let transform = CGAffineTransform(translationX: textView.contentOffset.x, y: textView.contentOffset.y)
            let transformedRect = excludedRect.applying(transform)
            let path = UIBezierPath(rect: transformedRect)
            exclusionPaths.append(path)
        }

        if toLabelText?.isEmpty == false {
            var transformedRect = toLabel.frame.offsetBy(dx: -textView.textContainerInset.left, dy: -textView.textContainerInset.top)
            transformedRect.size.width += tokenOffset
            let path = UIBezierPath(rect: transformedRect)
            exclusionPaths.append(path)
        }

        if hasAccessoryButton {
            // Exclude path should be relative to content of button, not frame.
            // Assuming intrinsic content size is a size of visual content of the button,
            // 1. Calcutale frame with same center as accessoryButton has, but with size of intrinsicContentSize
            var transformedRect = accessoryButton.frame
            let contentSize = CGSize(width: accessoryButtonSize, height: accessoryButtonSize)
            transformedRect = transformedRect.insetBy(dx: 0.5 * (transformedRect.size.width - contentSize.width), dy: 0.5 * (transformedRect.size.height - contentSize.height))

            // 2. Convert frame to textView coordinate system
            transformedRect = textView.convert(transformedRect, from: self)
            let transform = CGAffineTransform(translationX: -textView.textContainerInset.left, y: -textView.textContainerInset.top)
            transformedRect = transformedRect.applying(transform)

            let path = UIBezierPath(rect: transformedRect)
            exclusionPaths.append(path)
        }

        textView.textContainer.exclusionPaths = exclusionPaths
    }

    // MARK: - UIScrollViewDelegate
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == textView {
            updateExcludePath()
        }
    }

    private func setupSubviews() {
        // this prevents accessoryButton to be visible sometimes on scrolling
        clipsToBounds = true

        textView.tokenizedTextViewDelegate = self
        textView.delegate = self
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.textDragInteraction?.isEnabled = false
        addSubview(textView)

        toLabel.translatesAutoresizingMaskIntoConstraints = false
        toLabel.font = font
        toLabel.text = toLabelText
        toLabel.backgroundColor = UIColor.clear
        textView.addSubview(toLabel)

        // Accessory button could be a subview of textView,
        // but there are bugs with setting constraints from subview to UITextView trailing.
        // So we add button as subview of self, and update its position on scrolling.
        accessoryButton.translatesAutoresizingMaskIntoConstraints = false
        accessoryButton.isHidden = !hasAccessoryButton
        addSubview(accessoryButton)
    }

    private func setupStyle() {
        tokenOffset = 4

        textView.tintColor = .accent()
        textView.autocorrectionType = .no
        textView.returnKeyType = .go
        textView.placeholderFont = .smallRegularFont
        textView.placeholderTextColor = SemanticColors.SearchBar.textInputViewPlaceholder
        textView.placeholderTextContainerInset = UIEdgeInsets(top: 0, left: 48, bottom: 0, right: 0)
        textView.placeholderTextTransform = .upper
        textView.lineFragmentPadding = 0
    }

    // MARK: - Utility

    func updateTokenAttachments() {
        textView.attributedText.enumerateAttachment { tokenAttachment, _, _ in
            (tokenAttachment as? TokenTextAttachment)?.refreshImage()
        }
    }

    private func string(forTokens tokens: [Token<NSObjectProtocol>]) -> NSAttributedString {
        let string = NSMutableAttributedString()
        for token in tokens {
            let tokenAttachment = TokenTextAttachment(token: token, tokenField: self)
            let tokenString = NSAttributedString(attachment: tokenAttachment)

            string.append(tokenString)

            let separatorAttachment = TokenSeparatorAttachment(token: token, tokenField: self)
            let separatorString = NSAttributedString(attachment: separatorAttachment)

            string.append(separatorString)
        }

        return string && textAttributes
    }

    /// update currentTokens with textView's current attributedText text after the textView change the text
    func filterUnwantedAttachments() {
        var updatedCurrentTokens = Set<Token<NSObjectProtocol>>()
        var updatedCurrentSeparatorTokens: Set<Token<NSObjectProtocol>> = []

        textView.attributedText.enumerateAttachment { textAttachment, _, _ in

            if let token = (textAttachment as? TokenTextAttachment)?.token,
                !updatedCurrentTokens.contains(token) {
                updatedCurrentTokens.insert(token)
            }

            if let token = (textAttachment as? TokenSeparatorAttachment)?.token,
                !updatedCurrentSeparatorTokens.contains(token) {
                updatedCurrentSeparatorTokens.insert(token)
            }
        }

        updatedCurrentTokens = updatedCurrentTokens.intersection(updatedCurrentSeparatorTokens)

        var deletedTokens = Set<Token>(tokens)
        deletedTokens.subtract(updatedCurrentTokens)

        if !deletedTokens.isEmpty {
            removeTokens(Array(deletedTokens))
        }
        tokens.removeAll(where: { deletedTokens.contains($0) })
        delegate?.tokenField(self, changedTokensTo: tokens)
    }

    // MARK: - remove token

    func removeAllTokens() {
        removeTokens(tokens)
        textView.showOrHidePlaceholder()
    }

    func removeToken(_ token: Token<NSObjectProtocol>) {
        removeTokens([token])
    }

    private func removeTokens(_ tokensToRemove: [Token<NSObjectProtocol>]) {
        var rangesToRemove: [NSRange] = []

        textView.attributedText.enumerateAttachment { textAttachment, range, _ in
            if let token = (textAttachment as? TokenContainer)?.token,
                tokensToRemove.contains(token) {
                rangesToRemove.append(range)
            }
        }

        // Delete ranges from the end of string till the beginning: this keeps range locations valid.
        rangesToRemove.sort(by: { rangeValue1, rangeValue2 in
            rangeValue1.location > rangeValue2.location
        })

        textView.textStorage.beginEditing()
        for rangeValue in rangesToRemove {
            textView.textStorage.deleteCharacters(in: rangeValue)
        }
        textView.textStorage.endEditing()

        tokens.removeAll(where: { tokensToRemove.contains($0) })

        invalidateIntrinsicContentSize()
        updateTextAttributes()

        textView.showOrHidePlaceholder()
    }

    private func rangeIncludesRange(_ range: NSRange, _ includedRange: NSRange) -> Bool {
        return range == range.union(includedRange)
    }

    private func notifyIfFilterTextChanged() {
        var indexOfFilterText = 0
        textView.attributedText.enumerateAttachment { tokenAttachment, range, _ in
            if tokenAttachment is TokenTextAttachment {
                indexOfFilterText = range.upperBound
            }
        }

        let oldFilterText = filterText
        self.filterText = ((textView.text as NSString).substring(from: indexOfFilterText)).replacingOccurrences(of: "\u{FFFC}", with: "")
        if oldFilterText != filterText {
            delegate?.tokenField(self, changedFilterTextTo: filterText)
        }
    }

}

// MARK: - TokenizedTextViewDelegate

extension TokenField: TokenizedTextViewDelegate {
    func tokenizedTextView(_ textView: TokenizedTextView,
                           didTapTextRange range: NSRange,
                           fraction: CGFloat) {
        if isCollapsed {
            setCollapsed(false, animated: true)
            return
        }

        if fraction >= 1 && range.location == self.textView.textStorage.length - 1 {
            return
        }

        if range.location < textView.textStorage.length {
            textView.attributedText.enumerateAttachment { tokenAttachemnt, range, _ in
                if tokenAttachemnt is TokenTextAttachment {
                    textView.selectedRange = range
                }
            }
        }
    }

    func tokenizedTextView(_ textView: TokenizedTextView, textContainerInsetChanged textContainerInset: UIEdgeInsets) {
        invalidateIntrinsicContentSize()
        updateExcludePath()
        updateLayout()
    }

}

// MARK: - UITextViewDelegate

extension TokenField: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith textAttachment: NSTextAttachment, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        return !(textAttachment is TokenSeparatorAttachment)
    }

    func textViewDidChange(_ textView: UITextView) {
        userDidConfirmInput = false

        filterUnwantedAttachments()
        notifyIfFilterTextChanged()
        invalidateIntrinsicContentSize()
    }

    func textViewDidChangeSelection(_ textView: UITextView) {
        zmLog.debug("Selection changed: NSStringFromRange(textView.selectedRange)")

        var modifiedSelectionRange = NSRange(location: 0, length: 0)
        var hasModifiedSelection = false

        textView.attributedText.enumerateAttachment { tokenAttachment, range, _ in
            if let tokenAttachment = tokenAttachment as? TokenTextAttachment {
                tokenAttachment.isSelected = rangeIncludesRange(textView.selectedRange, range)
                textView.layoutManager.invalidateDisplay(forCharacterRange: range)

                if rangeIncludesRange(textView.selectedRange, range) {
                    modifiedSelectionRange = (hasModifiedSelection ? modifiedSelectionRange : range).union(range)
                    hasModifiedSelection = true
                }
                zmLog.info("    person attachement: \(tokenAttachment.token.title) at range: \(range) selected: \(tokenAttachment.isSelected)")
            }
        }

        if hasModifiedSelection, textView.selectedRange != modifiedSelectionRange {
            textView.selectedRange = modifiedSelectionRange
        }
    }

    func textView(_ textView: UITextView,
                  shouldChangeTextIn range: NSRange,
                  replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            userDidConfirmInput = true
            delegate?.tokenFieldDidConfirmSelection(self)

            return false
        }

        // backspace - search for first TokenTextAttachment, select it.(and remove last token)
        if range.length == 1, text.isEmpty {
            var cancelBackspace = false
            textView.attributedText.enumerateAttachment(range: range) { tokenAttachment, range, stop in
                if let tokenAttachment = tokenAttachment as? TokenTextAttachment {
                    if !tokenAttachment.isSelected {
                        textView.selectedRange = range
                        cancelBackspace = true
                    }

                    stop.pointee = true
                }
            }

            if cancelBackspace {
                return false
            }
        }

        // Inserting text between tokens does not make sense for this control.
        // If there are any tokens after the insertion point, move the cursor to the end instead, but only for insertions
        // If the range length is >0, we are trying to replace something instead, and that’s a bit more complex,
        // so don’t do any magic in that case

        if !text.isEmpty,
           let attachmentCharacter = UnicodeScalar.textAttachmentCharacter,
           let textRange = Range(range, in: textView.text),
           textView.text.suffix(from: textRange.upperBound).unicodeScalars.contains(attachmentCharacter) {
            textView.selectedRange = NSRange(location: textView.text.utf16.count, length: 0)
        }
        updateTextAttributes()

        return true
    }
}

extension UnicodeScalar {
    fileprivate static var textAttachmentCharacter: UnicodeScalar? {
        return UnicodeScalar(NSTextAttachment.character)
    }
}
