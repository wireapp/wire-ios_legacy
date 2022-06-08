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
        return L10n.Localizable.Self.Settings.SoundMenu.title
    }

    private var soundAlertProperty: SettingsProperty {
        return settingsPropertyFactory.property(.soundAlerts)
    }

    private var alertsSection: SettingsSectionDescriptorType {
        let property = soundAlertProperty

        let allAlerts = SettingsPropertySelectValueCellDescriptor(
            settingsProperty: property,
            value: SettingsPropertyValue(AVSIntensityLevel.full.rawValue),
            title: L10n.Localizable.Self.Settings.SoundMenu.AllSounds.title
        )

        let someAlerts = SettingsPropertySelectValueCellDescriptor(
            settingsProperty: property,
            value: SettingsPropertyValue(AVSIntensityLevel.some.rawValue),
            title: L10n.Localizable.Self.Settings.SoundMenu.MuteWhileTalking.title
        )

        let noneAlerts = SettingsPropertySelectValueCellDescriptor(
            settingsProperty: property,
            value: SettingsPropertyValue(AVSIntensityLevel.none.rawValue),
            title: L10n.Localizable.Self.Settings.SoundMenu.NoSounds.title
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
                return .text(L10n.Localizable.Self.Settings.SoundMenu.AllSounds.title)
            case .some:
                return .text(L10n.Localizable.Self.Settings.SoundMenu.MuteWhileTalking.title)
            case .none:
                return .text(L10n.Localizable.Self.Settings.SoundMenu.NoSounds.title)
            @unknown default:
                // TODO: change AVSIntensityLevel to NS_CLOSED_ENUM
                return .text("")
            }
        } as PreviewGeneratorType
    }
}
