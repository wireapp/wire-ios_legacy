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

class SettingsInfoCell: SettingsTableCell, UITextFieldDelegate {

//    // MARK: Data
//    var tweet: Tweet? {
//        didSet {
//            guard let tweet = tweet else {
//                tweetText.text = nil
//                return
//            }
//
//            tweetText.text = tweet.text
//
//            if let mediaURL = tweet.mediaURL {
//                KingfisherManager.shared.retrieveImage(with: mediaURL) { result in
//                    switch result {
//                    case .success(let value):
//                        self.mediaView.image = value.image
//                        let aspectRatio = self.vStack.frame.width / value.image.size.width
//                        // UPDATING THE CONSTRAINT TO MATCH THE IMAGE HEIGHT HERE!!!
//                        self.mediaViewHeightAnchor.constant = value.image.size.height * aspectRatio
//                    case .failure(let error):
//                        print(error.localizedDescription)
//                    }
//                }
//            }
//        }
//    }

    private var isEditingTextField: Bool = false {
        didSet {
            if isEditingTextField {
                textInput.layer.borderWidth = 1
                textInput.layer.borderColor = UIColor.accent().cgColor
                textInput.layer.cornerRadius = 12
                backgroundView?.backgroundColor = SemanticColors.View.backgroundDefault
                titleLabel.textColor = .accent()
                mediaViewHeightAnchor.constant = 48
            } else {
                textInput.layer.borderWidth = 0
                backgroundView?.backgroundColor = SemanticColors.View.backgroundUserCell
                titleLabel.textColor = SemanticColors.Label.textUserPropertyCellName
                mediaViewHeightAnchor.constant = 24
            }
        }
    }

    private let titleLabel = DynamicFontLabel(text: "Profile name",
                                              fontSpec: .accountTeam,
                                              color: SemanticColors.Label.textUserPropertyCellName)

    private lazy var mediaViewHeightAnchor = textInput.heightAnchor.constraint(equalToConstant: 24)
    let textInput: SimpleTextField = {
        let textInput = SimpleTextField()
        textInput.textColor = SemanticColors.Label.textDefault
        textInput.font = FontSpec.body.font!
        textInput.text = "@jaquelineolaho"
        return textInput
    }()

    private lazy var vStack: UIStackView = {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        let stack = UIStackView(arrangedSubviews: [titleLabel, textInput])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.alignment = .leading
        stack.spacing = 8
        stack.setContentCompressionResistancePriority(.required, for: .vertical)
        return stack
    }()

    // MARK: Overrides
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        loadView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        mediaViewHeightAnchor.constant = 24
    }

    private func loadView() {
        textInput.delegate = self
        contentView.addSubview(vStack)
        vStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0).isActive = true
        vStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16).isActive = true
        vStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16).isActive = true
        vStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 0).isActive = true

        NSLayoutConstraint.activate([mediaViewHeightAnchor])
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        isEditingTextField = true
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        isEditingTextField = false
    }
}

final class SettingsInfoCell1: SettingsTableCell,/* CellConfigurationConfigurable,*/ UITextFieldDelegate {

    private var contentStackView: UIStackView!
    private var textInput: SimpleTextField! //= SimpleTextField()
    private let titleLabel = DynamicFontLabel(text: "Profile name",
                                              fontSpec: .accountTeam,
                                              color: SemanticColors.Label.textUserPropertyCellName)
    lazy var textInputHeight: NSLayoutConstraint = textInput.heightAnchor.constraint(equalToConstant: 24)

   // private let subtitleLabel = UILabel()

