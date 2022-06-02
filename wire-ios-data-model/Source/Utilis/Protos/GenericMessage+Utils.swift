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

extension GenericMessage {
    var knownMessage: Bool {
        return content != nil
    }
}

extension ImageAsset {
    public init(mediumProperties: ZMIImageProperties?,
                processedProperties: ZMIImageProperties?,
                encryptionKeys: ZMImageAssetEncryptionKeys?,
                format: ZMImageFormat) {
        self = ImageAsset.with {
            $0.width = Int32(processedProperties?.size.width ?? 0)
            $0.height = Int32(processedProperties?.size.height ?? 0)
            $0.size = Int32(processedProperties?.length ?? 0)
            $0.originalWidth = Int32(mediumProperties?.size.width ?? 0)
            $0.originalHeight = Int32(mediumProperties?.size.height ?? 0)
            if let otrKey = encryptionKeys?.otrKey {
                $0.otrKey = otrKey
            }
            if let sha256 = encryptionKeys?.sha256 {
                $0.sha256 = sha256
            }
            $0.mimeType = processedProperties?.mimeType ?? ""
            $0.tag = StringFromImageFormat(format)
        }
    }
}
