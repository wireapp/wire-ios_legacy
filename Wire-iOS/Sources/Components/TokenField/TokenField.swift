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

private let zmLog = ZMSLog(tag: "TokenField")

let accessoryButtonSize: CGFloat = 32.0

final class TokenField: UIView {
    weak var delegate: TokenFieldDelegate?
    let textView: TokenizedTextView = TokenizedTextView()
    var hasAccessoryButton = false
    var accessoryButton: IconButton?
    private(set) var tokens: [Token]?
    private(set) var filterText: String = ""
    
    // Appearance
    var toLabelText: String?
    var font: UIFont?
    var textColor: UIColor?
    var tokenTitleFont: UIFont?
    var tokenTitleColor: UIColor?
    var tokenSelectedTitleColor: UIColor?
    var tokenBackgroundColor: UIColor?
    var tokenSelectedBackgroundColor: UIColor?
    var tokenBorderColor: UIColor?
    var tokenSelectedBorderColor: UIColor?
    var dotColor: UIColor?
    var tokenTextTransform: TextTransform?
    var lineSpacing: CGFloat = 0.0
    var tokenOffset: CGFloat = 0.0
    /* horisontal distance between tokens, and btw "To:" and first token */    var tokenTitleVerticalAdjustment: CGFloat = 0.0
    // Utils
    var excludedRect = CGRect.zero
    /* rect for excluded path in textView text container */
    
    private(set) var userDidConfirmInput = false
    
    private var accessoryButtonTopMargin: NSLayoutConstraint!
    private var accessoryButtonRightMargin: NSLayoutConstraint!
    private var toLabel: UILabel?
    private var toLabelLeftMargin: NSLayoutConstraint?
    private var toLabelTopMargin: NSLayoutConstraint?
    private var currentTokens: [AnyHashable]?
    private var textAttributes: [AnyHashable : Any]?

    // Collapse
    var numberOfLines = 0
    /* in not collapsed state; in collapsed state - 1 line; default to NSUIntegerMax */
    var collapsed = false
    
    
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
    func setup() {
        currentTokens = []
        numberOfLines = UInt.max
        
        setupDefaultAppearance()
        setupSubviews()
        setupConstraints()
        setupStyle()
    }
    
    func setupDefaultAppearance() {
        setupFonts()
        textColor = UIColor.black
        lineSpacing = 8.0
        hasAccessoryButton = false
        tokenTitleVerticalAdjustment = 1
        
        tokenTitleColor = UIColor.white
        tokenSelectedTitleColor = UIColor(red: 0.103, green: 0.382, blue: 0.691, alpha: 1.000)
        tokenBackgroundColor = UIColor(red: 0.118, green: 0.467, blue: 0.745, alpha: 1.000)
        tokenSelectedBackgroundColor = UIColor.white
        tokenBorderColor = UIColor(red: 0.118, green: 0.467, blue: 0.745, alpha: 1.000)
        tokenSelectedBorderColor = UIColor(red: 0.118, green: 0.467, blue: 0.745, alpha: 1.000)
        tokenTextTransform = .upper
        dotColor = ColorScheme.default.color(named: .textDimmed)
    }
    
