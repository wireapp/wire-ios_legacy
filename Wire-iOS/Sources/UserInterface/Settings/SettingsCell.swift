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
    case None
    case Text(String)
    case Image(UIImage)
    case Color(UIColor)
}

protocol SettingsCellType: class {
    var titleText: String {get set}
    var preview: SettingsCellPreview {get set}
    var titleColor: UIColor {get set}
    var cellColor: UIColor? {get set}
    var descriptor: SettingsCellDescriptorType? {get set}
    var icon: ZetaIconType {get set}
}

class SettingsTableCell: UITableViewCell, SettingsCellType {
    var iconImageView = UIImageView()
    var cellNameLabel = UILabel()
    var valueLabel = UILabel()
    var imagePreview = UIImageView()
    var cellNameLabelToIconInset: NSLayoutConstraint!
    
    var titleText: String = "" {
        didSet {
            self.cellNameLabel.text = self.titleText
        }
    }
    
    var preview: SettingsCellPreview = .None {
        didSet {
            
            switch self.preview {
            case .Text(let string):
                self.valueLabel.text = string
                self.imagePreview.image = .None
                self.imagePreview.backgroundColor = UIColor.clearColor()

            case .Image(let image):
                self.valueLabel.text = ""
                self.imagePreview.image = image
                self.imagePreview.backgroundColor = UIColor.clearColor()
                
            case .Color(let color):
                self.valueLabel.text = ""
                self.imagePreview.image = .None
                self.imagePreview.backgroundColor = color
                
            case .None:
                self.valueLabel.text = ""
                self.imagePreview.image = .None
                self.imagePreview.backgroundColor = UIColor.clearColor()
            }
        }
    }
    
    var icon: ZetaIconType = .None {
        didSet {
            if icon == .None {
                self.iconImageView.image = .None
                self.cellNameLabelToIconInset.active = false
            }
            else {
                self.iconImageView.image = UIImage(forIcon: icon, iconSize: .Tiny, color: .whiteColor())
                self.cellNameLabelToIconInset.active = true
            }
        }
    }
    
    var titleColor: UIColor = UIColor.whiteColor() {
        didSet {
            self.cellNameLabel.textColor = self.titleColor
        }
    }
    
    var cellColor: UIColor? {
        didSet {
            self.backgroundColor = self.cellColor
        }
    }
    
    var descriptor: SettingsCellDescriptorType?
    
    override var reuseIdentifier: String {
        get {
            return self.dynamicType.reuseIdentifier
        }
    }
    
    static var reuseIdentifier: String {
        return "\(self)" + "ReuseIdentifier"
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }
    
    func setup() {
        self.backgroundColor = .clearColor()
        self.backgroundView = UIView()
        self.selectedBackgroundView = UIView()
        
        self.iconImageView.contentMode = .Center
        self.contentView.addSubview(self.iconImageView)
        
        constrain(self.contentView, self.iconImageView) { contentView, iconImageView in
            iconImageView.left == contentView.left + 24
            iconImageView.width == 16
            iconImageView.height == iconImageView.height
            iconImageView.centerY == contentView.centerY
        }
        
        self.cellNameLabel.font = UIFont.systemFontOfSize(17)
        self.cellNameLabel.translatesAutoresizingMaskIntoConstraints = false
        self.cellNameLabel.setContentHuggingPriority(UILayoutPriorityRequired, forAxis: .Horizontal)
        self.cellNameLabel.textColor = .whiteColor()
        self.contentView.addSubview(self.cellNameLabel)
        
        constrain(self.contentView, self.cellNameLabel, self.iconImageView) { contentView, cellNameLabel, iconImageView in
            self.cellNameLabelToIconInset = cellNameLabel.left == iconImageView.right + 24
            cellNameLabel.left == contentView.left + 16 ~ 750
            cellNameLabel.top == contentView.top + 12
            cellNameLabel.bottom == contentView.bottom - 12
        }
        
        self.cellNameLabelToIconInset.active = false
        
        self.valueLabel.textColor = .lightGrayColor()
        self.valueLabel.font = UIFont.systemFontOfSize(17)
        self.valueLabel.translatesAutoresizingMaskIntoConstraints = false
        self.valueLabel.textAlignment = .Right
        
        self.contentView.addSubview(self.valueLabel)
        
        constrain(self.contentView, self.cellNameLabel, self.valueLabel) { contentView, cellNameLabel, valueLabel in
            valueLabel.top == contentView.top - 8
            valueLabel.bottom == contentView.bottom + 8
            valueLabel.left == cellNameLabel.right + 8
            valueLabel.right == contentView.right - 16
        }
        
        self.imagePreview.clipsToBounds = true
        self.imagePreview.layer.cornerRadius = 12
        self.imagePreview.contentMode = .ScaleAspectFill
        self.contentView.addSubview(self.imagePreview)
        
        constrain(self.contentView, self.imagePreview) { contentView, imagePreview in
            imagePreview.width == imagePreview.height
            imagePreview.height == 24
            imagePreview.right == contentView.right - 16
            imagePreview.centerY == contentView.centerY
        }
        
    }
}

