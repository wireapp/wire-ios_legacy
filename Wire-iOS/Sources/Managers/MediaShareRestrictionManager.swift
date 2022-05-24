//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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
import WireSyncEngine

enum ShareableMediaSource: CaseIterable {
    case camera
    case photoLibrary
    case sketch
    case gif
    case audioRecording
    case shareExtension
    case clipboard
}

enum MediaShareRestrictionLevel {
    case none
    case securityFlag
    case APIFlag
}

class MediaShareRestrictionManager {
    private let securityFlagRestrictedTypes: [ShareableMediaSource] = [.photoLibrary, .shareExtension, .clipboard]
    
    var mediaShareRestrictionLevel: MediaShareRestrictionLevel {
        if let session = ZMUserSession.shared(), session.fileSharingFeature.status == .disabled {
            return .APIFlag
        }
        if SecurityFlags.fileSharing.isEnabled {
            return .none
        }
        return .securityFlag
    }
    
    func canUploadMedia(from source: ShareableMediaSource) -> Bool {
        switch mediaShareRestrictionLevel {
        case .none:
            return true
        case .securityFlag:
            return securityFlagRestrictedTypes.contains(source)
        case .APIFlag:
            return false
        }
    }
    
    func canDownloadMedia() -> Bool {
        return  SecurityFlags.fileSharing.isEnabled
    }
    
    func canCopyFromClipboard() -> Bool {
        return canUploadMedia(from: .clipboard)
    }
}
