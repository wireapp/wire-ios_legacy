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



public enum InputBarState: Equatable {
    case Writing
    case Editing(originalText: String)
}

public func ==(lhs: InputBarState, rhs: InputBarState) -> Bool {
    switch (lhs, rhs) {
    case (.Writing, .Writing): return true
    case (.Editing(let lhsText), .Editing(let rhsText)): return lhsText == rhsText
    default: return false
    }
}

private struct InputBarConstants {
    let buttonsBarHeight: CGFloat = 56
    let contentLeftMargin = CGFloat(WAZUIMagic.floatForIdentifier("content.left_margin"))
    let contentRightMargin = CGFloat(WAZUIMagic.floatForIdentifier("content.right_margin"))
}

@objc public class InputBar: UIView {
    
    public let textView: TextView = ResizingTextView()
    public let leftAccessoryView  = UIView()
    public let rightAccessoryView = UIView()
    public let buttonContainer = UIView()
    public let editingView = InputBarEditView()
    public let buttonsView: InputBarButtonsView
    
    public var editingBackgroundColor: UIColor?
    public var barBackgroundColor: UIColor?

    private var contentSizeObserver: NSObject? = nil
    private var rowTopInsetConstraint: NSLayoutConstraint? = nil
    
    private let buttonInnerContainer = UIView()
    private let fakeCursor = UIView()
    private let inputBarSeparator = UIView()
    private let buttonRowSeparator = UIView()
    private let constants = InputBarConstants()
    private let notificationCenter = NSNotificationCenter.defaultCenter()
    
    var isEditing: Bool {
        if case .Editing(_) = inputBarState { return true }
        return false
    }
    
    var inputBarState: InputBarState = .Writing {
        didSet {
            updateInputBar(withState: inputBarState)
        }
    }
    
    private var textIsOverflowing = false {
        didSet {
            updateTopSeparator() 
        }
    }
    
    public var separatorEnabled = false {
        didSet {
            updateTopSeparator()
        }
    }
    
    public var invisibleInputAccessoryView : InvisibleInputAccessoryView? = nil  {
        didSet {
            textView.inputAccessoryView = invisibleInputAccessoryView
        }
    }
    
    override public var bounds: CGRect {
        didSet {
            invisibleInputAccessoryView?.setIntrinsicContentSize(CGSizeMake(UIViewNoIntrinsicMetric, bounds.height))
        }
    }
        
    override public func didMoveToWindow() {
        super.didMoveToWindow()
        startCursorBlinkAnimation()
    }
    
    deinit {
        notificationCenter.removeObserver(self)
        contentSizeObserver = nil
    }

