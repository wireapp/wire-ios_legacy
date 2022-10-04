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
import WireSystem
import UIKit

private let zmLog = ZMSLog(tag: "UI")

final class SettingsPropertySelectValueCellDescriptor: SettingsPropertyCellDescriptorType {
    static let cellType: SettingsTableCellProtocol.Type = SettingsValueCell.self
    let value: SettingsPropertyValue
    let title: String
    let identifier: String?

    typealias SelectActionType = (SettingsPropertySelectValueCellDescriptor) -> Void
    let selectAction: SelectActionType?
    let backgroundColor: UIColor?
    var visible: Bool = true

    weak var group: SettingsGroupCellDescriptorType?
    var settingsProperty: SettingsProperty

    init(settingsProperty: SettingsProperty, value: SettingsPropertyValue, title: String, identifier: String? = .none, selectAction: SelectActionType? = .none, backgroundColor: UIColor? = .none) {
        self.settingsProperty = settingsProperty
        self.value = value
        self.title = title
        self.identifier = identifier
        self.selectAction = selectAction
        self.backgroundColor = backgroundColor
    }

    func featureCell(_ cell: SettingsCellType) {
        cell.titleText = self.title
        if let valueCell = cell as? SettingsValueCell {
            valueCell.accessoryType = self.settingsProperty.value() == self.value ? .checkmark : .none
        }
    }

    func select(_ value: SettingsPropertyValue?) {
        do {
            try settingsProperty.set(newValue: self.value)
        } catch {
            zmLog.error("Cannot set property: \(error)")
        }

        selectAction?(self)
    }
}
