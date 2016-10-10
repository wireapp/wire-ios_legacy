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
import Classy
import WireExtensionComponents


extension Settings {
    var returnKeyType: UIReturnKeyType {
        return disableSendButton ? .send : .default
    }
}

public enum InputBarState: Equatable {
    case writing(ephemeral: Bool)
    case editing(originalText: String)

    var isWriting: Bool {
        switch self {
        case .writing(ephemeral: _): return true
        default: return false
        }
    }

    var isEditing: Bool {
        switch self {
        case .editing(originalText: _): return true
        default: return false
        }
    }
}

public func ==(lhs: InputBarState, rhs: InputBarState) -> Bool {
    switch (lhs, rhs) {
    case (.writing, .writing): return true
    case (.editing(let lhsText), .editing(let rhsText)): return lhsText == rhsText
    default: return false
    }
}

private struct InputBarConstants {
    let buttonsBarHeight: CGFloat = 56
    let contentLeftMargin = WAZUIMagic.cgFloat(forIdentifier: "content.left_margin")
    let contentRightMargin = WAZUIMagic.cgFloat(forIdentifier: "content.right_margin")
}

@objc public final class InputBar: UIView {
    
    public let textView: NextResponderTextView = NextResponderTextView()
    public let leftAccessoryView  = UIView()
    public let rightAccessoryView = UIView()
    
    // Contains and clips the buttonInnerContainer
    public let buttonContainer = UIView()
    
    public let editingView = InputBarEditView()
    public let buttonsView: InputBarButtonsView
    
    public var editingBackgroundColor: UIColor?
    public var barBackgroundColor: UIColor?
    public var writingSeparatorColor: UIColor?
    public var ephemeralColor: UIColor?
    public var placeholderColor: UIColor?

    fileprivate var contentSizeObserver: NSObject? = nil
    fileprivate var rowTopInsetConstraint: NSLayoutConstraint? = nil
    
    // Contains the editingView and buttonsView
    fileprivate let buttonInnerContainer = UIView()
    fileprivate let fakeCursor = UIView()
    fileprivate let inputBarSeparator = UIView()
    fileprivate let buttonRowSeparator = UIView()
    fileprivate let constants = InputBarConstants()
    fileprivate let notificationCenter = NotificationCenter.default
    
    var isEditing: Bool {
        return inputBarState.isEditing
    }
    
    var inputBarState: InputBarState = .writing(ephemeral: false) {
        didSet {
            updateInputBar(withState: inputBarState)
        }
    }
    
    fileprivate var textIsOverflowing = false {
        didSet {
            updateTopSeparator() 
        }
    }
    
    open var separatorEnabled = false {
        didSet {
            updateTopSeparator()
        }
    }
    
    open var invisibleInputAccessoryView : InvisibleInputAccessoryView? = nil  {
        didSet {
            textView.inputAccessoryView = invisibleInputAccessoryView
        }
    }
    
    override open var bounds: CGRect {
        didSet {
            invisibleInputAccessoryView?.intrinsicContentSize = CGSize(width: UIViewNoIntrinsicMetric, height: bounds.height)
        }
    }
        
    override open func didMoveToWindow() {
        super.didMoveToWindow()
        startCursorBlinkAnimation()
    }
    
    deinit {
        notificationCenter.removeObserver(self)
        contentSizeObserver = nil
    }

