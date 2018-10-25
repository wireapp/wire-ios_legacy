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
import WireUtilities

private let zmLog = ZMSLog(tag: "UI")

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

                // specific error message for name string is too short
                if error.domain == ZMObjectValidationErrorDomain &&
                    error.code == ZMManagedObjectValidationErrorCode.objectValidationErrorCodeStringTooShort.rawValue {
                    UIApplication.shared.wr_topmostController(onlyFullScreen: false)?.showAlert(forMessage: "name.guidance.tooshort".localized)
                } else {
                    UIApplication.shared.wr_topmostController(onlyFullScreen: false)?.showAlert(forError: error)
                }

            }
            catch let generalError {
                zmLog.error("Error setting property: \(generalError)")
            }
        }
    }
}
