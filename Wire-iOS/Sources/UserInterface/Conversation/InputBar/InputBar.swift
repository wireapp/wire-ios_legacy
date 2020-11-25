//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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
import Cartography
import Down
import WireDataModel

extension Settings {
    var returnKeyType: UIReturnKeyType {
        let disableSendButton: Bool? = self[.sendButtonDisabled]
        return disableSendButton == true ? .send : .default
    }
}

enum EphemeralState: Equatable {
    case conversation
    case message
    case none

    var isEphemeral: Bool {
        return [.message, .conversation].contains(self)
    }
}

enum InputBarState: Equatable {
    case writing(ephemeral: EphemeralState)
    case editing(originalText: String, mentions: [Mention])
    case markingDown(ephemeral: EphemeralState)

    var isWriting: Bool {
        switch self {
        case .writing: return true
        default: return false
        }
    }

    var isEditing: Bool {
        switch self {
        case .editing: return true
        default: return false
        }
    }
    
    var isMarkingDown: Bool {
        switch self {
        case .markingDown: return true
        default: return false
        }
    }
    
    var isEphemeral: Bool {
        switch self {
        case .markingDown(let ephemeral):
            return ephemeral.isEphemeral
        case .writing(let ephemeral):
            return ephemeral.isEphemeral
        default:
            return false
        }
    }

    var isEphemeralEnabled: Bool {
        switch self {
        case .markingDown(let ephemeral):
            return ephemeral == .message
        case .writing(let ephemeral):
            return ephemeral == .message
        default:
            return false
        }
    }

    mutating func changeEphemeralState(to newState: EphemeralState) {
        switch self {
        case .markingDown(_):
            self = .markingDown(ephemeral: newState)
        case .writing(_):
            self = .writing(ephemeral: newState)
        default:
            return
        }
    }
}

private struct InputBarConstants {
    let buttonsBarHeight: CGFloat = 56
}

final class InputBar: UIView {

    private let inputBarVerticalInset: CGFloat = 34
    static let rightIconSize: CGFloat = 32

    let textView = MarkdownTextView(with: DownStyle.compact)
    let leftAccessoryView  = UIView()
    let rightAccessoryStackView: UIStackView = {
        let stackView = UIStackView()

        let rightInset = (stackView.conversationHorizontalMargins.left - rightIconSize) / 2

        stackView.spacing = 16
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.isLayoutMarginsRelativeArrangement = true

        return stackView
    }()
    
    // Contains and clips the buttonInnerContainer
    let buttonContainer = UIView()
    
    // Contains editingView and mardownView
    let secondaryButtonsView: InputBarSecondaryButtonsView
    
    let buttonsView: InputBarButtonsView
    let editingView = InputBarEditView()
    
    let markdownView = MarkdownBarView()
    
    var editingBackgroundColor = UIColor.brightYellow
    var barBackgroundColor: UIColor? = UIColor.from(scheme: .barBackground)
    var writingSeparatorColor: UIColor? = .from(scheme: .separator)
    var ephemeralColor: UIColor {
        return .accent()
    }
    
    var placeholderColor: UIColor = .from(scheme: .textPlaceholder)
    var textColor: UIColor? = .from(scheme: .textForeground)

    fileprivate var rowTopInsetConstraint: NSLayoutConstraint? = nil
    
    // Contains the secondaryButtonsView and buttonsView
    fileprivate let buttonInnerContainer = UIView()

    fileprivate let buttonRowSeparator = UIView()
    fileprivate let constants = InputBarConstants()
    
    fileprivate var leftAccessoryViewWidthConstraint: NSLayoutConstraint?
    
    var isEditing: Bool {
        return inputBarState.isEditing
    }
    
    var isMarkingDown: Bool {
        return inputBarState.isMarkingDown
    }
    
    private var inputBarState: InputBarState = .writing(ephemeral: .none) {
        didSet {
            updatePlaceholder()
            updatePlaceholderColors()
        }
    }

    func changeEphemeralState(to newState: EphemeralState) {
        inputBarState.changeEphemeralState(to: newState)
    }

