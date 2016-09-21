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


import UIKit
import ImageIO

extension UIImage {
    
    class func loadPreviewForImageWithURL(_ imageURL: URL, maxPixelSize previewImagePixelSize:Int, completion:@escaping (_ previewImage: UIImage?) -> Void) {
        DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default).async {
            guard let imageSource = CGImageSourceCreateWithURL(imageURL as CFURL, nil),
                let imagePropertiesRef = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil)
                else { return }
            
            let imageProperties = imagePropertiesRef as NSDictionary
            
            guard let imageWidth = (imageProperties[String(kCGImagePropertyPixelWidth)] as? NSNumber)?.floatValue,
                let imageHeight = (imageProperties[String(kCGImagePropertyPixelHeight)] as? NSNumber)?.floatValue
                else { return }

            
            var orientation = UIImageOrientation.up
            if let imageCGOrientation = (imageProperties[String(kCGImagePropertyOrientation)] as? NSNumber)?.uint32Value,
                let imagePropertyOrientation = CGImagePropertyOrientation(rawValue: imageCGOrientation),
                let imageUIOrientation = UIImageOrientation.fromCGImageOrientation(imagePropertyOrientation) {
                    orientation = imageUIOrientation
            }
            
            let aspectRatio = (imageWidth > imageHeight) ? imageWidth / imageHeight : imageHeight / imageWidth
            let maxPixelSize = aspectRatio * Float(previewImagePixelSize)
            
            let options: [AnyHashable: Any] =
            [
                kCGImageSourceThumbnailMaxPixelSize as AnyHashable: maxPixelSize,
                kCGImageSourceCreateThumbnailFromImageIfAbsent as AnyHashable: true,
            ]
            
            guard let thumbnailCGImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary?)
                else { return }
            
            let thumbnailImage = UIImage(cgImage: thumbnailCGImage, scale:1.0, orientation: orientation)
            DispatchQueue.main.async {
                completion(thumbnailImage)
            }
        }
    }
}

extension UIImageOrientation {
    static func fromCGImageOrientation(_ orientation:CGImagePropertyOrientation) -> UIImageOrientation? {
        let imageOrientationMapping: Dictionary<UInt32, UIImageOrientation> =
        [
            CGImagePropertyOrientation.up.rawValue           : UIImageOrientation.up,
            CGImagePropertyOrientation.upMirrored.rawValue   : UIImageOrientation.upMirrored,
            CGImagePropertyOrientation.down.rawValue         : UIImageOrientation.down,
            CGImagePropertyOrientation.downMirrored.rawValue : UIImageOrientation.downMirrored,
            CGImagePropertyOrientation.leftMirrored.rawValue : UIImageOrientation.rightMirrored,
            CGImagePropertyOrientation.right.rawValue        : UIImageOrientation.right,
            CGImagePropertyOrientation.rightMirrored.rawValue: UIImageOrientation.leftMirrored,
            CGImagePropertyOrientation.left.rawValue         : UIImageOrientation.left,
        ]
        return imageOrientationMapping[orientation.rawValue]
    }
}
