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

enum SecurityFlags {
    case clipboard
    case generateLinkPreviews
    case forceConstantBitRateCalls
    case customBackend
    case cameraRoll
    case backup
    case federation
    case maxNumberAccounts

    /// Whether encryption at rest is enabled and can't be disabled.

    case forceEncryptionAtRest

    var bundleKey: String {
        switch self {
        case .maxNumberAccounts:
            return "MaxNumberAccounts"
        case .clipboard:
            return "ClipboardEnabled"
        case .generateLinkPreviews:
            return "GenerateLinkPreviewEnabled"
        case .forceConstantBitRateCalls:
            return "ForceCBREnabled"
        case .customBackend:
            return "CustomBackendEnabled"
        case .cameraRoll:
            return "CameraRollEnabled"
        case .backup:
            return "BackupEnabled"
        case .forceEncryptionAtRest:
            return "ForceEncryptionAtRestEnabled"
        case .federation:
            return "FederationEnabled"
        }
    }

    var intValue: Int? {
        guard let string = Bundle.appMainBundle.infoForKey(bundleKey) else {
            return nil
        }

        return Int(string)
    }

    var isEnabled: Bool {
        return Bundle.appMainBundle.infoForKey(bundleKey) == "1"
    }
}
