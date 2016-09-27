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


import Foundation
import CocoaLumberjackSwift

/**
 * @abstract Generates the cell that displays toggle control
 */
class SettingsPropertyToggleCellDescriptor: SettingsPropertyCellDescriptorType {
    static let cellType: SettingsTableCell.Type = SettingsToggleCell.self
    let inverse: Bool
    var title: String {
        get {
            return SettingsPropertyLabelText(self.settingsProperty.propertyName)
        }
    }
    let identifier: String?
    var visible: Bool = true
    weak var group: SettingsGroupCellDescriptorType?
    var settingsProperty: SettingsProperty
    
    init(settingsProperty: SettingsProperty, inverse: Bool = false, identifier: String? = .none) {
        self.settingsProperty = settingsProperty
        self.inverse = inverse
        self.identifier = identifier
    }
    
    func featureCell(_ cell: SettingsCellType) {
        cell.titleText = self.title
        if let toggleCell = cell as? SettingsToggleCell {
            var boolValue = false
            if let value = self.settingsProperty.value().value() as? Int {
                boolValue = value > 0
            }
            else {
                boolValue = false
            }
            
            if self.inverse {
                boolValue = !boolValue
            }
            
            toggleCell.switchView.isOn = boolValue
        }
    }
    
    func select(_ value: SettingsPropertyValue?) {
        var valueToSet = false
        
        if let intValue = value?.value() as? Int {
            valueToSet = intValue > 0
        }
        else if let boolValue = value?.value() as? Bool {
            valueToSet = boolValue
        }
        
        if self.inverse {
            valueToSet = !valueToSet
        }
        
        do {
            try self.settingsProperty << SettingsPropertyValue.bool(value: valueToSet)
        }
        catch(let e) {
            DDLogError("Cannot set property: \(e)")
        }
    }
}
