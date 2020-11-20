//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

extension SettingsCellDescriptorFactory {
    func dataUsagePermissionsGroup(isTeamMember: Bool) -> SettingsCellDescriptorType {
        
        let sendCrashData = SettingsPropertyToggleCellDescriptor(settingsProperty: settingsPropertyFactory.property(.disableCrashSharing), inverse: true)
        let sendCrashDataSection = SettingsSectionDescriptor(cellDescriptors: [sendCrashData], footer: "self.settings.privacy_crash_menu.description.title".localized)

        var items: [SettingsSectionDescriptor] = [sendCrashDataSection]

        //show analytics toggle for team members only
        if isTeamMember {
            let sendAnalyticsData = SettingsPropertyToggleCellDescriptor(settingsProperty: settingsPropertyFactory.property(.disableAnalyticsSharing), inverse: true)
            let sendAnalyticsDataSection = SettingsSectionDescriptor(cellDescriptors: [sendAnalyticsData], footer: "self.settings.privacy_analytics_menu.description.title".localized)
            
            items.append(sendAnalyticsDataSection)
        }

        let receiveNewsAndOffersData = SettingsPropertyToggleCellDescriptor(settingsProperty: settingsPropertyFactory.property(.receiveNewsAndOffers))
        let receiveNewsAndOffersSection = SettingsSectionDescriptor(cellDescriptors: [receiveNewsAndOffersData], footer: "self.settings.receiveNews_and_offers.description.title".localized)

        items.append(receiveNewsAndOffersSection)

        return SettingsGroupCellDescriptor(
            items: items,
            title: "self.settings.account.data_usage_permissions.title".localized
        )
    }
}
