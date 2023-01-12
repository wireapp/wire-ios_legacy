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
import WireCommonComponents

enum SettingsCellPreview {
    case none
    case text(String)
    case badge(Int)
    case image(UIImage)
    case color(UIColor)
}

protocol SettingsCellType: AnyObject {
    var titleText: String {get set}
    var preview: SettingsCellPreview {get set}
    var descriptor: SettingsCellDescriptorType? {get set}
    var icon: StyleKitIcon? {get set}
}

typealias SettingsTableCellProtocol = UITableViewCell & SettingsCellType

class SettingsTableCell: SettingsTableCellProtocol {
    private let iconImageView: UIImageView = {
        let iconImageView = UIImageView()
        iconImageView.contentMode = .center
        iconImageView.tintColor = SemanticColors.Label.textDefault
        return iconImageView
    }()

    let cellNameLabel: UILabel = {
        let label = DynamicFontLabel(
            fontSpec: .normalSemiboldFont,
            color: SemanticColors.Label.textDefault)
        label.numberOfLines = 0
        label.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        label.setContentHuggingPriority(UILayoutPriority.required, for: .horizontal)
        label.adjustsFontSizeToFitWidth = true

        return label
    }()

    let valueLabel: UILabel = {
        let valueLabel = UILabel()

        valueLabel.textColor = SemanticColors.Label.textDefault
        valueLabel.font = UIFont.systemFont(ofSize: 17)
        valueLabel.textAlignment = .right

        return valueLabel
    }()

    let badge: RoundedBadge = {
        let badge = RoundedBadge(view: UIView())
        badge.backgroundColor = SemanticColors.View.backgroundDefaultBlack
        badge.isHidden = true

        return badge
    }()

    private let badgeLabel: UILabel = {
        let badgeLabel = DynamicFontLabel(fontSpec: .smallMediumFont,
                                          color: SemanticColors.Label.textDefaultWhite)
        badgeLabel.textAlignment = .center
        return badgeLabel
    }()

    private let imagePreview: UIImageView = {
        let imagePreview = UIImageView()
        imagePreview.clipsToBounds = true
        imagePreview.layer.cornerRadius = 12
        imagePreview.contentMode = .scaleAspectFill
        imagePreview.accessibilityIdentifier = "imagePreview"

        return imagePreview
    }()

