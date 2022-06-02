//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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

public extension WireProtos.Asset.Original {
    var hasRasterImage: Bool {
        guard case .image? = metaData else {
            return false
        }

        guard let uti = UTIHelper.convertToUti(mime: mimeType) else { return false }

        return !UTIHelper.conformsToVectorType(uti: uti)
    }
}

fileprivate extension ImageAsset {
    var isRaster: Bool {
        return !UTIHelper.conformsToVectorType(mime: mimeType)
    }
}

public extension GenericMessage {
    var hasRasterImage: Bool {
        guard let content = content else { return false }
        switch content {
        case .image(let data):
            return data.isRaster
        case .ephemeral(let data):
            switch data.content {
            case .image(let image)?:
                return image.isRaster
            default:
                return false
            }
        default:
            return false
        }
    }
}
