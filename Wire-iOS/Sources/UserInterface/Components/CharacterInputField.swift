//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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
import Cartography

protocol CharacterInputFieldDelegate: class {
    func shouldAcceptChanges(_ inputField: CharacterInputField) -> Bool
    func didChangeText(_ inputField: CharacterInputField, to: String)
    func didFillInput(inputField: CharacterInputField, text: String)
}


protocol TextContainer: class {
    var text: String? { get set }
}

/// Custom input field implementation. Allows entering the characters from @c characterSet up to @c maxLength characters
/// Allows pasting the text.
final class CharacterInputField: UIControl, UITextInputTraits, TextContainer {
    fileprivate var storage = String() {
        didSet {
            if storage.count > maxLength {
                storage = String(storage.prefix(maxLength))
            }

            self.updateCharacterViews(isFirstResponder: self.isFirstResponder)
            self.accessibilityValue = storage
        }
    }

    let maxLength: Int
    let characterSet: CharacterSet
    weak var delegate: CharacterInputFieldDelegate? = .none
    private let characterViews: [CharacterView]
    private let stackView = UIStackView()

    fileprivate func prepare(string: String) -> String {
        var result = string.filter { element -> Bool in
            guard element.unicodeScalars.count == 1, let firstScalar = element.unicodeScalars.first else {
                return false
            }
            return characterSet.contains(firstScalar)
        }

        if result.count > maxLength {
            result = String(result.prefix(maxLength))
        }

        return result
    }

    private func updateCharacterViews(isFirstResponder: Bool) {
        for index in 0...(maxLength - 1) {
            let characterView = characterViews[index]

            if let character = storage.count > index ? storage[storage.index(storage.startIndex, offsetBy: index)] : nil {
                characterView.character = character
            }
            else {
                characterView.character = .none
            }
        }
    }

    fileprivate func notifyingDelegate(_ action: ()->()) {
        let wasFilled = self.isFilled
        let previousText = self.storage

        action()

        if previousText != storage {
            self.delegate?.didChangeText(self, to: storage)
        }

        if let text = self.text, !wasFilled && self.isFilled {
            self.delegate?.didFillInput(inputField: self, text: text)
        }
    }

    fileprivate func showMenu() {
        let menuController = UIMenuController.shared
        menuController.setTargetRect(bounds, in: self)
        menuController.setMenuVisible(true, animated: true)
    }

    final class CharacterView: UIView {
        private let label = UILabel()
        let parentSize: CGSize

        var character: Character? = .none {
            didSet {
                if let character = self.character {
                    label.text = String(character)
                    label.isHidden = false
                }
                else {
                    label.isHidden = true
                }
            }
        }

        init(parentSize: CGSize) {
            self.parentSize = parentSize

            super.init(frame: .zero)

            self.layer.cornerRadius = 4
            self.backgroundColor = .white

            label.font = UIFont.systemFont(ofSize: 32)
            self.addSubview(label)

            constrain(self, label) { selfView, label in
                label.center == selfView.center
            }
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override var intrinsicContentSize: CGSize {
            return CGSize(width: parentSize.width > CGFloat.iPhone4Inch.width ? 50 : 44, height: parentSize.height)
        }
    }

    // MARK: - Overrides

    /// init method with custom settings
    ///
    /// - Parameters:
    ///   - maxLength: number of textfield will be created
    ///   - characterSet: characterSet accepted
    ///   - size: size of the view to be created (we take the width to calculate the size of each textField, the height for each textField's height)
    init(maxLength: Int, characterSet: CharacterSet, size: CGSize) {
        self.maxLength = maxLength
        self.characterSet = characterSet
        characterViews = (0..<maxLength).map { _ in CharacterView(parentSize: size) }

        super.init(frame: .zero)

        self.isAccessibilityElement = true
        self.shouldGroupAccessibilityChildren = true

        accessibilityHint = "verification.code_hint".localized

        accessibilityCustomActions = [
            UIAccessibilityCustomAction(name: "general.paste".localized, target: self, selector: #selector(UIResponderStandardEditActions.paste))
        ]

        stackView.spacing = 8
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually

        characterViews.forEach(self.stackView.addArrangedSubview)

        self.addSubview(stackView)

        constrain(self, stackView) { selfView, stackView in
            stackView.edges == selfView.edges
        }

        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(onLongPress(_:)))
        self.addGestureRecognizer(longPressGestureRecognizer)

        self.storage = String()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var canBecomeFirstResponder: Bool {
        return true
    }

    override var canBecomeFocused: Bool {
        return true
    }

    @discardableResult override func becomeFirstResponder() -> Bool {
        let result = super.becomeFirstResponder()
        updateCharacterViews(isFirstResponder: true)
        return result
    }

    @discardableResult override func resignFirstResponder() -> Bool {
        let result = super.resignFirstResponder()
        updateCharacterViews(isFirstResponder: false)
        return result
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        self.becomeFirstResponder()
    }

    override func accessibilityActivate() -> Bool {
        return self.becomeFirstResponder()
    }

    // MARK: - Paste support

    @objc fileprivate func onLongPress(_ sender: Any?) {
        self.showMenu()
    }

    override func paste(_ sender: Any?) {
        guard UIPasteboard.general.hasStrings, let valueToPaste = UIPasteboard.general.string else {
            return
        }

        notifyingDelegate {
            self.text = valueToPaste
        }
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        switch action {
        case #selector(paste(_:)):
            return UIPasteboard.general.string != nil
        default:
            return false
        }
    }

    // MARK: - Public API

    var isFilled: Bool {
        return storage.count >= maxLength
    }

    var text: String? {
        set {
            storage = prepare(string: newValue ?? "")
        }
        get {
            return storage
        }
    }

    // MARK: - UITextInputTraits
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType! = nil
}

extension CharacterInputField: UIKeyInput {
    func insertText(_ text: String) {
        let shouldInsert = delegate?.shouldAcceptChanges(self) ?? true
        guard shouldInsert else { return }

        if let _ = text.rangeOfCharacter(from: CharacterSet.newlines) {
            self.resignFirstResponder()
            return
        }

        let allowedChars = prepare(string: text)
        guard !allowedChars.isEmpty else {
            return
        }

        notifyingDelegate {
            self.storage.append(String(allowedChars))
        }
    }

    func deleteBackward() {
        guard !self.storage.isEmpty else {
            return
        }

        let shouldDelete = delegate?.shouldAcceptChanges(self) ?? true
        guard shouldDelete else { return }

        notifyingDelegate {
            self.storage.removeLast()
        }
    }

    var hasText: Bool {
        return !storage.isEmpty
    }
}

