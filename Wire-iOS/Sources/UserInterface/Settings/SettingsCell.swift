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

enum SettingsCellPreview {
    case none
    case text(String)
    case badge(Int)
    case image(UIImage)
    case color(UIColor)
}

protocol SettingsCellType: class {
    var titleText: String {get set}
    var preview: SettingsCellPreview {get set}
    var titleColor: UIColor {get set}
    var cellColor: UIColor? {get set}
    var descriptor: SettingsCellDescriptorType? {get set}
    var icon: ZetaIconType {get set}
}

@objcMembers class SettingsTableCell: UITableViewCell, SettingsCellType {
    let iconImageView = UIImageView()
    public let cellNameLabel: UILabel = {
        let label = UILabel()
        label.font = .normalLightFont
        label.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)

        return label
    }()
    let valueLabel = UILabel()
    let badge = RoundedBadge(view: UIView())
    var badgeLabel = UILabel()
    let imagePreview = UIImageView()
    let separatorLine = UIView()
    let topSeparatorLine = UIView()
    var cellNameLabelToIconInset: NSLayoutConstraint!

    var variant: ColorSchemeVariant? = .none {
        didSet {
            switch variant {
            case .dark?, .none:
                titleColor = .white
            case .light?:
                titleColor = UIColor.from(scheme: .textForeground, variant: .light)
            }
        }
    }

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
        }
    }
    
    var icon: ZetaIconType = .none {
        didSet {
            if icon == .none {
                iconImageView.image = .none
                cellNameLabelToIconInset.isActive = false
            }
            else {
                iconImageView.image = UIImage(for: icon, iconSize: .tiny, color: UIColor.white)
                cellNameLabelToIconInset.isActive = true
            }
        }
    }
    
    var isFirst: Bool = false {
        didSet {
            topSeparatorLine.isHidden = !isFirst
        }
    }
    
    var titleColor: UIColor = UIColor.white {
        didSet {
            cellNameLabel.textColor = titleColor
        }
    }
    
    var cellColor: UIColor? {
        didSet {
            backgroundColor = cellColor
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
        setupAccessibiltyElements()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
        setupAccessibiltyElements()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        preview = .none
    }
    
    func setup() {
        backgroundColor = UIColor.clear
        backgroundView = UIView()
        selectedBackgroundView = UIView()
        
        iconImageView.contentMode = .center
        contentView.addSubview(iconImageView)
        
        constrain(contentView, iconImageView) { contentView, iconImageView in
            iconImageView.leading == contentView.leading + 24
            iconImageView.width == 16
            iconImageView.height == iconImageView.height
            iconImageView.centerY == contentView.centerY
        }
        
        cellNameLabel.setContentHuggingPriority(UILayoutPriority.required, for: .horizontal)
        contentView.addSubview(cellNameLabel)
        
        constrain(contentView, cellNameLabel, iconImageView) { contentView, cellNameLabel, iconImageView in
            cellNameLabelToIconInset = cellNameLabel.leading == iconImageView.trailing + 24
            cellNameLabel.leading == contentView.leading + 16 ~ 750.0
            cellNameLabel.top == contentView.top + 12
            cellNameLabel.bottom == contentView.bottom - 12
        }
        
        cellNameLabelToIconInset.isActive = false
        
        valueLabel.textColor = UIColor.lightGray
        valueLabel.font = UIFont.systemFont(ofSize: 17)
        valueLabel.textAlignment = .right
        
        contentView.addSubview(valueLabel)

        badgeLabel.font = FontSpec(.small, .medium).font
        badgeLabel.textAlignment = .center
        badgeLabel.textColor = UIColor.black
        
        badge.containedView.addSubview(badgeLabel)
        
        badge.backgroundColor = UIColor.white
        badge.isHidden = true
        contentView.addSubview(badge)
        
        let trailingBoundaryView = accessoryView ?? contentView

        constrain(contentView, cellNameLabel, valueLabel, trailingBoundaryView, badge) { contentView, cellNameLabel, valueLabel, trailingBoundaryView, badge in
            valueLabel.top == contentView.top - 8
            valueLabel.bottom == contentView.bottom + 8
            valueLabel.leading >= cellNameLabel.trailing + 8
            valueLabel.trailing == trailingBoundaryView.trailing - 16
            badge.center == valueLabel.center
            badge.height == 20
            badge.width >= 28
        }
        
        constrain(badge, badgeLabel) { badge, badgeLabel in
            badgeLabel.leading == badge.leading + 6
            badgeLabel.trailing == badge.trailing - 6
            badgeLabel.top == badge.top
            badgeLabel.bottom == badge.bottom
        }
        
        imagePreview.clipsToBounds = true
        imagePreview.layer.cornerRadius = 12
        imagePreview.contentMode = .scaleAspectFill
        imagePreview.accessibilityIdentifier = "imagePreview"
        contentView.addSubview(imagePreview)
        
        constrain(contentView, imagePreview) { contentView, imagePreview in
            imagePreview.width == imagePreview.height
            imagePreview.height == 24
            imagePreview.trailing == contentView.trailing - 16
            imagePreview.centerY == contentView.centerY
        }
        
        separatorLine.backgroundColor = UIColor(white: 1.0, alpha: 0.08)
        separatorLine.isAccessibilityElement = false
        addSubview(separatorLine)
        
        constrain(self, separatorLine, cellNameLabel) { selfView, separatorLine, cellNameLabel in
            separatorLine.leading == cellNameLabel.leading
            separatorLine.trailing == selfView.trailing
            separatorLine.bottom == selfView.bottom
            separatorLine.height == .hairline
        }
        
        topSeparatorLine.backgroundColor = UIColor(white: 1.0, alpha: 0.08)
        topSeparatorLine.isAccessibilityElement = false
        addSubview(topSeparatorLine)
        
        constrain(self, topSeparatorLine, cellNameLabel) { selfView, topSeparatorLine, cellNameLabel in
            topSeparatorLine.leading == cellNameLabel.leading
            topSeparatorLine.trailing == selfView.trailing
            topSeparatorLine.top == selfView.top
            topSeparatorLine.height == .hairline
        }

        contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 56).isActive = true
        variant = .none
    }
    
    func setupAccessibiltyElements() {
        var currentElements = accessibilityElements ?? []
        currentElements.append(contentsOf: [cellNameLabel, valueLabel, imagePreview])
        accessibilityElements = currentElements
    }
    
    func updateBackgroundColor() {
        if let _ = cellColor {
            return
        }
        
        if isHighlighted && selectionStyle != .none {
            backgroundColor = UIColor(white: 0, alpha: 0.2)
            badge.backgroundColor = UIColor.white
            badgeLabel.textColor = UIColor.black
        }
        else {
            backgroundColor = UIColor.clear
        }
    }
}

