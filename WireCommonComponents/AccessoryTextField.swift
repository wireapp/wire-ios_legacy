//
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
import UIKit

open class AccessoryTextField: UITextField, DynamicTypeCapable {

    public func redrawFont() {
        self.font = textFieldAttributes.textFont.font
    }

    public struct Attributes {

        var textFont: FontSpec
        let textColor: UIColor
        let placeholderFont: FontSpec
        let placeholderColor: UIColor
        let backgroundColor: UIColor
        let cornerRadius: CGFloat

        public init(
            textFont: FontSpec,
            textColor: UIColor,
            placeholderFont: FontSpec,
            placeholderColor: UIColor,
            backgroundColor: UIColor,
            cornerRadius: CGFloat = 0) {
                self.textFont = textFont
                self.textColor = textColor
                self.placeholderFont = placeholderFont
                self.placeholderColor = placeholderColor
                self.backgroundColor = backgroundColor
                self.cornerRadius = cornerRadius
        }
    }
    // MARK: - Constants
    private let horizonalInset: CGFloat = 16
    // MARK: - Properties
    public var input: String {
        return text ?? ""
    }
    public override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: 56)
    }
    public let accessoryStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 16
        stack.alignment = .center
        stack.distribution = .fill
        return stack
    }()
    let accessoryContainer = UIView()
    public var textInsets: UIEdgeInsets
    let placeholderInsets: UIEdgeInsets
    let accessoryTrailingInset: CGFloat
    let textFieldAttributes: Attributes
    // MARK: - Life cycle
    /// - Parameters:
    ///   - leftInset: placeholder left inset
    ///   - accessoryTrailingInset: accessory stack right inset
    ///   - textFieldAttributes: text field attributes
    public init(
        leftInset: CGFloat = 8,
        accessoryTrailingInset: CGFloat = 16,
        textFieldAttributes: Attributes) {
            let topInset: CGFloat = 0
            self.placeholderInsets = UIEdgeInsets(top: topInset, left: leftInset, bottom: 0, right: horizonalInset)
            self.textInsets = UIEdgeInsets(top: 0, left: horizonalInset, bottom: 0, right: horizonalInset)
            self.accessoryTrailingInset = accessoryTrailingInset
            self.textFieldAttributes = textFieldAttributes
            super.init(frame: .zero)
            setupViews()
            setupTextField(with: textFieldAttributes)
        }

    @available(*, unavailable)
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - View creation

extension AccessoryTextField {
    private func setupViews() {
        addTarget(self, action: #selector(textFieldDidChange(textField:)), for: .editingChanged)
        accessoryContainer.addSubview(accessoryStack)
        createConstraints()
    }
    private func createConstraints() {
        accessoryStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            // spacing
            accessoryStack.topAnchor.constraint(equalTo: accessoryContainer.topAnchor),
            accessoryStack.bottomAnchor.constraint(equalTo: accessoryContainer.bottomAnchor),
            accessoryStack.leadingAnchor.constraint(equalTo: accessoryContainer.leadingAnchor, constant: 0),
            accessoryStack.trailingAnchor.constraint(equalTo: accessoryContainer.trailingAnchor, constant: -accessoryTrailingInset)])
    }
    @objc
    open func textFieldDidChange(textField: UITextField) {
        // to be overriden
    }
    private func setupTextField(with textFieldAttributes: Attributes) {
        rightView = accessoryContainer
        rightViewMode = .always

        font = textFieldAttributes.textFont.font
        textColor = textFieldAttributes.textColor
        backgroundColor = textFieldAttributes.backgroundColor

        autocorrectionType = .no
        contentVerticalAlignment = .center

        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            layer.cornerRadius = 4
        default:
            layer.cornerRadius = textFieldAttributes.cornerRadius
        }
        layer.masksToBounds = true
    }
}

// MARK: - Custom edge insets

extension AccessoryTextField {
    public override func textRect(forBounds bounds: CGRect) -> CGRect {
        let textRect = super.textRect(forBounds: bounds)
        return textRect.inset(by: textInsets.directionAwareInsets(view: self))
    }
    public override func editingRect(forBounds bounds: CGRect) -> CGRect {
        let editingRect: CGRect = super.editingRect(forBounds: bounds)
        return editingRect.inset(by: textInsets.directionAwareInsets(view: self))
    }
}

// MARK: - Placeholder

extension AccessoryTextField {
    func attributedPlaceholderString(placeholder: String) -> NSAttributedString {
        let attribute: [NSAttributedString.Key: Any] = [.foregroundColor: textFieldAttributes.placeholderColor,
                                                        .font: textFieldAttributes.placeholderFont.font!]
        return placeholder && attribute
    }
    public override var placeholder: String? {
        get {
            return super.placeholder
        }
        set {
            if let newValue = newValue {
                attributedPlaceholder = attributedPlaceholderString(placeholder: newValue)
            }
        }
    }
    public override func drawPlaceholder(in rect: CGRect) {
        super.drawPlaceholder(in: rect.inset(by: placeholderInsets.directionAwareInsets(view: self)))
    }
}

// MARK: - Right and left accessory

extension AccessoryTextField {
    func rightAccessoryViewRect(forBounds bounds: CGRect, isLeftToRight: Bool) -> CGRect {
        let contentSize = accessoryContainer.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        var rightViewRect: CGRect
        let newY = bounds.origin.y + (bounds.size.height -  contentSize.height) / 2
        if isLeftToRight {
            rightViewRect = CGRect(x: CGFloat(bounds.maxX - contentSize.width), y: newY, width: contentSize.width, height: contentSize.height)
        } else {
            rightViewRect = CGRect(x: bounds.origin.x, y: newY, width: contentSize.width, height: contentSize.height)
        }

        return rightViewRect
    }
    public override func rightViewRect(forBounds bounds: CGRect) -> CGRect {
        return isLeftToRight
            ? rightAccessoryViewRect(forBounds: bounds, isLeftToRight: isLeftToRight)
            : .zero
    }
    public override func leftViewRect(forBounds bounds: CGRect) -> CGRect {
        return isLeftToRight
            ? .zero
            : rightAccessoryViewRect(forBounds: bounds, isLeftToRight: isLeftToRight)
    }
}
