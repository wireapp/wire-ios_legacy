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
import UIKit
import WireDataModel
import WireCommonComponents

class FloatingLabel: UITextField {
    var floatingLabel: UILabel = UILabel(frame: CGRect.zero) // Label
    var floatingLabelHeight: CGFloat = 14 // Default height
   // @IBInspectable
    var _placeholder: String? // we cannot override 'placeholder'
   // @IBInspectable
    var floatingLabelColor: UIColor = UIColor.black {
        didSet {
            self.floatingLabel.textColor = floatingLabelColor
            self.setNeedsDisplay()
        }
    }
   // @IBInspectable
    var activeBorderColor: UIColor = UIColor.blue
    //@IBInspectable
    var floatingLabelFont: UIFont = UIFont.systemFont(ofSize: 14) {
        didSet {
            self.floatingLabel.font = self.floatingLabelFont
            self.font = self.floatingLabelFont
            self.setNeedsDisplay()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .red

        self._placeholder = "Test placeholder"//(self._placeholder != nil) ? self._placeholder : placeholder // Use our custom placeholder if none is set
        placeholder = self._placeholder // make sure the placeholder is shown
        self.floatingLabel = UILabel(frame: CGRect.zero)
        self.addTarget(self, action: #selector(self.addFloatingLabel), for: .editingDidBegin)
        self.addTarget(self, action: #selector(self.removeFloatingLabel), for: .editingDidEnd)

    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
//        self._placeholder = "Test placeholder"//(self._placeholder != nil) ? self._placeholder : placeholder // Use our custom placeholder if none is set
//        placeholder = self._placeholder // make sure the placeholder is shown
//        self.floatingLabel = UILabel(frame: CGRect.zero)
//        self.addTarget(self, action: #selector(self.addFloatingLabel), for: .editingDidBegin)
//        self.addTarget(self, action: #selector(self.removeFloatingLabel), for: .editingDidEnd)
    }

    @objc func addFloatingLabel() {
        if self.text == "" {
            self.floatingLabel.textColor = floatingLabelColor
            self.floatingLabel.font = floatingLabelFont
            self.floatingLabel.text = self._placeholder
            self.floatingLabel.layer.backgroundColor = UIColor.white.cgColor
            self.floatingLabel.translatesAutoresizingMaskIntoConstraints = false
            self.floatingLabel.clipsToBounds = true
            self.floatingLabel.frame = CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.floatingLabelHeight)
            self.layer.borderColor = self.activeBorderColor.cgColor
            self.addSubview(self.floatingLabel)

            self.floatingLabel.bottomAnchor.constraint(equalTo: self.topAnchor, constant: -2).isActive = true // Place our label 10pts above the text field
            // Remove the placeholder
            self.placeholder = ""
        }
        self.setNeedsDisplay()
    }

    @objc func removeFloatingLabel() {
        if self.text == "" {
            UIView.animate(withDuration: 0.13) {
               self.subviews.forEach{ $0.removeFromSuperview() }
               self.setNeedsDisplay()
            }
            self.placeholder = self._placeholder
        }
        self.layer.borderColor = UIColor.black.cgColor
    }

}
//final class SettingsInfoCell: UITableViewCell {
//
//    var contentStackView: UIStackView!
//    let titleTextField = SimpleTextField()
//    let title = UILabel()
//
//    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
//        super.init(style: style, reuseIdentifier: reuseIdentifier)
//        setup()
//    }
//
//    @available(*, unavailable)
//    required init?(coder aDecoder: NSCoder) {
//        fatalError("init?(coder aDecoder: NSCoder) is not implemented")
//    }
//
//    private func setup() {
//        contentStackView = UIStackView(arrangedSubviews: [titleTextField])
//        contentStackView.axis = .horizontal
//        contentStackView.distribution = .fill
//        contentStackView.alignment = .center
//        contentStackView.translatesAutoresizingMaskIntoConstraints = false
//
//        contentView.addSubview(contentStackView)
//    }
//
//}

final class GroupDetailsRenameCell: UICollectionViewCell {

    let verifiedIconView = UIImageView()
    let accessoryIconView = UIImageView()
    let titleTextField = SimpleTextField()
    var contentStackView: UIStackView!

    override init(frame: CGRect) {
        super.init(frame: frame)

        setup()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init?(coder aDecoder: NSCoder) is not implemented")
    }

    fileprivate func setup() {

        verifiedIconView.image = WireStyleKit.imageOfShieldverified
        verifiedIconView.translatesAutoresizingMaskIntoConstraints = false
        verifiedIconView.contentMode = .scaleAspectFit
        verifiedIconView.setContentHuggingPriority(UILayoutPriority.required, for: .horizontal)
        verifiedIconView.setContentCompressionResistancePriority(UILayoutPriority.required, for: .horizontal)
        verifiedIconView.accessibilityIdentifier = "img.shield"

        accessoryIconView.translatesAutoresizingMaskIntoConstraints = false
        accessoryIconView.contentMode = .scaleAspectFit
        accessoryIconView.setContentHuggingPriority(UILayoutPriority.required, for: .horizontal)
        accessoryIconView.setContentCompressionResistancePriority(UILayoutPriority.required, for: .horizontal)

        titleTextField.translatesAutoresizingMaskIntoConstraints = false
        titleTextField.font = FontSpec.init(.normal, .light).font!
        titleTextField.returnKeyType = .done
        titleTextField.backgroundColor = .clear
        titleTextField.textInsets = UIEdgeInsets.zero
        titleTextField.keyboardAppearance = .default

        contentStackView = UIStackView(arrangedSubviews: [verifiedIconView, titleTextField, accessoryIconView])
        contentStackView.axis = .horizontal
        contentStackView.distribution = .fill
        contentStackView.alignment = .center
        contentStackView.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(contentStackView)
        contentStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24).isActive = true
        contentStackView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        contentStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        contentStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16).isActive = true
        contentStackView.spacing = 8

        configureColors()
    }

    func configure(for conversation: GroupDetailsConversationType, editable: Bool) {
        titleTextField.text = conversation.displayName
        verifiedIconView.isHidden = conversation.securityLevel != .secure

        titleTextField.isUserInteractionEnabled = editable
        accessoryIconView.isHidden = !editable
    }

    private func configureColors() {
        backgroundColor = SemanticColors.View.backgroundUserCell
        accessoryIconView.setTemplateIcon(.pencil, size: .tiny)
        accessoryIconView.tintColor = SemanticColors.Icon.foregroundDefault
        titleTextField.textColor = SemanticColors.Label.textDefault
    }

}