@objcMembers class SettingsGroupCell: SettingsTableCell {
    override func setup() {
        super.setup()
        accessoryType = .disclosureIndicator
    }
}

@objcMembers class SettingsButtonCell: SettingsTableCell {
    override func setup() {
        super.setup()
        cellNameLabel.textColor = UIColor.accent()
    }
}

@objcMembers class SettingsToggleCell: SettingsTableCell {
    var switchView: UISwitch!
    
    override func setup() {
        super.setup()
        
        selectionStyle = .none
        shouldGroupAccessibilityChildren = false
        switchView = UISwitch(frame: CGRect.zero)
        switchView.addTarget(self, action: #selector(SettingsToggleCell.onSwitchChanged(_:)), for: .valueChanged)
        accessoryView = switchView
        switchView.isAccessibilityElement = true
        
        accessibilityElements = [cellNameLabel, switchView]
    }
    
    @objc func onSwitchChanged(_ sender: UIResponder) {
        descriptor?.select(SettingsPropertyValue(switchView.isOn))
    }
}

@objcMembers class SettingsValueCell: SettingsTableCell {
    override var descriptor: SettingsCellDescriptorType?{
        willSet {
            if let propertyDescriptor = descriptor as? SettingsPropertyCellDescriptorType {
                NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: propertyDescriptor.settingsProperty.propertyName.changeNotificationName), object: nil)
            }
        }
        didSet {
            if let propertyDescriptor = descriptor as? SettingsPropertyCellDescriptorType {
                NotificationCenter.default.addObserver(self, selector: #selector(SettingsValueCell.onPropertyChanged(_:)), name: NSNotification.Name(rawValue: propertyDescriptor.settingsProperty.propertyName.changeNotificationName), object: nil)
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Properties observing
    
    @objc func onPropertyChanged(_ notification: Notification) {
        descriptor?.featureCell(self)
    }
}

@objcMembers class SettingsTextCell: SettingsTableCell, UITextFieldDelegate {
    var textInput: UITextField!

    override func setup() {
        super.setup()
        selectionStyle = .none
        
        textInput = TailEditingTextField(frame: CGRect.zero)
        textInput.delegate = self
        textInput.textAlignment = .right
        textInput.textColor = UIColor.lightGray
        textInput.setContentCompressionResistancePriority(UILayoutPriority.defaultLow, for: .horizontal)

        contentView.addSubview(textInput)

        createConstraints()

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(onCellSelected(_:)))
        contentView.addGestureRecognizer(tapGestureRecognizer)
    }

    func createConstraints(){
        let textInputSpacing = CGFloat(16)

        let trailingBoundaryView = accessoryView ?? contentView
        constrain(contentView, textInput, trailingBoundaryView) { contentView, textInput, trailingBoundaryView in
            textInput.top == contentView.top - 8
            textInput.bottom == contentView.bottom + 8
            textInput.trailing == trailingBoundaryView.trailing - textInputSpacing
        }

        NSLayoutConstraint.activate([
            cellNameLabel.trailingAnchor.constraint(equalTo: textInput.leadingAnchor, constant: -textInputSpacing)
        ])

    }
    
    override func setupAccessibiltyElements() {
        super.setupAccessibiltyElements()
        
        var currentElements = accessibilityElements ?? []
        currentElements.append(contentsOf: [textInput!])
        accessibilityElements = currentElements
    }
    
    @objc public func onCellSelected(_ sender: AnyObject!) {
        if !textInput.isFirstResponder {
            textInput.becomeFirstResponder()
        }
    }
    
    // MARK: - UITextFieldDelegate
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string.rangeOfCharacter(from: CharacterSet.newlines) != .none {
            textField.resignFirstResponder()
            return false
        }
        else {
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

class SettingsStaticTextTableCell: SettingsTableCell {

    override func setup() {
        super.setup()
        cellNameLabel.numberOfLines = 0
        cellNameLabel.textAlignment = .justified
    }

}