    private lazy var cellNameLabelToIconInset: NSLayoutConstraint = cellNameLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 24)

    var titleText: String = "" {
        didSet {
            cellNameLabel.text = titleText
        }
    }

    var preview: SettingsCellPreview = .none {
        didSet {
            switch preview {
            case .text(let string):
                valueLabel.text = string
                badgeLabel.text = ""
                badge.isHidden = true
                imagePreview.image = .none
                imagePreview.backgroundColor = UIColor.clear
                imagePreview.accessibilityValue = nil
                imagePreview.isAccessibilityElement = false

            case .badge(let value):
                valueLabel.text = ""
                badgeLabel.text = "\(value)"
                badge.isHidden = false
                imagePreview.image = .none
                imagePreview.backgroundColor = UIColor.clear
                imagePreview.accessibilityValue = nil
                imagePreview.isAccessibilityElement = false

            case .image(let image):
                valueLabel.text = ""
                badgeLabel.text = ""
                badge.isHidden = true
                imagePreview.image = image
                imagePreview.backgroundColor = UIColor.clear
                imagePreview.accessibilityValue = "image"
                imagePreview.isAccessibilityElement = true

            case .color(let color):
                valueLabel.text = ""
                badgeLabel.text = ""
                badge.isHidden = true
                imagePreview.image = .none
                imagePreview.backgroundColor = color
                imagePreview.accessibilityValue = "color"
                imagePreview.isAccessibilityElement = true

            case .none:
                valueLabel.text = ""
                badgeLabel.text = ""
                badge.isHidden = true
                imagePreview.image = .none
                imagePreview.backgroundColor = UIColor.clear
                imagePreview.accessibilityValue = nil
                imagePreview.isAccessibilityElement = false
            }
            setupAccessibility()
        }
    }

    var icon: StyleKitIcon? {
        didSet {
            if let icon = icon {
                iconImageView.setTemplateIcon(icon, size: .tiny)
                cellNameLabelToIconInset.isActive = true
            } else {
                iconImageView.image = nil
                cellNameLabelToIconInset.isActive = false
            }
        }
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        updateBackgroundColor()
    }

    var descriptor: SettingsCellDescriptorType?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init?(coder aDecoder: NSCoder) is not implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        preview = .none
    }

    func setup() {
        backgroundView = UIView()
        selectedBackgroundView = UIView()

        badge.containedView.addSubview(badgeLabel)

        [iconImageView, cellNameLabel, valueLabel, badge, imagePreview].forEach {
            contentView.addSubview($0)
        }

        createConstraints()
        addBorder(for: .bottom)
        setupAccessibility()
    }

    private func createConstraints() {
        let leadingConstraint = cellNameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16)
        leadingConstraint.priority = .defaultHigh

        let trailingBoundaryView = accessoryView ?? contentView

        if trailingBoundaryView != contentView {
            trailingBoundaryView.translatesAutoresizingMaskIntoConstraints = false
        }

        [iconImageView, valueLabel, badge, badgeLabel, imagePreview, cellNameLabel].prepareForLayout()

        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            iconImageView.widthAnchor.constraint(equalToConstant: 16),
            iconImageView.heightAnchor.constraint(equalTo: iconImageView.heightAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            leadingConstraint,
            cellNameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            cellNameLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),

            valueLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: -8),
            valueLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 8),
            valueLabel.leadingAnchor.constraint(greaterThanOrEqualTo: cellNameLabel.trailingAnchor, constant: 8),
            valueLabel.trailingAnchor.constraint(equalTo: trailingBoundaryView.trailingAnchor, constant: -16),
            badge.centerXAnchor.constraint(equalTo: valueLabel.centerXAnchor),
            badge.centerYAnchor.constraint(equalTo: valueLabel.centerYAnchor),
            badge.heightAnchor.constraint(equalToConstant: 20),
            badge.widthAnchor.constraint(greaterThanOrEqualToConstant: 28),

            badgeLabel.leadingAnchor.constraint(equalTo: badge.leadingAnchor, constant: 6),
            badgeLabel.trailingAnchor.constraint(equalTo: badge.trailingAnchor, constant: -6),
            badgeLabel.topAnchor.constraint(equalTo: badge.topAnchor),
            badgeLabel.bottomAnchor.constraint(equalTo: badge.bottomAnchor),

            imagePreview.widthAnchor.constraint(equalTo: imagePreview.heightAnchor),
            imagePreview.heightAnchor.constraint(equalToConstant: 24),
            imagePreview.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            imagePreview.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 56)
        ])
    }

    func setupAccessibility() {
        isAccessibilityElement = true
        accessibilityTraits = .button
        let badgeValue = badgeLabel.text ?? ""
        accessibilityHint = badgeValue.isEmpty ? "" : L10n.Accessibility.Settings.DeviceCount.hint("\(badgeValue)")
    }

    func updateBackgroundColor() {
        backgroundColor = SemanticColors.View.backgroundUserCell

        if isHighlighted && selectionStyle != .none {
            backgroundColor = SemanticColors.View.backgroundUserCellHightLighted
            badge.backgroundColor = SemanticColors.View.backgroundDefaultBlack
            badgeLabel.textColor = SemanticColors.Label.textDefaultWhite
        }
    }
}

final class SettingsButtonCell: SettingsTableCell {
    override func setup() {
        super.setup()
        cellNameLabel.textColor = SemanticColors.Label.textDefault
    }
}

final class SettingsToggleCell: SettingsTableCell {
    var switchView: UISwitch!