class SettingsGroupCell: SettingsTableCell {
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }
    
    override func setup() {
        super.setup()
        self.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
    }
}

class SettingsButtonCell: SettingsTableCell {
    override func setup() {
        super.setup()
        self.cellNameLabel.textColor = UIColor.accentColor()
    }
}

class SettingsToggleCell: SettingsTableCell {
    var switchView: UISwitch!
    
    override func setup() {
        super.setup()
        
        self.selectionStyle = .None
        
        self.switchView = UISwitch(frame: CGRectZero)
        self.switchView.addTarget(self, action: #selector(SettingsToggleCell.onSwitchChanged(_:)), forControlEvents: .ValueChanged)
        self.accessoryView = self.switchView
    }
    
    func onSwitchChanged(sender: UIResponder) {
        self.descriptor?.select(SettingsPropertyValue.Bool(value: self.switchView.on))
    }
}

class SettingsValueCell: SettingsTableCell {
    override var descriptor: SettingsCellDescriptorType?{
        willSet {
            if let propertyDescriptor = self.descriptor as? SettingsPropertyCellDescriptorType {
                NSNotificationCenter.defaultCenter().removeObserver(self, name: propertyDescriptor.settingsProperty.propertyName.changeNotificationName, object: nil)
            }
        }
        didSet {
            if let propertyDescriptor = self.descriptor as? SettingsPropertyCellDescriptorType {
                NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SettingsValueCell.onPropertyChanged(_:)), name: propertyDescriptor.settingsProperty.propertyName.changeNotificationName, object: nil)
            }
        }
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // MARK: - Properties observing
    
    func onPropertyChanged(notification: NSNotification) {
        self.descriptor?.featureCell(self)
    }
}

class SettingsTextCell: SettingsTableCell, UITextFieldDelegate {
    var textInput: UITextField!

    override func setup() {
        super.setup()
        self.selectionStyle = .None
        
        self.textInput = TailEditingTextField(frame: CGRectZero)
        self.textInput.translatesAutoresizingMaskIntoConstraints = false
        self.textInput.delegate = self
        self.textInput.textAlignment = .Right
        self.textInput.textColor = .lightGrayColor()
        self.contentView.addSubview(self.textInput)
        
        constrain(self.contentView, self.cellNameLabel, self.textInput) { contentView, cellNameLabel, textInput in
            textInput.top == contentView.top - 8
            textInput.bottom == contentView.bottom + 8
            textInput.left == cellNameLabel.right + 8
            textInput.right == contentView.right - 16
        }
    }
    
    // MARK: - UITextFieldDelegate
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        if string.rangeOfCharacterFromSet(NSCharacterSet.newlineCharacterSet()) != .None {
            textField.resignFirstResponder()
            return false
        }
        else {
            return true
        }
    }
    
    func textFieldShouldEndEditing(textField: UITextField) -> Bool {
        return true
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        if let text = self.textInput.text {
            self.descriptor?.select(SettingsPropertyValue.String(value: text))
        }
    }
}
