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
    case saveMessage
    case profileCameraRoll
    case gifAction
    case externalFilePicker
    case generateLinkPreviews
    case forceConstantBitRateCalls
    case openFilePreview
    case customBackend
    
    var bundleKey: String {
        switch self {
        case .clipboard:
            return "ClipboardEnabled"
        case .saveMessage:
            return "SaveMessageEnabled"
        case .profileCameraRoll:
            return "ProfileCameraRollEnabled"
        case .gifAction:
            return "FileGifActionEnabled"
        case .externalFilePicker:
            return "ExternalFilePickerEnabled"
        case .generateLinkPreviews:
            return "GenerateLinkPreviewEnabled"
        case .forceConstantBitRateCalls:
            return "ForceCBREnabled"
        case .openFilePreview:
            return "OpenFilePreviewEnabled"
        case .customBackend:
            return "CustomBackendEnabled"
        }
    }
    
    var isEnabled: Bool {
        return Bundle.appMainBundle.infoForKey(bundleKey) == "1"
    }
}
