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
import MobileCoreServices
import AVFoundation

/**
 * The list of asset types that the app can show preview of, or play inline.
 */

@objc(ZMRichAssetFileType)
public enum RichAssetFileType: Int, Equatable {
    /// A wallet pass.
    case walletPass = 0

    /// A playable video.
    case video = 1

    /// An playable audio.
    case audio = 2

    // MARK: - Helpers

    init?(mimeType: String) {
        let audioVisualMimeTypes = AVURLAsset.audiovisualMIMETypes()

        if mimeType == "application/vnd.apple.pkpass" {
            self = .walletPass
            return
        }

        // If the file format is not playable, ignore it.
        guard audioVisualMimeTypes.contains(mimeType) else {
            return nil
        }

        if UTIHelper.conformsToAudioType(mime: mimeType) {
            // Match playable audio files
            self = .audio
        } else if UTIHelper.conformsToMovieType(mime: mimeType) {
            // Match playable video files
            self = .video
        } else {
            // If we cannot match the mime type to a known asset type
            return nil
        }
    }

}
