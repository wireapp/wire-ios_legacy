//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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
import WireImages

public final class UserProfileImageOwner: NSObject, ZMImageOwner {

    static var imageFormats: [ZMImageFormat] {
        return [.medium, .profile]
    }

    let imageData: Data
    var processedImages = [ZMImageFormat: Data]()

    init(imageData: Data) {
        self.imageData = imageData
        super.init()
    }

    public func setImageData(_ imageData: Data, for format: ZMImageFormat, properties: ZMIImageProperties?) {
        processedImages[format] = imageData
    }

    public func imageData(for format: ZMImageFormat) -> Data? {
        return processedImages[format]
    }

    public func requiredImageFormats() -> NSOrderedSet {
        return NSOrderedSet(array: UserProfileImageOwner.imageFormats.map { $0.rawValue })
    }

    public func originalImageData() -> Data? {
        return imageData
    }

    public func originalImageSize() -> CGSize {
        return .zero
    }

    public func isInline(for format: ZMImageFormat) -> Bool {
        return false
    }

    public func isPublic(for format: ZMImageFormat) -> Bool {
        return false
    }

    public func isUsingNativePush(for format: ZMImageFormat) -> Bool {
        return false
    }

    public func processingDidFinish() {

    }

}
