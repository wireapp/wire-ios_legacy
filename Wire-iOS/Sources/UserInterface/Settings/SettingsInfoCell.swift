//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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
import WireCommonComponents

final class SettingsInfoCell: SettingsTableCell {

    // MARK: - Properties

    private let textInputSmallHeight: CGFloat = 24
    private let bottomStackPadding: CGFloat = 6
    private let bottomTitlePadding: CGFloat = 4

    private let contentPadding: CGFloat = 16

    var textInput: TextFieldWithPadding = {
        return TextFieldWithPadding(frame: .zero)
    }()

    private let titleLabel: DynamicFontLabel = {
        return DynamicFontLabel(fontSpec: .accountTeam, color: SemanticColors.Label.textUserPropertyCellName)
    }()

    private let clearButton: IconButton = {
        return IconButton(style: .default)
    }()

    private let subtitleLabel: DynamicFontLabel = {
        return DynamicFontLabel(fontSpec: .mediumRegularFont, color: SemanticColors.Label.textUserPropertyCellName)
    }()

    private lazy var contentStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [textInput, subtitleLabel])
        stack.axis = .vertical
        stack.alignment = .leading
        stack.spacing = 8
        stack.setContentCompressionResistancePriority(.required, for: .vertical)

        return stack
    }()

    private let accessoryIconView: UIImageView = {
        let iconView = UIImageView()
        iconView.clipsToBounds = true
        iconView.contentMode = .scaleAspectFill
        iconView.setTemplateIcon(.pencil, size: .tiny)
        iconView.tintColor = SemanticColors.Icon.foregroundDefault

        return iconView
    }()

    private lazy var textInputHeightConstraint: NSLayoutConstraint = textInput.heightAnchor.constraint(equalToConstant: textInputSmallHeight)
    private lazy var bottomTitleConstraint: NSLayoutConstraint = titleLabel.bottomAnchor.constraint(equalTo: contentStackView.topAnchor,
                                                                                                    constant: -(bottomTitlePadding * 2))
    private lazy var bottomStackConstraint: NSLayoutConstraint = contentStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor,
                                                                                                          constant: -6)

    var textFieldDidChanges: (() -> Void)? = nil

    private var isEditingTextField: Bool = false {
        didSet {
            if isEditingTextField {
                textInput.layer.borderWidth = 1
                textInput.layer.borderColor = UIColor.accent().cgColor
                textInput.layer.cornerRadius = 12
                UIView.animate(withDuration: 0.4) {
                    self.backgroundView?.backgroundColor = SemanticColors.View.backgroundDefault
                    self.titleLabel.textColor = .accent()
                    self.textInput.font = FontSpec.body.font!
                    self.clearButton.isHidden = false
                    self.subtitleLabel.isHidden = self.isSubtitleHidden || false
                    self.isAccessoryIconHidden = true
                    self.textInputHeightConstraint.constant = self.textInputSmallHeight * 2
                    self.bottomTitleConstraint.constant = -self.bottomTitlePadding
                    self.bottomStackConstraint.constant = -(self.bottomStackPadding * 2)
                }
            } else {
                textInput.layer.borderWidth = 0
                UIView.animate(withDuration: 0.4) {
                    self.backgroundView?.backgroundColor = SemanticColors.View.backgroundUserCell
                    self.titleLabel.textColor = SemanticColors.Label.textUserPropertyCellName
                    self.textInput.font = FontSpec.bodyTwoSemibold.font!
                    self.clearButton.isHidden = true
                    self.subtitleLabel.isHidden = self.isSubtitleHidden || true
                    self.isAccessoryIconHidden = false
                    self.textInputHeightConstraint.constant = self.textInputSmallHeight
                    self.bottomTitleConstraint.constant = -(self.bottomTitlePadding * 2)
                    self.bottomStackConstraint.constant = -self.bottomStackPadding
                }
            }
            textFieldDidChanges?()
        }
    }

    var isAccessoryIconHidden: Bool = false {
        didSet {
            accessoryIconView.isHidden = isAccessoryIconHidden
        }
    }

    var isSubtitleHidden: Bool = true {
        didSet {
            subtitleLabel.isHidden = isSubtitleHidden
        }
    }

    var title: String = "" {
        didSet {
            titleLabel.text = title
            textInput.placeholder = title
            accessibilityIdentifier = title
        }
    }

    var value: String = "" {
        didSet {
            textInput.text = value
        }
    }

    override func setup() {
        super.setup()

        backgroundView = UIView()
        backgroundView?.backgroundColor = SemanticColors.View.backgroundUserCell

        textInput.textColor = SemanticColors.Label.textDefault
        textInput.backgroundColor = SemanticColors.View.backgroundDefaultWhite
        textInput.font = FontSpec.bodyTwoSemibold.font!

        textInput.delegate = self
        textInput.autocorrectionType = .no
        textInput.spellCheckingType = .no

        clearButton.setIcon(.clearInput, size: .tiny, for: .normal)
        clearButton.setIconColor(SemanticColors.Icon.foregroundDefaultBlack, for: .normal)
        clearButton.isHidden = true
        clearButton.addTarget(self, action: #selector(onClearButtonPressed), for: .touchUpInside)
        clearButton.accessibilityIdentifier = "clear button"
        clearButton.accessibilityLabel = L10n.Accessibility.SearchView.ClearButton.description

        subtitleLabel.text = L10n.Localizable.Self.Settings.AccountSection.Handle.Change.footer
        subtitleLabel.isHidden = true

        [titleLabel, contentStackView, clearButton, accessoryIconView].forEach {
            contentView.addSubview($0)
        }

        setupAccessibility()
        createConstraints()

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(onCellSelected(_:)))
        contentView.addGestureRecognizer(tapGestureRecognizer)
    }

    override func setupAccessibility() {
        // TODO setup

//        isAccessibilityElement = true
//        accessibilityTraits = .button
    }

    private func createConstraints() {
        [titleLabel, contentStackView, clearButton, accessoryIconView].prepareForLayout()

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -contentPadding),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: contentPadding),
            bottomTitleConstraint,

            textInput.trailingAnchor.constraint(equalTo: contentStackView.trailingAnchor),
            textInput.leadingAnchor.constraint(equalTo: contentStackView.leadingAnchor),
            textInputHeightConstraint,

            clearButton.widthAnchor.constraint(equalToConstant: 16),
            clearButton.heightAnchor.constraint(equalTo: clearButton.widthAnchor),
            clearButton.centerYAnchor.constraint(equalTo: textInput.centerYAnchor),
            clearButton.trailingAnchor.constraint(equalTo: textInput.trailingAnchor, constant: -contentPadding),

            accessoryIconView.widthAnchor.constraint(equalTo: accessoryIconView.heightAnchor),
            accessoryIconView.heightAnchor.constraint(equalToConstant: 16),
            accessoryIconView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            accessoryIconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            contentStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -contentPadding),
            contentStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: contentPadding),
            bottomStackConstraint
        ])
    }

    // MARK: - Actions

    @objc
    private func onCellSelected(_ sender: AnyObject!) {
        if !textInput.isFirstResponder {
            textInput.becomeFirstResponder()
        }
    }

    @objc
    private func onClearButtonPressed() {
        textInput.text = ""
    }

}

// MARK: - UITextFieldDelegate

extension SettingsInfoCell: UITextFieldDelegate {

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string.rangeOfCharacter(from: CharacterSet.newlines) != .none {
            textField.resignFirstResponder()
            return false
        } else {
            return true
        }
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        isEditingTextField = true
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        isEditingTextField = false
        if let text = textInput.text {
            descriptor?.select(SettingsPropertyValue.string(value: text))
        }
    }

}

// MARK: - TextFieldWithPadding

final class TextFieldWithPadding: UITextField {

    var textPadding = UIEdgeInsets(
        top: 0,
        left: 16,
        bottom: 0,
        right: 16
    )

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        let rect = super.editingRect(forBounds: bounds)
        return rect.inset(by: textPadding)
    }

    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        let rect = super.textRect(forBounds: bounds)
        return rect.inset(by: textPadding)
    }

}