    private func setupConstraints() {
        let views = [
            "textView": textView,
            "toLabel": toLabel,
            "button": accessoryButton
        ]
        let metrics = [
            "left": NSNumber(value: Float(textView.textContainerInset.left)),
            "top": NSNumber(value: Float(textView.textContainerInset.top)),
            "right": NSNumber(value: Float(textView.textContainerInset.right)),
            "bSize": NSNumber(value: accessoryButtonSize),
            "bTop": NSNumber(value: accessoryButtonTop),
            "bRight": NSNumber(value: accessoryButtonRight)
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
    func setFont(_ font: UIFont?) {
        if self.font == font {
            return
        }
        self.font = font
        updateTextAttributes()
    }
    
    var textColor: UIColor! {
        get {
            return super.textColor
        }
        set(textColor) {
            if self.textColor == textColor {
                return
            }
            self.textColor = textColor
            updateTextAttributes()
        }
    }
    
    var lineSpacing: CGFloat {
        get {
            return super.lineSpacing
        }
        set(lineSpacing) {
            if self.lineSpacing == lineSpacing {
                return
            }
            self.lineSpacing = lineSpacing
            updateTextAttributes()
        }
    }
    
    func setTokenOffset(_ tokenOffset: CGFloat) {
        if self.tokenOffset == tokenOffset {
            return
        }
        self.tokenOffset = tokenOffset
        updateExcludePath()
        updateTokenAttachments()
    }
    
    func textAttributes() -> [AnyHashable : Any]? {
        var attributes: [AnyHashable : Any] = [:]
        
        var inputParagraphStyle = NSMutableParagraphStyle()
        inputParagraphStyle.lineSpacing = lineSpacing
        attributes[NSAttributedString.Key.paragraphStyle] = inputParagraphStyle
        
        if font {
            attributes[NSAttributedString.Key.font] = font
        }
        if textColor != nil {
            attributes[NSAttributedString.Key.foregroundColor] = textColor
        }
        
        return attributes
    }

    func setToLabelText(_ toLabelText: String?) {
        if (self.toLabelText == toLabelText) {
            return
        }
        self.toLabelText = toLabelText
        updateTextAttributes()
    }
    
    func setHasAccessoryButton(_ hasAccessoryButton: Bool) {
        if self.hasAccessoryButton == hasAccessoryButton {
            return
        }
        
        self.hasAccessoryButton = hasAccessoryButton
        accessoryButton.hidden = !hasAccessoryButton
        updateExcludePath()
    }
    
    func setTokenTitleColor(_ color: UIColor?) {
        if tokenTitleColor == color {
            return
        }
        tokenTitleColor = color
        updateTokenAttachments()
    }
    
    func setTokenSelectedTitleColor(_ color: UIColor?) {
        if tokenSelectedTitleColor == color {
            return
        }
        tokenSelectedTitleColor = color
        updateTokenAttachments()
    }
    
    var tokenBackgroundColor: UIColor! {
        get {
            return super.tokenBackgroundColor
        }
        set(color) {
            if tokenBackgroundColor == color {
                return
            }
            tokenBackgroundColor = color
            updateTokenAttachments()
        }
    }
    
    func setTokenSelectedBackgroundColor(_ color: UIColor?) {
        if tokenSelectedBackgroundColor == color {
            return
        }
        tokenSelectedBackgroundColor = color
        updateTokenAttachments()
    }

    func setTokenBorderColor(_ color: UIColor?) {
        if tokenBorderColor == color {
            return
        }
        tokenBorderColor = color
        updateTokenAttachments()
    }
    
    func setTokenSelectedBorderColor(_ color: UIColor?) {
        if tokenSelectedBorderColor == color {
            return
        }
        tokenSelectedBorderColor = color
        updateTokenAttachments()
    }
    
    func setTokenTitleVerticalAdjustment(_ tokenTitleVerticalAdjustment: CGFloat) {
        if self.tokenTitleVerticalAdjustment == tokenTitleVerticalAdjustment {
            return
        }
        self.tokenTitleVerticalAdjustment = tokenTitleVerticalAdjustment
        updateTokenAttachments()
    }
    
    // MARK: - UIView overrides
    override var isFirstResponder: Bool {
        return textView.isFirstResponder
    }
    
    var canBecomeFirstResponder: Bool {
        return textView.canBecomeFirstResponder
    }
    
    var canResignFirstResponder: Bool {
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
    func tokens() -> [AnyHashable]? {
        return currentTokens
    }
    
    func addToken(forTitle title: String?, representedObject object: Any?) {
        let token = Token(title: title, representedObject: object)
        add(token)
    }
    
    func add(_ token: Token?) {
        if let token = token {
            if !currentTokens.contains(token) {
                currentTokens.append(token)
            } else {
                return
            }
        }
        
        updateMaxTitleWidth(for: token)
        
        if !isCollapsed {
            textView.attributedText = string(forTokens: currentTokens)
            // Calling -insertText: forces textView to update its contentSize, while other public methods do not.
            // Broken contentSize leads to broken scrolling to bottom of input field.
            textView.insertText("")
            
            if delegate.responds(to: #selector(tokenField(_:changedFilterTextTo:))) {
                delegate.tokenField(self, changedFilterTextTo: "")
            }
            
            invalidateIntrinsicContentSize()
            
            // Move the cursor to the end of the input field
            textView.selectedRange = NSRange(location: textView.text.count, length: 0)
            
            // autoscroll to the end of the input field
            setNeedsLayout()
            updateLayout()
            scrollToBottomOfInputField()
        } else {
            textView.attributedText = collapsedString()
            invalidateIntrinsicContentSize()
        }
    }

    func updateMaxTitleWidth(for token: Token?) {
        var tokenMaxSizeWidth = textView.textContainer.size.width
        if currentTokens.count == 0 {
            tokenMaxSizeWidth -= toLabel.frame.size.width + (hasAccessoryButton ? accessoryButton.frame.size.width : 0.0) + tokenOffset
        } else if currentTokens.count == 1 {
            tokenMaxSizeWidth -= hasAccessoryButton ? accessoryButton.frame.size.width : 0.0
        }
        token?.maxTitleWidth = tokenMaxSizeWidth
    }
    
    // searches by isEqual:
    func token(forRepresentedObject object: Any?) -> Token? {
        for token in currentTokens {
            if token.representedObject == object {
                return token
            }
        }
        return nil
    }
    
    func scrollToBottomOfInputField() {
        if textView.contentSize.height > textView.bounds.size.height {
            textView.setContentOffset(CGPoint(x: 0.0, y: textView.contentSize.height - textView.bounds.size.height), animated: true)
        } else {
            textView.contentOffset = CGPoint.zero
        }
    }
    
    func setExcludedRect(_ excludedRect: CGRect) {
        if self.excludedRect.equalTo(excludedRect) {
            return
        }
        
        self.excludedRect = excludedRect
        updateExcludePath()
    }
    
    var numberOfLines: Int {
        get {
            return super.numberOfLines
        }
        set(numberOfLines) {
            if self.numberOfLines != numberOfLines {
                self.numberOfLines = numberOfLines
                invalidateIntrinsicContentSize()
            }
        }
    }
    
    func setCollapsed(_ collapsed: Bool) {
        setCollapsed(collapsed, animated: false)
    }
    
    func addToken(forTitle title: String?, representedObject object: Any?) {
        let token = Token(title: title, representedObject: object)
        add(token)
    }

    func add(_ token: Token?) {
        if let token = token {
            if !currentTokens.contains(token) {
                currentTokens.append(token)
            } else {
                return
            }
        }
        
        updateMaxTitleWidth(for: token)
        
        if !isCollapsed {
            textView.attributedText = string(forTokens: currentTokens)
            // Calling -insertText: forces textView to update its contentSize, while other public methods do not.
            // Broken contentSize leads to broken scrolling to bottom of input field.
            textView.insertText("")
            
            if delegate.responds(to: #selector(tokenField(_:changedFilterTextTo:))) {
                delegate.tokenField(self, changedFilterTextTo: "")
            }
            
            invalidateIntrinsicContentSize()
            
            // Move the cursor to the end of the input field
            textView.selectedRange = NSRange(location: textView.text.count, length: 0)
            
            // autoscroll to the end of the input field
            setNeedsLayout()
            updateLayout()
            scrollToBottomOfInputField()
        } else {
            textView.attributedText = collapsedString()
            invalidateIntrinsicContentSize()
        }
    }

    func setCollapsed(_ collapsed: Bool, animated: Bool) {
        if self.collapsed == collapsed {
            return
        }
        
        if currentTokens.count == 0 {
            return
        }
        
        self.collapsed = collapsed
        
        let animationBlock = {
            self.invalidateIntrinsicContentSize()
            self.layoutIfNeeded()
        }
        ZM_WEAK(self)
        let compeltionBlock: ((Bool) -> Void)? = { finnished in
            ZM_STRONG(self)
            if self.collapsed {
                self.textView.attributedText = self.collapsedString()
                self.invalidateIntrinsicContentSize()
                UIView.animate(withDuration: 0.2, animations: {
                    self.textView.setContentOffset(CGPoint.zero, animated: false)
                })
            } else {
                self.textView.attributedText = self.string(forTokens: self.currentTokens)
                self.invalidateIntrinsicContentSize()
                if self.textView.attributedText.length > 0 {
                    self.textView.selectedRange = NSRange(location: self.textView.attributedText.length, length: 0)
                    UIView.animate(withDuration: 0.2, animations: {
                        self.textView.scrollRangeToVisible(self.textView.selectedRange)
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
    var intrinsicContentSize: CGSize {
        let height = textView.contentSize.height
        let maxHeight = font.lineHeight * CGFloat(numberOfLines) + lineSpacing * CGFloat((numberOfLines - 1)) + textView.textContainerInset.top + textView.textContainerInset.bottom
        let minHeight = font.lineHeight * 1 + textView.textContainerInset.top + textView.textContainerInset.bottom
        
        if collapsed {
            return CGSize(width: UIView.noIntrinsicMetric, height: minHeight)
        } else {
            return CGSize(width: UIView.noIntrinsicMetric, height: max(min(height, maxHeight), minHeight))
        }
    }
    
    func accessoryButtonTop() -> CGFloat {
        return textView.textContainerInset.top + (font.lineHeight - accessoryButtonSize) / 2 - textView.contentOffset.y
    }
    
    func accessoryButtonRight() -> CGFloat {
        return textView.textContainerInset.right
    }
    
    private func updateLayout() {
        if toLabelText.length > 0 {
            toLabelLeftMargin.constant = textView.textContainerInset.left
            toLabelTopMargin.constant = textView.textContainerInset.top
        }
        if hasAccessoryButton {
            accessoryButtonRightMargin.constant = accessoryButtonRight()
            accessoryButtonTopMargin.constant = accessoryButtonTop()
        }
        layoutIfNeeded()
    }
    
    func layoutSubviews() {
        super.layoutSubviews()
        
        var anyTokenUpdated = false
        for token in currentTokens {
            if token.maxTitleWidth == 0 {
                updateMaxTitleWidth(for: token)
                anyTokenUpdated = true
            }
        }
        
        if anyTokenUpdated {
            updateTokenAttachments()
            let wholeRange = NSRange(location: 0, length: textView.attributedText.length)
            textView.layoutManager.invalidateLayout(forCharacterRange: wholeRange, actualCharacterRange: nil)
        }
    }

    // MARK: - Utility
    func collapsedString() -> NSAttributedString? {
        let collapsedText = NSLocalizedString(" ...", comment: "")
        
        return NSAttributedString(string: collapsedText, attributes: textAttributes)
    }
    
    func clearFilterText() {
        var firstCharacterIndex = NSNotFound
        
        let notWhitespace = CharacterSet.whitespacesAndNewlines.inverted
        
        (textView.text as NSString).enumerateSubstrings(in: NSRange(location: 0, length: textView.text.count), options: .byComposedCharacterSequences, using: { substring, substringRange, enclosingRange, stop in
            if (substring?.count ?? 0) != 0 && (substring?[substring?.index(substring?.startIndex, offsetBy: 0)] != .character) && (substring as NSString?)?.rangeOfCharacter(from: notWhitespace).location != NSNotFound {
                firstCharacterIndex = substringRange.location
                stop = UnsafeMutablePointer<ObjCBool>(mutating: &true)
            }
        })
        
        filterText = ""
        if firstCharacterIndex != NSNotFound {
            let rangeToClear = NSRange(location: firstCharacterIndex, length: textView.text.count - firstCharacterIndex)
            
            textView.textStorage.beginEditing()
            textView.textStorage.deleteCharacters(in: rangeToClear)
            textView.textStorage.endEditing()
            textView.insertText("")
            
            invalidateIntrinsicContentSize()
            layoutIfNeeded()
        }
    }
    
    private func updateTextAttributes() {
        textView.typingAttributes = textAttributes
        textView.textStorage.beginEditing()
        textView.textStorage.addAttributes(textAttributes, range: NSRange(location: 0, length: textView.textStorage.length))
        textView.textStorage.endEditing()
        
        if toLabelText {
            toLabel.attributedText = NSMutableAttributedString(string: toLabelText, attributes: textAttributes)
        } else {
            toLabel.text = ""
        }
        
        updateExcludePath()
    }


    private func updateExcludePath() {
        updateLayout()
        
        var exclusionPaths: [AnyHashable]? = []
        
        if excludedRect.equalTo(CGRect.zero) == false {
            let transform = CGAffineTransform(translationX: textView.contentOffset.x, y: textView.contentOffset.y)
            var transformedRect = excludedRect.applying(transform)
            let path = UIBezierPath(rect: transformedRect)
            exclusionPaths?.append(path)
        }
        
        if toLabelText.length > 0 {
            var transformedRect = toLabel.frame.offsetBy(dx: -textView.textContainerInset.left, dy: -textView.textContainerInset.top)
            transformedRect.size.width += tokenOffset
            let path = UIBezierPath(rect: transformedRect)
            exclusionPaths?.append(path)
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
            exclusionPaths?.append(path)
        }
        
        if let exclusionPaths = exclusionPaths as? [UIBezierPath] {
            textView.textContainer.exclusionPaths = exclusionPaths
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

    func setupSubviews() {
        // this prevents accessoryButton to be visible sometimes on scrolling
        clipsToBounds = true

        textView.tokenizedTextViewDelegate = self
        textView.delegate = self
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.backgroundColor = UIColor.clear
        if #available(iOS 11, *) {
            textView.textDragInteraction?.isEnabled = false
        }
        addSubview(textView)

        toLabel = UILabel()
        toLabel.translatesAutoresizingMaskIntoConstraints = false
        toLabel.font = font
        toLabel.text = toLabelText
        toLabel.backgroundColor = UIColor.clear
        textView.addSubview(toLabel)

        self.textView = textView

        // Accessory button could be a subview of textView,
        // but there are bugs with setting constraints from subview to UITextView trailing.
        // So we add button as subview of self, and update its position on scrolling.
        accessoryButton = IconButton()
        accessoryButton.translatesAutoresizingMaskIntoConstraints = false
        accessoryButton.isHidden = !hasAccessoryButton
        addSubview(accessoryButton)
    }

    @objc func setupStyle() {
        tokenOffset = 4

        textView.tintColor = .accent()
        textView.autocorrectionType = .no
        textView.returnKeyType = .go
        textView.placeholderFont = .smallRegularFont
        textView.placeholderTextContainerInset = UIEdgeInsets(top: 0, left: 48, bottom: 0, right: 0)
        textView.placeholderTextTransform = .upper
        textView.lineFragmentPadding = 0
    }

    @objc func setupFonts() {
        // Dynamic Type is disabled for now until the separator dots
        // vertical alignment has been fixed for larger fonts.
        let schema = FontScheme(contentSizeCategory: .medium)
        font = schema.font(for: .init(.normal, .regular))
        tokenTitleFont = schema.font(for: .init(.small, .regular))
    }

    // MARK: - Utility

    @objc
    func updateTokenAttachments() {
        textView?.attributedText.enumerateAttachment() { tokenAttachment, _, _ in
            (tokenAttachment as? TokenTextAttachment)?.refreshImage()
        }
    }

    @objc
    func string(forTokens tokens: [Token]) -> NSAttributedString {
        let string = NSMutableAttributedString()
        for token in tokens {
            let tokenAttachment = TokenTextAttachment(token: token, tokenField: self)
            let tokenString = NSAttributedString(attachment: tokenAttachment)

            string.append(tokenString)

            let separatorAttachment = TokenSeparatorAttachment(token: token, tokenField: self)
            let separatorString = NSAttributedString(attachment: separatorAttachment)

            string.append(separatorString)
        }

        return string && (textAttributes as? [NSAttributedString.Key: Any]) ?? [:]
    }

    /// update currentTokens with textView's current attributedText text after the textView change the text
    func filterUnwantedAttachments() {
        var updatedCurrentTokens: Set<Token> = []
        var updatedCurrentSeparatorTokens: Set<Token> = []

        textView.attributedText.enumerateAttachment() { textAttachment, _, _ in

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

        ///TODO: Change currentTokens type to [Token]
        if let currentTokens = self.currentTokens as? [Token] {
            var deletedTokens = Set<Token>(currentTokens)
            deletedTokens.subtract(updatedCurrentTokens)

            if !deletedTokens.isEmpty {
                removeTokens(Array(deletedTokens))
            }

            self.currentTokens.removeObjects(in: Array(deletedTokens))
            delegate?.tokenField(self, changedTokensTo: currentTokens)
        }
    }

    // MARK: - remove token

    func removeAllTokens() {
        removeTokens(currentTokens as! [Token])
        textView.showOrHidePlaceholder()
    }

    func removeToken(_ token: Token) {
        removeTokens([token])
    }

    private func removeTokens(_ tokensToRemove: [Token]) {
        var rangesToRemove: [NSRange] = []

        textView.attributedText.enumerateAttachment() { textAttachment, range, _ in
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

        currentTokens?.removeObjects(in: tokensToRemove)

        invalidateIntrinsicContentSize()
        updateTextAttributes()

        textView.showOrHidePlaceholder()
    }

    private func rangeIncludesRange(_ range: NSRange, _ includedRange: NSRange) -> Bool {
        return NSEqualRanges(range, NSUnionRange(range, includedRange))
    }

    private func notifyIfFilterTextChanged() {
        var indexOfFilterText = 0
        textView.attributedText.enumerateAttachment() { tokenAttachment, range, _ in
            if tokenAttachment is TokenTextAttachment {
                indexOfFilterText = NSMaxRange(range)
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
    func tokenizedTextView(_ textView: TokenizedTextView, didTapTextRange range: NSRange, fraction: CGFloat) {
        if isCollapsed {
            setCollapsed(false, animated: true)
            return
        }

        if fraction >= 1 && range.location == self.textView.textStorage.length - 1 {
            return
        }

        if range.location < textView.textStorage.length {
            textView.attributedText.enumerateAttachment() { tokenAttachemnt, range, _ in
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
    public func textView(_ textView: UITextView, shouldInteractWith textAttachment: NSTextAttachment, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        return !(textAttachment is TokenSeparatorAttachment)
    }

    public func textViewDidChange(_ textView: UITextView) {
        userDidConfirmInput = false

        filterUnwantedAttachments()
        notifyIfFilterTextChanged()
        invalidateIntrinsicContentSize()
    }

    public func textViewDidChangeSelection(_ textView: UITextView) {
        zmLog.debug("Selection changed: NSStringFromRange(textView.selectedRange)")

        var modifiedSelectionRange = NSRange(location: 0, length: 0)
        var hasModifiedSelection = false

        textView.attributedText.enumerateAttachment() { tokenAttachment, range, _ in
            if let tokenAttachment = tokenAttachment as? TokenTextAttachment {
                tokenAttachment.isSelected = rangeIncludesRange(textView.selectedRange, range)
                textView.layoutManager.invalidateDisplay(forCharacterRange: range)

                if rangeIncludesRange(textView.selectedRange, range) {
                    modifiedSelectionRange = NSUnionRange(hasModifiedSelection ? modifiedSelectionRange : range, range)
                    hasModifiedSelection = true
                }
                zmLog.info("    person attachement: \(tokenAttachment.token.title) at range: \(range) selected: \(tokenAttachment.isSelected)")
            }
        }

        if hasModifiedSelection && !NSEqualRanges(textView.selectedRange, modifiedSelectionRange) {
            textView.selectedRange = modifiedSelectionRange
        }
    }

    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if (text == "\n") {
            textView.resignFirstResponder()
            userDidConfirmInput = true
            delegate?.tokenFieldDidConfirmSelection(self)

            return false
        }

        if range.length == 1 && text.isEmpty {
            // backspace
            var cancelBackspace = false
            textView.attributedText.enumerateAttachment() { tokenAttachment, range, stop in
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
        if !text.isEmpty {
            (textView.text as NSString).enumerateSubstrings(in: NSRange(location: range.location, length: textView.text.count - range.location), options: .byComposedCharacterSequences, using: { substring, substringRange, enclosingRange, stop in

                if substring?.isEmpty == false,
                    let nsString: NSString = substring as NSString?,
                    nsString.character(at: 0) == NSTextAttachment.character {
                    textView.selectedRange = NSRange(location: textView.text.count, length: 0)
                    stop.pointee = true
                }
            })
        }

        updateTextAttributes()

        return true

    }

}

extension NSAttributedString {
    func enumerateAttachment(block: (Any?, NSRange, UnsafeMutablePointer<ObjCBool>) -> Void) {
        enumerateAttribute(.attachment, in: NSRange(location: 0, length: length), options: [], using: block)
    }
}
