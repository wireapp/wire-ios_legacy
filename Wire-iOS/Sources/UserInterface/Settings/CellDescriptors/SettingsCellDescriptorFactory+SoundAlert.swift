//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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
import avs

extension SettingsCellDescriptorFactory {

    var soundAlertGroup: SettingsCellDescriptorType {
        return SettingsGroupCellDescriptor(
            items: [alertsSection],
            title: title,
            identifier: .none,
            previewGenerator: alertPreviewGenerator
        )
    }

    private var title: String {
        return "self.settings.sound_menu.title".localized
    }

    private var soundAlertProperty: SettingsProperty {
        return settingsPropertyFactory.property(.soundAlerts)
    }

    private var alertsSection: SettingsSectionDescriptorType {
        let property = soundAlertProperty

        let allAlerts = SettingsPropertySelectValueCellDescriptor(
            settingsProperty: property,
            value: SettingsPropertyValue(AVSIntensityLevel.full.rawValue),
            title: "self.settings.sound_menu.all_sounds.title".localized
        )

        let someAlerts = SettingsPropertySelectValueCellDescriptor(
            settingsProperty: property,
            value: SettingsPropertyValue(AVSIntensityLevel.some.rawValue),
            title: "self.settings.sound_menu.mute_while_talking.title".localized
        )

        let noneAlerts = SettingsPropertySelectValueCellDescriptor(
            settingsProperty: property,
            value: SettingsPropertyValue(AVSIntensityLevel.none.rawValue),
            title: "self.settings.sound_menu.no_sounds.title".localized
        )

        return SettingsSectionDescriptor(
            cellDescriptors: [allAlerts, someAlerts, noneAlerts],
            header: title,
            footer: .none
        )
    }

    private var alertPreviewGenerator: PreviewGeneratorType {
        return {
            guard
                let rawValue = self.soundAlertProperty.value().value() as? NSNumber,
                let intensityLevel = AVSIntensityLevel(rawValue: rawValue.uintValue)
            else {
                return .text($0.title)
            }

            switch intensityLevel {
            case .full:
                return .text("self.settings.sound_menu.all_sounds.title".localized)
            case .some:
                return .text("self.settings.sound_menu.mute_while_talking.title".localized)
            case .none:
                return .text("self.settings.sound_menu.no_sounds.title".localized)
            @unknown default:
                ///TODO: change AVSIntensityLevel to NS_CLOSED_ENUM
                return .text("")
            }
        } as PreviewGeneratorType
    }
}
