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

class SettingsPropertyTextValueCellDescriptor: SettingsPropertyCellDescriptorType {
    static let cellType: SettingsTableCell.Type = SettingsTextCell.self
    var title: String {
        get {
            return SettingsPropertyLabelText(self.settingsProperty.propertyName)
        }
    }
    var visible: Bool = true
    let identifier: String?
    weak var group: SettingsGroupCellDescriptorType?
    var settingsProperty: SettingsProperty
    
    init(settingsProperty: SettingsProperty, identifier: String? = .none) {
        self.settingsProperty = settingsProperty
        self.identifier = identifier
    }
    
    func featureCell(_ cell: SettingsCellType) {
        cell.titleText = self.title
        if let textCell = cell as? SettingsTextCell,
            let stringValue = self.settingsProperty.rawValue() as? String {
                textCell.textInput.text = stringValue
        }
    }
    
    func select(_ value: SettingsPropertyValue?) {
        if let stringValue = value?.value() as? String {
            
            do {
                try self.settingsProperty << SettingsPropertyValue.string(value: stringValue)
            }
            catch let error as NSError {
                let alertView = UIAlertController(title: "error.full_name".localized, message: error.localizedDescription, preferredStyle: .alert)
                let actionCancel = UIAlertAction(title: "general.cancel".localized, style: .cancel, handler: nil)
                alertView.addAction(actionCancel)
                UIApplication.shared.wr_topmostController(onlyFullScreen: false)?.present(alertView, animated: true, completion: .none)
                
            }
            catch let generalError {
                DDLogError("Error setting property: \(generalError)")
            }
        }
    }
}