    override func setup() {
        super.setup()
        selectionStyle = .none
        shouldGroupAccessibilityChildren = false
        let switchView = Switch(style: .default)
        switchView.addTarget(self, action: #selector(SettingsToggleCell.onSwitchChanged(_:)), for: .valueChanged)
        accessoryView = switchView
        switchView.isAccessibilityElement = true
        accessibilityElements = [cellNameLabel, switchView]
        accessibilityTraits = .button
        self.switchView = switchView
        backgroundColor = SemanticColors.View.backgroundUserCell
    }

    @objc
    func onSwitchChanged(_ sender: UIResponder) {
        descriptor?.select(SettingsPropertyValue(switchView.isOn))
    }
}

final class SettingsValueCell: SettingsTableCell {
    override var descriptor: SettingsCellDescriptorType? {
        willSet {
            if let propertyDescriptor = descriptor as? SettingsPropertyCellDescriptorType {
                NotificationCenter.default.removeObserver(self,
                                                          name: propertyDescriptor.settingsProperty.propertyName.notificationName,
                                                          object: nil)
            }
        }
        didSet {
            if let propertyDescriptor = descriptor as? SettingsPropertyCellDescriptorType {

                NotificationCenter.default.addObserver(self,
                                                       selector: #selector(SettingsValueCell.onPropertyChanged(_:)),
                                                       name: propertyDescriptor.settingsProperty.propertyName.notificationName,
                                                       object: nil)
            }
        }
    }

    // MARK: - Properties observing

    @objc func onPropertyChanged(_ notification: Notification) {
        descriptor?.featureCell(self)
    }
}

final class SettingsTextCell: SettingsTableCell,
                              UITextFieldDelegate {
    var textInput: UITextField!

    override func setup() {
        super.setup()
        selectionStyle = .none

        textInput = TailEditingTextField(frame: CGRect.zero)
        textInput.delegate = self
        textInput.textAlignment = .right
        textInput.textColor = SemanticColors.Label.textDefault
        textInput.setContentCompressionResistancePriority(UILayoutPriority.defaultLow, for: .horizontal)
        textInput.isAccessibilityElement = true

        contentView.addSubview(textInput)

        createConstraints()

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(onCellSelected(_:)))
        contentView.addGestureRecognizer(tapGestureRecognizer)
    }

    private func createConstraints() {
        let textInputSpacing: CGFloat = 16

        let trailingBoundaryView = accessoryView ?? contentView

        textInput.translatesAutoresizingMaskIntoConstraints = false
        if trailingBoundaryView != contentView {
            trailingBoundaryView.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            textInput.topAnchor.constraint(equalTo: contentView.topAnchor, constant: -8),
            textInput.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 8),
            textInput.trailingAnchor.constraint(equalTo: trailingBoundaryView.trailingAnchor, constant: -textInputSpacing),

            cellNameLabel.trailingAnchor.constraint(equalTo: textInput.leadingAnchor, constant: -textInputSpacing)
        ])

    }

    override func setupAccessibility() {
        super.setupAccessibility()

        var currentElements = accessibilityElements ?? []
        if let textInput = textInput {
            currentElements.append(textInput)
        }
        accessibilityElements = currentElements
    }

    @objc
    func onCellSelected(_ sender: AnyObject!) {
        if !textInput.isFirstResponder {
            textInput.becomeFirstResponder()
        }
    }

    // MARK: - UITextFieldDelegate

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string.rangeOfCharacter(from: CharacterSet.newlines) != .none {
            textField.resignFirstResponder()
            return false
        } else {
            return true
        }
    }

    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        return true
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        if let text = textInput.text {
            descriptor?.select(SettingsPropertyValue.string(value: text))
        }
    }
}

// TODO move to separate file
final class SettingsInfoCell: SettingsTableCell {

    // MARK: - Properties

    private let titleLabel: DynamicFontLabel = {
        return DynamicFontLabel(fontSpec: .accountTeam, color: SemanticColors.Label.textUserPropertyCellName)
    }()

    var textInput: TextFieldWithPadding = {
        return TextFieldWithPadding(frame: .zero)
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

    // TODO Magic numbers
    private lazy var textInputHeightConstraint: NSLayoutConstraint = textInput.heightAnchor.constraint(equalToConstant: 24)
    private lazy var bottomTitleConstraint: NSLayoutConstraint = titleLabel.bottomAnchor.constraint(equalTo: contentStackView.topAnchor, constant: -8)
    private lazy var bottomStackConstraint: NSLayoutConstraint = contentStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6)

    // TODO clean
    var textDidChanges: (() -> Void)? = nil

