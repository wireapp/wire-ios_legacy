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

@objc class SettingsTableCell: UITableViewCell, SettingsCellType, Reusable {
    let iconImageView = UIImageView()
    public let cellNameLabel = UILabel()
    let valueLabel = UILabel()
    let badge = RoundedBadge(view: UIView())
    var badgeLabel = UILabel()
    let imagePreview = UIImageView()
    let separatorLine = UIView()
    let topSeparatorLine = UIView()
    var cellNameLabelToIconInset: NSLayoutConstraint!
    
    var titleText: String = "" {
        didSet {
            self.cellNameLabel.text = self.titleText
        }
    }
    
    var preview: SettingsCellPreview = .none {
        didSet {
            switch self.preview {
            case .text(let string):
                self.valueLabel.text = string
                self.badgeLabel.text = ""
                self.badge.isHidden = true
                self.imagePreview.image = .none
                self.imagePreview.backgroundColor = UIColor.clear
                self.imagePreview.accessibilityValue = nil
                self.imagePreview.isAccessibilityElement = false
                
            case .badge(let value):
                self.valueLabel.text = ""
                self.badgeLabel.text = "\(value)"
                self.badge.isHidden = false
                self.imagePreview.image = .none
                self.imagePreview.backgroundColor = UIColor.clear
                self.imagePreview.accessibilityValue = nil
                self.imagePreview.isAccessibilityElement = false
                
            case .image(let image):
                self.valueLabel.text = ""
                self.badgeLabel.text = ""
                self.badge.isHidden = true
                self.imagePreview.image = image
                self.imagePreview.backgroundColor = UIColor.clear
                self.imagePreview.accessibilityValue = "image"
                self.imagePreview.isAccessibilityElement = true
                
            case .color(let color):
                self.valueLabel.text = ""
                self.badgeLabel.text = ""
                self.badge.isHidden = true
                self.imagePreview.image = .none
                self.imagePreview.backgroundColor = color
                self.imagePreview.accessibilityValue = "color"
                self.imagePreview.isAccessibilityElement = true
                
            case .none:
                self.valueLabel.text = ""
                self.badgeLabel.text = ""
                self.badge.isHidden = true
                self.imagePreview.image = .none
                self.imagePreview.backgroundColor = UIColor.clear
                self.imagePreview.accessibilityValue = nil
                self.imagePreview.isAccessibilityElement = false
            }
        }
    }
    
    var icon: ZetaIconType = .none {
        didSet {
            if icon == .none {
                self.iconImageView.image = .none
                self.cellNameLabelToIconInset.isActive = false
            }
            else {
                self.iconImageView.image = UIImage(for: icon, iconSize: .tiny, color: UIColor.white)
                self.cellNameLabelToIconInset.isActive = true
            }
        }
    }
    
    var isFirst: Bool = false {
        didSet {
            self.topSeparatorLine.isHidden = !isFirst
        }
    }
    
    var titleColor: UIColor = UIColor.white {
        didSet {
            self.cellNameLabel.textColor = self.titleColor
        }
    }
    
    var cellColor: UIColor? {
        didSet {
            self.backgroundColor = self.cellColor
        }
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        self.updateBackgroundColor()
    }
    
    var descriptor: SettingsCellDescriptorType?
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setup()
        self.setupAccessibiltyElements()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
        self.setupAccessibiltyElements()
    }
    
    func setup() {
        self.backgroundColor = UIColor.clear
        self.backgroundView = UIView()
        self.selectedBackgroundView = UIView()
        
        self.iconImageView.contentMode = .center
        self.contentView.addSubview(self.iconImageView)
        
        constrain(self.contentView, self.iconImageView) { contentView, iconImageView in
            iconImageView.leading == contentView.leading + 24
            iconImageView.width == 16
            iconImageView.height == iconImageView.height
            iconImageView.centerY == contentView.centerY
        }
        
        self.cellNameLabel.setContentHuggingPriority(UILayoutPriorityRequired, for: .horizontal)
        self.contentView.addSubview(self.cellNameLabel)
        
        constrain(self.contentView, self.cellNameLabel, self.iconImageView) { contentView, cellNameLabel, iconImageView in
            self.cellNameLabelToIconInset = cellNameLabel.leading == iconImageView.trailing + 24
            cellNameLabel.leading == contentView.leading + 16 ~ LayoutPriority(750)
            cellNameLabel.top == contentView.top + 12
            cellNameLabel.bottom == contentView.bottom - 12
        }
        
        self.cellNameLabelToIconInset.isActive = false
        
        self.valueLabel.textColor = UIColor.lightGray
        self.valueLabel.font = UIFont.systemFont(ofSize: 17)
        self.valueLabel.textAlignment = .right
        
        self.contentView.addSubview(self.valueLabel)

        self.badgeLabel.font = FontSpec(.small, .medium).font
        self.badgeLabel.textAlignment = .center
        self.badgeLabel.textColor = UIColor.black
        
        self.badge.containedView.addSubview(self.badgeLabel)
        
        self.badge.backgroundColor = UIColor.white
        self.badge.isHidden = true
        self.contentView.addSubview(self.badge)
        
        let trailingBoundaryView = accessoryView ?? contentView

        constrain(self.contentView, self.cellNameLabel, self.valueLabel, trailingBoundaryView, self.badge) { contentView, cellNameLabel, valueLabel, trailingBoundaryView, badge in
            valueLabel.top == contentView.top - 8
            valueLabel.bottom == contentView.bottom + 8
            valueLabel.leading >= cellNameLabel.trailing + 8
            valueLabel.trailing == trailingBoundaryView.trailing - 16
            badge.center == valueLabel.center
            badge.height == 20
            badge.width >= 28
        }
        
        constrain(self.badge, self.badgeLabel) { badge, badgeLabel in
            badgeLabel.leading == badge.leading + 6
            badgeLabel.trailing == badge.trailing - 6
            badgeLabel.top == badge.top
            badgeLabel.bottom == badge.bottom
        }
        
        self.imagePreview.clipsToBounds = true
        self.imagePreview.layer.cornerRadius = 12
        self.imagePreview.contentMode = .scaleAspectFill
        self.imagePreview.accessibilityIdentifier = "imagePreview"
        self.contentView.addSubview(self.imagePreview)
        
        constrain(self.contentView, self.imagePreview) { contentView, imagePreview in
            imagePreview.width == imagePreview.height
            imagePreview.height == 24
            imagePreview.trailing == contentView.trailing - 16
            imagePreview.centerY == contentView.centerY
        }
        
        self.separatorLine.backgroundColor = UIColor(white: 1.0, alpha: 0.08)
        self.addSubview(self.separatorLine)
        
        constrain(self, self.separatorLine, self.cellNameLabel) { selfView, separatorLine, cellNameLabel in
            separatorLine.leading == cellNameLabel.leading
            separatorLine.trailing == selfView.trailing
            separatorLine.bottom == selfView.bottom
            separatorLine.height == .hairline
        }
        
        self.topSeparatorLine.backgroundColor = UIColor(white: 1.0, alpha: 0.08)
        self.addSubview(self.topSeparatorLine)
        
        constrain(self, self.topSeparatorLine, self.cellNameLabel) { selfView, topSeparatorLine, cellNameLabel in
            topSeparatorLine.leading == cellNameLabel.leading
            topSeparatorLine.trailing == selfView.trailing
            topSeparatorLine.top == selfView.top
            topSeparatorLine.height == .hairline
        }
    }
    
    func setupAccessibiltyElements() {
        var currentElements = self.accessibilityElements ?? []
        currentElements.append(contentsOf: [cellNameLabel, valueLabel, imagePreview])
        self.accessibilityElements = currentElements
    }
    
    func updateBackgroundColor() {
        if let _ = cellColor {
            return
        }
        
        if self.isHighlighted && self.selectionStyle != .none {
            self.backgroundColor = UIColor(white: 0, alpha: 0.2)
            self.badge.backgroundColor = UIColor.white
            self.badgeLabel.textColor = UIColor.black
        }
        else {
            self.backgroundColor = UIColor.clear
        }
    }
}