    required public init(buttons: [UIButton]) {
        buttonsView = InputBarButtonsView(buttons: buttons)
        super.init(frame: CGRect.zero)
                
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapBackground))
        addGestureRecognizer(tapGestureRecognizer)
        buttonsView.clipsToBounds = true
        buttonContainer.clipsToBounds = true
        
        [leftAccessoryView, textView, rightAccessoryView, inputBarSeparator, buttonContainer, buttonRowSeparator].forEach(addSubview)
        buttonContainer.addSubview(buttonInnerContainer)
        [buttonsView, editingView].forEach(buttonInnerContainer.addSubview)
        textView.addSubview(fakeCursor)
        CASStyler.default().styleItem(self)

        setupViews()
        createConstraints()
        updateTopSeparator()

        notificationCenter.addObserver(self, selector: #selector(textViewTextDidChange), name: NSNotification.Name.UITextViewTextDidChange, object: textView)
        notificationCenter.addObserver(self, selector: #selector(textViewDidBeginEditing), name: NSNotification.Name.UITextViewTextDidBeginEditing, object: nil)
        notificationCenter.addObserver(self, selector: #selector(textViewDidEndEditing), name: NSNotification.Name.UITextViewTextDidEndEditing, object: nil)
        notificationCenter.addObserver(self, selector: #selector(applicationDidBecomeActive), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func setupViews() {
        inputBarSeparator.cas_styleClass = "separator"
        
        textView.accessibilityIdentifier = "inputField"
        updatePlaceholder()
        textView.lineFragmentPadding = 0
        textView.textContainerInset = UIEdgeInsetsMake(17, 0, 17, 4)
        textView.placeholderTextContainerInset = UIEdgeInsetsMake(21, 10, 21, 0)
        textView.keyboardType = .default
        textView.keyboardAppearance = ColorScheme.default().keyboardAppearance
        textView.placeholderTextTransform = .upper
        textView.tintAdjustmentMode = .automatic

        updateReturnKey()

        contentSizeObserver = KeyValueObserver.observe(textView, keyPath: "contentSize", target: self, selector: #selector(textViewContentSizeDidChange))
        updateInputBar(withState: inputBarState, animated: false)
        updateColors()
    }
    
    fileprivate func createConstraints() {
        
        constrain(buttonContainer, textView, buttonRowSeparator, leftAccessoryView, rightAccessoryView) { buttonContainer, textView, buttonRowSeparator, leftAccessoryView, rightAccessoryView in
            leftAccessoryView.leading == leftAccessoryView.superview!.leading
            leftAccessoryView.top == leftAccessoryView.superview!.top
            leftAccessoryView.bottom == buttonContainer.top
            leftAccessoryView.width == constants.contentLeftMargin

            rightAccessoryView.trailing == rightAccessoryView.superview!.trailing - 16
            rightAccessoryView.top == rightAccessoryView.superview!.top
            rightAccessoryView.width == 0 ~ LayoutPriority(750)
            rightAccessoryView.bottom == buttonContainer.top
            
            buttonContainer.top == textView.bottom
            textView.top == textView.superview!.top
            textView.leading == leftAccessoryView.trailing
            textView.right == rightAccessoryView.left
            textView.height >= 56
            textView.height <= 120 ~ LayoutPriority(750)

            buttonRowSeparator.top == buttonContainer.top
            buttonRowSeparator.left == buttonRowSeparator.superview!.left + 16
            buttonRowSeparator.right == buttonRowSeparator.superview!.right - 16
            buttonRowSeparator.height == 0.5
        }
        
        constrain(editingView, buttonsView, buttonInnerContainer) { editingView, buttonsView, buttonInnerContainer in
            editingView.top == buttonInnerContainer.top
            editingView.leading == buttonInnerContainer.leading
            editingView.trailing == buttonInnerContainer.trailing
            editingView.bottom == buttonsView.top
            editingView.height == constants.buttonsBarHeight
            
            buttonsView.leading == buttonInnerContainer.leading
            buttonsView.trailing <= buttonInnerContainer.trailing
            buttonsView.bottom == buttonInnerContainer.bottom
            buttonsView.width == 414 ~ LayoutPriority(750)
        }
        
        constrain(buttonContainer, buttonInnerContainer)  { container, innerContainer in
            container.bottom == container.superview!.bottom
            container.left == container.superview!.left
            container.right == container.superview!.right
            container.height == constants.buttonsBarHeight

            innerContainer.leading == container.leading
            innerContainer.trailing == container.trailing
            self.rowTopInsetConstraint = innerContainer.top == container.top - constants.buttonsBarHeight
        }
        
        constrain(inputBarSeparator) { inputBarSeparator in
            inputBarSeparator.top == inputBarSeparator.superview!.top
            inputBarSeparator.leading == inputBarSeparator.superview!.leading
            inputBarSeparator.trailing == inputBarSeparator.superview!.trailing
            inputBarSeparator.height == 0.5
        }
        
        constrain(fakeCursor) { fakeCursor in
            fakeCursor.width == 2
            fakeCursor.height == 23
            fakeCursor.centerY == fakeCursor.superview!.centerY
            fakeCursor.leading == fakeCursor.superview!.leading
        }
    }
    
    @objc fileprivate func didTapBackground(_ gestureRecognizer: UITapGestureRecognizer!) {
        guard gestureRecognizer.state == .recognized else { return }
        buttonsView.showRow(0, animated: true)
    }
    
    fileprivate func startCursorBlinkAnimation() {
        if fakeCursor.layer.animation(forKey: "blinkAnimation") == nil {
            let animation = CAKeyframeAnimation(keyPath: "opacity")
            animation.values = [1, 1, 0, 0]
            animation.keyTimes = [0, 0.4, 0.7, 0.9]
            animation.duration = 0.64
            animation.autoreverses = true
            animation.repeatCount = FLT_MAX
            fakeCursor.layer.add(animation, forKey: "blinkAnimation")
        }
    }

    public func updateReturnKey() {
        textView.returnKeyType = Settings.shared().returnKeyType
    }

    func updatePlaceholder() {
        textView.placeholder = placeholderText(for: inputBarState)
        textView.setNeedsLayout()
        textView.layoutIfNeeded()
    }

    func placeholderText(for state: InputBarState) -> String? {
        switch inputBarState {
        case .writing(ephemeral: let ephemeral):
            if ephemeral {
                return "conversation.input_bar.placeholder_ephemeral".localized
            }
            return "conversation.input_bar.placeholder".localized
        case .editing: return nil
        }
    }
    
    fileprivate func updateTopSeparator() {
        inputBarSeparator.isHidden = !textIsOverflowing && !separatorEnabled
    }
    
    func updateFakeCursorVisibility(_ firstResponder: UIResponder? = nil) {
        fakeCursor.isHidden = textView.isFirstResponder || textView.text.characters.count != 0 || firstResponder != nil
    }
    
    func textViewContentSizeDidChange(_ sender: AnyObject) {
        textIsOverflowing = textView.contentSize.height > textView.bounds.size.height
    }

    // MARK: - Disable interactions on the lower part to not to interfere with the keyboard
    
    override open func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
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

    func updateInputBar(withState state: InputBarState, animated: Bool = true) {
        updateEditViewState()
        updatePlaceholder()
        rowTopInsetConstraint?.constant = state.isWriting ? -constants.buttonsBarHeight : 0

        let textViewChanges = {
            switch state {
            case .writing:
                self.textView.text = nil

            case .editing(let text):
                self.setInputBarText(text)
            }
        }
        
        let completion: (Bool) -> Void = { _ in
            if case .editing(_) = state {
                self.textView.becomeFirstResponder()
                self.updateColors()
            }
        }
        
        if animated {
            UIView.wr_animate(easing: RBBEasingFunctionEaseInOutExpo, duration: 0.3, animations: layoutIfNeeded)
            UIView.transition(with: self.textView, duration: 0.1, options: [], animations: textViewChanges) { _ in
                UIView.animate(withDuration: 0.2, delay: 0.1, options:  .curveEaseInOut, animations: self.updateColors, completion: completion)
            }
        } else {
            layoutIfNeeded()
            textViewChanges()
            updateColors()
            completion(true)
        }
    }

    fileprivate func backgroundColor(forInputBarState state: InputBarState) -> UIColor? {
        guard let writingColor = barBackgroundColor, let editingColor = editingBackgroundColor else { return nil }
        return state.isWriting ? writingColor : writingColor.mix(editingColor, amount: 0.16)
    }

    fileprivate func updateColors() {
        backgroundColor = backgroundColor(forInputBarState: inputBarState)

        if case .writing(let ephemeral) = inputBarState {
            buttonRowSeparator.backgroundColor = ephemeral ? ephemeralColor : writingSeparatorColor
            textView.placeholderTextColor = ephemeral ? ephemeralColor : placeholderColor
            fakeCursor.backgroundColor = ephemeral ? ephemeralColor : .accent()
            textView.tintColor = ephemeral ? ephemeralColor : .accent()
        }
    }

    // MARK: – Editing View State

    open func setInputBarText(_ text: String) {
        textView.text = text
        textView.setContentOffset(.zero, animated: false)
        textView.undoManager?.removeAllActions()
        updateEditViewState()
    }

    open func undo() {
        guard inputBarState.isWriting else { return }
        guard let undoManager = textView.undoManager , undoManager.canUndo else { return }
        undoManager.undo()
        updateEditViewState()
    }

    fileprivate func updateEditViewState() {
        if case .editing(let text) = inputBarState {
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

    func textViewTextDidChange(_ notification: Notification) {
        updateFakeCursorVisibility()
        updateEditViewState()
    }
    
    func textViewDidBeginEditing(_ notification: Notification) {
        updateFakeCursorVisibility(notification.object as? UIResponder)
        updateEditViewState()
    }
    
    func textViewDidEndEditing(_ notification: Notification) {
        updateFakeCursorVisibility()
        updateEditViewState()
    }

}

extension InputBar {
    func applicationDidBecomeActive(_ notification: Notification) {
        startCursorBlinkAnimation()
    }
}