    var invisibleInputAccessoryView : InvisibleInputAccessoryView? = nil  {
        didSet {
            textView.inputAccessoryView = invisibleInputAccessoryView
        }
    }
    
    var availabilityPlaceholder : NSAttributedString? {
        didSet {
            updatePlaceholder()
        }
    }
    
    override var bounds: CGRect {
        didSet {
            invisibleInputAccessoryView?.overriddenIntrinsicContentSize = CGSize(width: UIView.noIntrinsicMetric, height: bounds.height)
        }
    }
        
    override func didMoveToWindow() {
        super.didMoveToWindow()

        // This is a workaround for UITextView truncating long contents.
        // However, this breaks the text view on iOS 8 ¯\_(ツ)_/¯.
        textView.isScrollEnabled = false
        textView.isScrollEnabled = true
    }

    required init(buttons: [UIButton]) {
        buttonsView = InputBarButtonsView(buttons: buttons)
        secondaryButtonsView = InputBarSecondaryButtonsView(editBarView: editingView, markdownBarView: markdownView)
        
        super.init(frame: CGRect.zero)
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapBackground))
        addGestureRecognizer(tapGestureRecognizer)
        buttonsView.clipsToBounds = true
        buttonContainer.clipsToBounds = true
        
        [leftAccessoryView, textView, rightAccessoryStackView, buttonContainer, buttonRowSeparator].forEach(addSubview)
        buttonContainer.addSubview(buttonInnerContainer)
        [buttonsView, secondaryButtonsView].forEach(buttonInnerContainer.addSubview)
        

        setupViews()
        updateRightAccessoryStackViewLayoutMargins()
        createConstraints()
        
        let notificationCenter = NotificationCenter.default
        
        notificationCenter.addObserver(markdownView, selector: #selector(markdownView.textViewDidChangeActiveMarkdown), name: Notification.Name.MarkdownTextViewDidChangeActiveMarkdown, object: textView)
        notificationCenter.addObserver(self, selector: #selector(textViewTextDidChange), name: UITextView.textDidChangeNotification, object: textView)
        notificationCenter.addObserver(self, selector: #selector(textViewDidBeginEditing), name: UITextView.textDidBeginEditingNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(textViewDidEndEditing), name: UITextView.textDidEndEditingNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(sendButtonEnablingDidApplyChanges), name: NSNotification.Name.disableSendButtonChanged, object: nil)
    }


    /// Update return key type when receiving a notification (from setting->toggle send key option)
    @objc
    private func sendButtonEnablingDidApplyChanges() {
        updateReturnKey()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func setupViews() {
        textView.accessibilityIdentifier = "inputField"
        
        updatePlaceholder()
        textView.lineFragmentPadding = 0
        textView.textAlignment = .natural
        textView.textContainerInset = UIEdgeInsets(top: inputBarVerticalInset / 2, left: 0, bottom: inputBarVerticalInset / 2, right: 4)
        textView.placeholderTextContainerInset = UIEdgeInsets(top: 21, left: 10, bottom: 21, right: 0)
        textView.keyboardType = .default
        textView.keyboardAppearance = ColorScheme.default.keyboardAppearance
        textView.placeholderTextTransform = .upper
        textView.tintAdjustmentMode = .automatic
        textView.font = .normalLightFont
        textView.placeholderFont = .smallSemiboldFont
        textView.backgroundColor = .clear
        
        markdownView.delegate = textView

        updateReturnKey()

        updateInputBar(withState: inputBarState, animated: false)
        updateColors()
    }
    
    fileprivate func createConstraints() {
        
        constrain(buttonContainer, textView, buttonRowSeparator, leftAccessoryView, rightAccessoryStackView) { buttonContainer, textView, buttonRowSeparator, leftAccessoryView, rightAccessoryView in
            leftAccessoryView.leading == leftAccessoryView.superview!.leading
            leftAccessoryView.top == leftAccessoryView.superview!.top
            leftAccessoryView.bottom == buttonContainer.top
            leftAccessoryViewWidthConstraint = leftAccessoryView.width == conversationHorizontalMargins.left

            rightAccessoryView.trailing == rightAccessoryView.superview!.trailing
            rightAccessoryView.top == rightAccessoryView.superview!.top
            rightAccessoryView.width == 0 ~ 750.0
            rightAccessoryView.bottom == buttonContainer.top
            
            buttonContainer.top == textView.bottom
            textView.top == textView.superview!.top
            textView.leading == leftAccessoryView.trailing
            textView.trailing <= textView.superview!.trailing - 16
            textView.trailing == rightAccessoryView.leading
            textView.height >= 56
            textView.height <= 120 ~ 1000.0

            buttonRowSeparator.top == buttonContainer.top
            buttonRowSeparator.leading == buttonRowSeparator.superview!.leading + 16
            buttonRowSeparator.trailing == buttonRowSeparator.superview!.trailing - 16
            buttonRowSeparator.height == .hairline
        }
        
        constrain(secondaryButtonsView, buttonsView, buttonInnerContainer) { secondaryButtonsView, buttonsView, buttonInnerContainer in
            secondaryButtonsView.top == buttonInnerContainer.top
            secondaryButtonsView.leading == buttonInnerContainer.leading
            secondaryButtonsView.trailing == buttonInnerContainer.trailing
            secondaryButtonsView.bottom == buttonsView.top
            secondaryButtonsView.height == constants.buttonsBarHeight
            
            buttonsView.leading == buttonInnerContainer.leading
            buttonsView.trailing <= buttonInnerContainer.trailing
            buttonsView.bottom == buttonInnerContainer.bottom
        }
        
        constrain(buttonContainer, buttonInnerContainer)  { container, innerContainer in
            container.bottom == container.superview!.bottom
            container.leading == container.superview!.leading
            container.trailing == container.superview!.trailing
            container.height == constants.buttonsBarHeight

            innerContainer.leading == container.leading
            innerContainer.trailing == container.trailing
            self.rowTopInsetConstraint = innerContainer.top == container.top - constants.buttonsBarHeight
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        guard traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass else { return }
        
        updateLeftAccessoryViewWidth()
        updateRightAccessoryStackViewLayoutMargins()
    }
    
    fileprivate func updateLeftAccessoryViewWidth() {
        leftAccessoryViewWidthConstraint?.constant = conversationHorizontalMargins.left
    }
    
    fileprivate func updateRightAccessoryStackViewLayoutMargins() {
        let rightInset = (conversationHorizontalMargins.left - InputBar.rightIconSize) / 2
        rightAccessoryStackView.layoutMargins = UIEdgeInsets(top: 0, left: rightInset, bottom: 0, right: rightInset)
    }
    
    @objc fileprivate func didTapBackground(_ gestureRecognizer: UITapGestureRecognizer!) {
        guard gestureRecognizer.state == .recognized else { return }
        buttonsView.showRow(0, animated: true)
    }
    
    func updateReturnKey() {
        textView.returnKeyType = isMarkingDown ? .default : Settings.shared.returnKeyType
        textView.reloadInputViews()
    }

    func updatePlaceholder() {
        textView.attributedPlaceholder = placeholderText(for: inputBarState)
        textView.setNeedsLayout()
    }

    func placeholderText(for state: InputBarState) -> NSAttributedString? {
        
        var placeholder = NSAttributedString(string: "conversation.input_bar.placeholder".localized)
        
        if let availabilityPlaceholder = availabilityPlaceholder {
            placeholder = availabilityPlaceholder
        } else if inputBarState.isEphemeral {
            placeholder  = NSAttributedString(string: "conversation.input_bar.placeholder_ephemeral".localized) && ephemeralColor
        }
        if state.isEditing {
            return nil
        } else {
            return placeholder
        }
    }
    
    // MARK: - Disable interactions on the lower part to not to interfere with the keyboard
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if self.textView.isFirstResponder {
            if super.point(inside: point, with: event) {
                let locationInButtonRow = buttonInnerContainer.convert(point, from: self)
                return locationInButtonRow.y < buttonInnerContainer.bounds.height / 1.3
            }
            else {
                return false
            }
        }
        else {
            return super.point(inside: point, with: event)
        }
    }

    // MARK: - InputBarState

    func setInputBarState(_ state: InputBarState, animated: Bool) {
        let oldState = inputBarState
        inputBarState = state
        updateInputBar(withState: state, oldState: oldState, animated: animated)
    }

    private func updateInputBar(withState state: InputBarState, oldState: InputBarState? = nil, animated: Bool = true) {
        updateEditViewState()
        updatePlaceholder()
        updateReturnKey()
        rowTopInsetConstraint?.constant = state.isWriting ? -constants.buttonsBarHeight : 0

        let textViewChanges = {
            switch state {
            case .writing:
                if let oldState = oldState, oldState.isEditing {
                    self.textView.text = nil
                }
            case .editing(let text, let mentions):
                self.setInputBarText(text, mentions: mentions)
                self.secondaryButtonsView.setEditBarView()
            
            case .markingDown:
                self.secondaryButtonsView.setMarkdownBarView()
            }
        }
        
        let completion: () -> Void = {
            self.updateColors()
            self.updatePlaceholderColors()

            if state.isEditing {
                self.textView.becomeFirstResponder()
            }
        }

        if animated && self.superview != nil {
            UIView.animate(easing: .easeInOutExpo, duration: 0.3, animations: layoutIfNeeded)
            UIView.transition(with: self.textView, duration: 0.1, options: [], animations: textViewChanges) { _ in
                self.updateColors()
                completion()
            }
        } else {
            layoutIfNeeded()
            textViewChanges()
            completion()
        }
    }

    func updateEphemeralState() {
        guard inputBarState.isWriting else { return }
        updateColors()
        updatePlaceholder()
    }

    fileprivate func backgroundColor(forInputBarState state: InputBarState) -> UIColor? {
        guard let writingColor = barBackgroundColor else { return nil }
        return state.isWriting || state.isMarkingDown ? writingColor : writingColor.mix(editingBackgroundColor, amount: 0.16)
    }

    fileprivate func updatePlaceholderColors() {
        if inputBarState.isEphemeral &&
            inputBarState.isEphemeralEnabled &&
            availabilityPlaceholder == nil {
            textView.placeholderTextColor = ephemeralColor
        } else {
            textView.placeholderTextColor = placeholderColor
        }
    }

    fileprivate func updateColors() {

        backgroundColor = backgroundColor(forInputBarState: inputBarState)
        buttonRowSeparator.backgroundColor = writingSeparatorColor

        updatePlaceholderColors()

        textView.tintColor = .accent()
        textView.updateTextColor(base: textColor)

        var buttons = self.buttonsView.buttons
        
        buttons.append(self.buttonsView.expandRowButton)
        
        buttons.forEach { button in
            guard let button = button as? IconButton else {
                return
            }
            
            button.setIconColor(UIColor.from(scheme: .iconNormal), for: .normal)
            button.setIconColor(UIColor.from(scheme: .iconHighlighted), for: .highlighted)
        }
    }

    // MARK: – Editing View State

    func setInputBarText(_ text: String, mentions: [Mention]) {
        textView.setText(text, withMentions: mentions)
        textView.setContentOffset(.zero, animated: false)
        textView.undoManager?.removeAllActions()
        updateEditViewState()
    }

    func undo() {
        guard inputBarState.isEditing else { return }
        guard let undoManager = textView.undoManager , undoManager.canUndo else { return }
        undoManager.undo()
        updateEditViewState()
    }

    fileprivate func updateEditViewState() {
        if case .editing(let text, _) = inputBarState {
            let canUndo = textView.undoManager?.canUndo ?? false
            editingView.undoButton.isEnabled = canUndo

            // We do not want to enable the confirm button when
            // the text is the same as the original message
            let trimmedText = textView.text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            let hasChanges = text != trimmedText && canUndo
            editingView.confirmButton.isEnabled = hasChanges
        }
    }
}

extension InputBar {

    @objc func textViewTextDidChange(_ notification: Notification) {
        updateEditViewState()
    }
    
    @objc func textViewDidBeginEditing(_ notification: Notification) {
        updateEditViewState()
    }
    
    @objc func textViewDidEndEditing(_ notification: Notification) {
        updateEditViewState()
    }

}
