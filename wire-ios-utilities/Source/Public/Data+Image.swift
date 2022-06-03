////
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


import Foundation
import ImageIO

extension Data {
    
    /// get MIME type of given image data. Returns nil if the data is not a image
    public var mimeType: String? {
        guard let source = (self as NSData).imageSource,
              let type = CGImageSourceGetType(source) as String? else {
            return nil
        }
        
        return UTIHelper.convertToMime(uti: type)
    }
}

extension NSData {
    var imageSource: CGImageSource? {
        guard length > 0 else {
            return nil
        }
        
        return CGImageSourceCreateWithData(self as CFData, nil)
    }
    
    /// Returns whether the data represents animated GIF
    /// - Parameter data: image data
    /// - Returns: returns turn if the data is GIF and number of images > 1
    @objc
    public func isDataAnimatedGIF() -> Bool {
        guard let source = imageSource,
              CGImageSourceGetCount(source) > 1,
              let type = CGImageSourceGetType(source) as String?,
              UTIHelper.conformsToGifType(uti: type) else {
            return false
        }

        return true
    }
}