@objc class SettingsGroupCell: SettingsTableCell {
    override func setup() {
        super.setup()
        self.accessoryType = UITableViewCellAccessoryType.disclosureIndicator
    }
}

@objc class SettingsButtonCell: SettingsTableCell {
    override func setup() {
        super.setup()
        self.cellNameLabel.textColor = UIColor.accent()
    }
}

@objc class SettingsToggleCell: SettingsTableCell {
    var switchView: UISwitch!
    
    override func setup() {
        super.setup()
        
        self.selectionStyle = .none
        self.shouldGroupAccessibilityChildren = false
        self.switchView = UISwitch(frame: CGRect.zero)
        self.switchView.addTarget(self, action: #selector(SettingsToggleCell.onSwitchChanged(_:)), for: .valueChanged)
        self.accessoryView = self.switchView
        self.switchView.isAccessibilityElement = true
        
        self.accessibilityElements = [self.cellNameLabel, self.switchView]
    }
    
    func onSwitchChanged(_ sender: UIResponder) {
        self.descriptor?.select(SettingsPropertyValue(self.switchView.isOn))
    }
}

@objc class SettingsValueCell: SettingsTableCell {
    override var descriptor: SettingsCellDescriptorType?{
        willSet {
            if let propertyDescriptor = self.descriptor as? SettingsPropertyCellDescriptorType {
                NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: propertyDescriptor.settingsProperty.propertyName.changeNotificationName), object: nil)
            }
        }
        didSet {
            if let propertyDescriptor = self.descriptor as? SettingsPropertyCellDescriptorType {
                NotificationCenter.default.addObserver(self, selector: #selector(SettingsValueCell.onPropertyChanged(_:)), name: NSNotification.Name(rawValue: propertyDescriptor.settingsProperty.propertyName.changeNotificationName), object: nil)
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Properties observing
    
    func onPropertyChanged(_ notification: Notification) {
        self.descriptor?.featureCell(self)
    }
}

@objc class SettingsTextCell: SettingsTableCell, UITextFieldDelegate {
    var textInput: UITextField!

    override func setup() {
        super.setup()
        self.selectionStyle = .none
        
        self.textInput = TailEditingTextField(frame: CGRect.zero)
        self.textInput.delegate = self
        self.textInput.textAlignment = .right
        self.textInput.textColor = UIColor.lightGray
        self.contentView.addSubview(self.textInput)

        let trailingBoundaryView = accessoryView ?? contentView
        constrain(self.contentView, self.textInput, trailingBoundaryView) { contentView, textInput, trailingBoundaryView in
            textInput.top == contentView.top - 8
            textInput.bottom == contentView.bottom + 8
            textInput.trailing == trailingBoundaryView.trailing - 16
        }
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(onCellSelected(_:)))
        self.contentView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    override func setupAccessibiltyElements() {
        super.setupAccessibiltyElements()
        
        var currentElements = self.accessibilityElements ?? []
        currentElements.append(contentsOf: [textInput])
        self.accessibilityElements = currentElements
    }
    
    @objc public func onCellSelected(_ sender: AnyObject!) {
        if !self.textInput.isFirstResponder {
            self.textInput.becomeFirstResponder()
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
        if let text = self.textInput.text {
            self.descriptor?.select(SettingsPropertyValue.string(value: text))
        }
    }
}
