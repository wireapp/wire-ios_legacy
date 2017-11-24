//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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

private let settingsChangeEvent = "settings.changed_value"
private let settingsChangeEventPropertyName = "property"
private let settingsChangeEventPropertyValue = "new_value"

extension Analytics {
    
    internal func tagSettingsChanged(for propertyName: SettingsPropertyName, to value: SettingsPropertyValue) {
        guard let value = value.value(),
              propertyName != SettingsPropertyName.lockAppLastDate &&
                propertyName != SettingsPropertyName.disableCrashAndAnalyticsSharing else {
            return
        }
        let attributes = [settingsChangeEventPropertyName: propertyName,
                          settingsChangeEventPropertyValue: value]
        tagEvent(settingsChangeEvent, attributes: attributes)
    }
    
    func tagOpenManageTeamURL() {
        self.tagEvent("settings.opened_manage_team")
    }
}
