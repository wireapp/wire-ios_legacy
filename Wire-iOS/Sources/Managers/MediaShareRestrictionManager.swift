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

//var canFilesBeShared: Bool {
//    guard let session = ZMUserSession.shared() else { return true }
//    return session.fileSharingFeature.status == .enabled && SecurityFlags.fileSharing.isEnabled
//}

extension ShareableMediaSource {
    static var SecurityFlagRestrictedTypes: [ShareableMediaSource] = [.photoLibrary, .shareExtension, .clipboard]
    
    var canBeUploaded: Bool {
        guard let session = ZMUserSession.shared(), session.fileSharingFeature.status == .enabled else {
            if SecurityFlags.fileSharing.isEnabled {
                return ShareableMediaSource.allCases.contains(self)
            }
            return ShareableMediaSource.SecurityFlagRestrictedTypes.contains(self)
        }
        return false
    }
    
    var canBeDownloaded: Bool {
        return  SecurityFlags.fileSharing.isEnabled
    }
    
}

//return canFilesBeShared ? [
//    photoButton,
//    mentionButton,
//    sketchButton,
//    gifButton,
//    audioButton,
//    pingButton,
//    uploadFileButton,
//    locationButton,
//    videoButton
//] : [
//    mentionButton,
//    pingButton,
//    locationButton
//]