    private var isEditingTextField: Bool = false {
        didSet {
            if isEditingTextField {
                textInput.layer.borderWidth = 1
                textInput.layer.borderColor = UIColor.accent().cgColor
                textInput.layer.cornerRadius = 12
                backgroundView?.backgroundColor = SemanticColors.View.backgroundDefault
                titleLabel.textColor = .accent()
                textInputHeight.constant = 48
//                    self.textInputHeight.isActive = true
            } else {
                textInput.layer.borderWidth = 0
                backgroundView?.backgroundColor = SemanticColors.View.backgroundUserCell
                titleLabel.textColor = SemanticColors.Label.textUserPropertyCellName
                textInputHeight.constant = 24
//                    self.textInputHeight.isActive = false
            }
            //self.layoutIfNeeded()
           // setNeedsLayout()
            self.invalidateIntrinsicContentSize()
        }
    }
    override func prepareForReuse() {
        super.prepareForReuse()

        textInputHeight.constant = 24
    }

    override func setup() {
        super.setup()

        selectionStyle = .none
        backgroundView = UIView()
//        selectedBackgroundView = UIView()
//        backgroundView?.backgroundColor = SemanticColors.View.backgroundDefault

//        textInput = TailEditingTextField(frame: .zero)
//        textInput = UITextField(frame: .zero)
        textInput = SimpleTextField()
       // textInputHeight.priority = .defaultHigh
        //textInput.delegate = self
        textInput.textColor = SemanticColors.Label.textDefault
//        textInput.font = FontSpec.bodyTwoSemibold.font!
        textInput.font = FontSpec.body.font!
        //  textInput.setContentCompressionResistancePriority(UILayoutPriority.defaultLow, for: .horizontal)
        //textInput.isAccessibilityElement = true
        textInput.placeholder = "Something"
//        textInput.text = "Jaqueline Olaho"
        textInput.text = "@jaquelineolaho"

       // textInput.returnKeyType = .done
        textInput.textFieldDelegate = self

//        contentStackView = UIStackView(arrangedSubviews: [titleLabel, textInput])
//        contentStackView.axis = .vertical
//        contentStackView.distribution = .fill
//        contentStackView.alignment = .leading
//        contentStackView.spacing = 10

//        contentView.addSubview(contentStackView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(textInput)

        setContentCompressionResistancePriority(.required, for: .vertical)
        createConstraints()

        //        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(onCellSelected(_:)))
//        contentView.addGestureRecognizer(tapGestureRecognizer)

    }

    private func createConstraints() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        textInput.translatesAutoresizingMaskIntoConstraints = false
//        titleLabel.setContentHuggingPriority(.required, for: .vertical)
//        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            titleLabel.bottomAnchor.constraint(equalTo: textInput.topAnchor, constant: -4),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),

            //textInput.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            textInput.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            textInput.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            textInput.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            textInputHeight
        ])

//        contentStackView.translatesAutoresizingMaskIntoConstraints = false
//        NSLayoutConstraint.activate([
//            contentStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
//            contentStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 7),
//            contentStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5),
//            contentStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4)
//        ])

    }

//    @objc
//    func onCellSelected(_ sender: AnyObject!) {
//        if !textInput.isFirstResponder {
//            textInput.becomeFirstResponder()
//        }
//    }

    // MARK: - UITextFieldDelegate

//    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
//        if string.rangeOfCharacter(from: CharacterSet.newlines) != .none {
//            textField.resignFirstResponder()
//            return false
//        } else {
//            return true
//        }
//    }

//    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
//        return true
//    }

    func textFieldDidEndEditing(_ textField: UITextField) {
//        if let text = textInput.text {
//            descriptor?.select(SettingsPropertyValue.string(value: text))
//        }
    }
}

extension SettingsInfoCell1: SimpleTextFieldDelegate {
    func textField(_ textField: SimpleTextField, valueChanged value: SimpleTextField.Value) {

    }
    func textFieldReturnPressed(_ textField: SimpleTextField) {

    }
    func textFieldDidEndEditing(_ textField: SimpleTextField) {
        isEditingTextField = false
    }
    func textFieldDidBeginEditing(_ textField: SimpleTextField) {
        isEditingTextField = true
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