    // TODO clean
    private var isEditingTextField: Bool = false {
        didSet {
            if isEditingTextField {
                textInput.layer.borderWidth = 1
                textInput.layer.borderColor = UIColor.accent().cgColor
                textInput.layer.cornerRadius = 12
                UIView.animate(withDuration: 0.3) {
                    self.backgroundView?.backgroundColor = SemanticColors.View.backgroundDefault
                    self.titleLabel.textColor = .accent()
                    self.textInput.font = FontSpec.body.font!
                    self.clearButton.isHidden = false
                    self.subtitleLabel.isHidden = false
                    self.isAccessoryIconHidden = true
                    self.subtitleLabel.text = "At least 2 characters. a-z, 0-9, and '.','-','_' only."
                }
                textInputHeightConstraint.constant = 48
                bottomTitleConstraint.constant = -4
                bottomStackConstraint.constant = -12
            } else {
                textInput.layer.borderWidth = 0
                UIView.animate(withDuration: 0.3) {
                    self.backgroundView?.backgroundColor = SemanticColors.View.backgroundUserCell
                    self.titleLabel.textColor = SemanticColors.Label.textUserPropertyCellName
                    self.textInput.font = FontSpec.bodyTwoSemibold.font!
                    self.clearButton.isHidden = true
                    self.subtitleLabel.isHidden = true
                    self.isAccessoryIconHidden = false
                    self.subtitleLabel.text = ""

                }
                textInputHeightConstraint.constant = 24
                bottomTitleConstraint.constant = -8
                bottomStackConstraint.constant = -6
            }
            textDidChanges?()

        }
    }

    var isAccessoryIconHidden: Bool = false {
        didSet {
            accessoryIconView.isHidden = isAccessoryIconHidden
        }
    }

    var title: String = "" {
        didSet {
            titleLabel.text = title
            textInput.placeholder = title
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

        textInput = TextFieldWithPadding(frame: .zero)
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

        subtitleLabel.isHidden = true

        [titleLabel, contentStackView, clearButton, accessoryIconView].forEach {
            contentView.addSubview($0)
        }

        createConstraints()

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(onCellSelected(_:)))
        contentView.addGestureRecognizer(tapGestureRecognizer)
    }

    private func createConstraints() {
        [titleLabel, contentStackView, clearButton, accessoryIconView].prepareForLayout()

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            bottomTitleConstraint,

            textInput.trailingAnchor.constraint(equalTo: contentStackView.trailingAnchor),
            textInput.leadingAnchor.constraint(equalTo: contentStackView.leadingAnchor),
            textInputHeightConstraint,

            clearButton.widthAnchor.constraint(equalToConstant: 16),
            clearButton.heightAnchor.constraint(equalTo: clearButton.widthAnchor),
            clearButton.centerYAnchor.constraint(equalTo: textInput.centerYAnchor),
            clearButton.trailingAnchor.constraint(equalTo: textInput.trailingAnchor, constant: -16),

            accessoryIconView.widthAnchor.constraint(equalTo: accessoryIconView.heightAnchor),
            accessoryIconView.heightAnchor.constraint(equalToConstant: 16),
            accessoryIconView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            accessoryIconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            contentStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            contentStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
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
    }

}

class TextFieldWithPadding: UITextField {
    var textPadding = UIEdgeInsets(
        top: 0,
        left: 16,
        bottom: 0,
        right: 32
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

final class SettingsStaticTextTableCell: SettingsTableCell {

    override func setup() {
        super.setup()
        cellNameLabel.numberOfLines = 0
        cellNameLabel.textAlignment = .justified
        accessibilityTraits = .staticText
    }

}

final class SettingsProfileLinkCell: SettingsTableCell {

    // MARK: - Properties

    var label = CopyableLabel()

    override func setup() {
        super.setup()

        setupViews()
        createConstraints()
    }

    // MARK: - Helpers

    private func setupViews() {
        contentView.addSubview(label)

        label.textColor = SemanticColors.Label.textDefault
        label.font = FontSpec(.normal, .light).font
        label.lineBreakMode = .byClipping
        label.numberOfLines = 0
        accessibilityTraits = .staticText
    }

    private func createConstraints() {
        [label].prepareForLayout()
        label.fitIn(view: contentView, insets: UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16))
    }

}