    required public init(buttons: [UIButton]) {
        buttonsView = InputBarButtonsView(buttons: buttons)
        super.init(frame: CGRectZero)
                
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapBackground))
        addGestureRecognizer(tapGestureRecognizer)
        buttonsView.clipsToBounds = true
        buttonContainer.clipsToBounds = true
        
        [leftAccessoryView, textView, rightAccessoryView, inputBarSeparator, buttonContainer, buttonRowSeparator].forEach(addSubview)
        buttonContainer.addSubview(buttonInnerContainer)
        [buttonsView, editingView].forEach(buttonInnerContainer.addSubview)
        textView.addSubview(fakeCursor)
        CASStyler.defaultStyler().styleItem(self)

        setupViews()
        createConstraints()
        updateTopSeparator()

        notificationCenter.addObserver(self, selector: #selector(textViewTextDidChange), name: UITextViewTextDidChangeNotification, object: textView)
        notificationCenter.addObserver(self, selector: #selector(textViewDidBeginEditing), name: UITextViewTextDidBeginEditingNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(textViewDidEndEditing), name: UITextViewTextDidEndEditingNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(applicationDidBecomeActive), name: UIApplicationDidBecomeActiveNotification, object: nil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        fakeCursor.backgroundColor = UIColor.accentColor()
        
        buttonRowSeparator.cas_styleClass = "separator"
        inputBarSeparator.cas_styleClass = "separator"
        
        textView.accessibilityIdentifier = "inputField"
        textView.placeholder = "conversation.input_bar.placeholder".localized
        textView.lineFragmentPadding = 0
        textView.textContainerInset = UIEdgeInsetsMake(17, 0, 17, constants.contentRightMargin)
        textView.placeholderTextContainerInset = UIEdgeInsetsMake(21, 10, 21, 0)
        textView.keyboardType = .Default;
        textView.returnKeyType = .Send;
        textView.keyboardAppearance = ColorScheme.defaultColorScheme().keyboardAppearance;
        textView.placeholderTextTransform = .Upper
        
        contentSizeObserver = KeyValueObserver.observeObject(textView, keyPath: "contentSize", target: self, selector: #selector(textViewContentSizeDidChange))
        updateBackgroundColor()
    }
    
    private func createConstraints() {
        
        constrain(buttonContainer, textView, buttonRowSeparator, leftAccessoryView, rightAccessoryView) { buttonRow, textView, buttonRowSeparator, leftAccessoryView, rightAccessoryView in
            leftAccessoryView.leading == leftAccessoryView.superview!.leading
            leftAccessoryView.top == leftAccessoryView.superview!.top
            leftAccessoryView.bottom == buttonRow.top
            leftAccessoryView.width == constants.contentLeftMargin
            
            rightAccessoryView.trailing == rightAccessoryView.superview!.trailing - 16
            rightAccessoryView.top == rightAccessoryView.superview!.top
            rightAccessoryView.bottom == buttonRow.top
            
            buttonRow.top == textView.bottom
            textView.top == textView.superview!.top
            textView.leading == leftAccessoryView.trailing
            textView.trailing == textView.superview!.trailing
            textView.height >= 56
            textView.height <= 120 ~ 750

            buttonRowSeparator.top == buttonRow.top
            buttonRowSeparator.left == buttonRowSeparator.superview!.left + 16
            buttonRowSeparator.right == buttonRowSeparator.superview!.right - 16
            buttonRowSeparator.height == 0.5
        }
        
        constrain(editingView, buttonsView, buttonInnerContainer) { editRow, buttonRow, container in
            editRow.top == container.top
            editRow.leading == container.leading
            editRow.trailing == container.trailing
            editRow.bottom == buttonRow.top
            editRow.height == constants.buttonsBarHeight
            
            buttonRow.leading == container.leading
            buttonRow.trailing == container.trailing
            buttonRow.bottom == container.bottom
        }
        
        constrain(buttonContainer, buttonInnerContainer)  { buttonBox, container in
            buttonBox.bottom == buttonBox.superview!.bottom
            buttonBox.left == buttonBox.superview!.left
            buttonBox.right <= buttonBox.superview!.right
            buttonBox.height == constants.buttonsBarHeight
            buttonBox.width == 414 ~ 750

            container.leading == buttonBox.leading
            container.trailing == buttonBox.trailing
            self.rowTopInsetConstraint = container.top == buttonBox.top - constants.buttonsBarHeight
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
    
    @objc private func didTapBackground(gestureRecognizer: UITapGestureRecognizer!) {
        guard gestureRecognizer.state == .Recognized else { return }
        buttonsView.showRow(0, animated: true)
    }
    
    private func startCursorBlinkAnimation() {
        if fakeCursor.layer.animationForKey("blinkAnimation") == nil {
            let animation = CAKeyframeAnimation(keyPath: "opacity")
            animation.values = [1, 1, 0, 0]
            animation.keyTimes = [0, 0.4, 0.7, 0.9]
            animation.duration = 0.64
            animation.autoreverses = true
            animation.repeatCount = FLT_MAX
            fakeCursor.layer.addAnimation(animation, forKey: "blinkAnimation")
        }
    }
    
    private func updateTopSeparator() {
        inputBarSeparator.hidden = !textIsOverflowing && !separatorEnabled
    }
    
    func updateFakeCursorVisibility(firstResponder: UIResponder? = nil) {
        fakeCursor.hidden = textView.isFirstResponder() || textView.text.characters.count != 0 || firstResponder != nil
    }
    
    func textViewContentSizeDidChange(notification: NSNotification) {
        textIsOverflowing = textView.contentSize.height > textView.bounds.size.height
    }

    // MARK: - Disable interactions on the lower part to not to interfere with the keyboard
    
    override public func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
        if self.textView.isFirstResponder() {
            if super.pointInside(point, withEvent: event) {
                let locationInButtonRow = buttonInnerContainer.convertPoint(point, fromView: self)
                return locationInButtonRow.y < buttonInnerContainer.bounds.height / 1.3
            }
            else {
                return false
            }
        }
        else {
            return super.pointInside(point, withEvent: event)
        }
    }

    // MARK: - InputBarState

    func updateInputBar(withState state: InputBarState, animated: Bool = true) {
        updateEditViewState()
        rowTopInsetConstraint?.constant = state == .Writing ? -constants.buttonsBarHeight : 0

        let textViewChanges = {
            switch state {
            case .Writing:
                self.textView.text = nil
            case .Editing(let text):
                self.textView.text = text
                self.textView.setContentOffset(.zero, animated: false)
            }
        }
        
        let completion: Bool -> Void = { _ in
            if case .Editing(_) = state {
                self.textView.becomeFirstResponder()
            }
        }
        
        if animated {
            UIView.wr_animateWithEasing(RBBEasingFunctionEaseInOutExpo, duration: 0.3, animations: layoutIfNeeded)
            UIView.transitionWithView(self.textView, duration: 0.1, options: [], animations: textViewChanges) { _ in
                UIView.animateWithDuration(0.2, delay: 0.1, options:  .CurveEaseInOut, animations: self.updateBackgroundColor, completion: completion)
            }
        } else {
            layoutIfNeeded()
            textViewChanges()
            updateBackgroundColor()
            completion(true)
        }
    }

    private func backgroundColor(forInputBarState state: InputBarState) -> UIColor? {
        guard let writingColor = barBackgroundColor, editingColor = editingBackgroundColor else { return nil }
        let mixed = writingColor.mix(editingColor, amount: 0.16)
        return state == .Writing ? writingColor : mixed
    }

    private func updateBackgroundColor() {
        backgroundColor = backgroundColor(forInputBarState: inputBarState)
    }

    // MARK: – Editing View State

    public func undo() {
        guard inputBarState != .Writing else { return }
        guard let undoManager = textView.undoManager where undoManager.canUndo else { return }
        undoManager.undo()
        updateEditViewState()
    }

    private func updateEditViewState() {
        if case .Editing(let text) = inputBarState {
            let canUndo = textView.undoManager?.canUndo ?? false
            editingView.undoButton.enabled = canUndo

            // We do not want to enable the confirm button when
            // the text is the same as the original message
            let hasChanges = text != textView.text && canUndo
            editingView.confirmButton.enabled = hasChanges
        }
    }
}

extension InputBar {

    func textViewTextDidChange(notification: NSNotification) {
        updateFakeCursorVisibility()
        updateEditViewState()
    }
    
    func textViewDidBeginEditing(notification: NSNotification) {
        updateFakeCursorVisibility(notification.object as? UIResponder)
        updateEditViewState()
    }
    
    func textViewDidEndEditing(notification: NSNotification) {
        updateFakeCursorVisibility()
        updateEditViewState()
    }

}

extension InputBar {
    func applicationDidBecomeActive(notification: NSNotification) {
        startCursorBlinkAnimation()
    }
}
