// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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
import UIKit

extension UIImage {
    func imageScaled(with scaleFactor: CGFloat) -> UIImage? {
        let size = self.size.applying(CGAffineTransform(scaleX: scaleFactor, y: scaleFactor))
        let scale: CGFloat = 0 // Automatically use scale factor of main screens
        let hasAlpha = false

        UIGraphicsBeginImageContextWithOptions(size, _: !hasAlpha, _: scale)
        draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return scaledImage
    }

    func desaturatedImage(with context: CIContext, saturation: Double = 0) -> UIImage? {
        guard let filter = CIFilter(name: "CIColorControls"),
            let cg = cgImage
            else { return nil }

        let i: CIImage = CIImage(cgImage: cg)

        filter.setValue(i, forKey: kCIInputImageKey)
        filter.setValue(saturation, forKey: "InputSaturation")

        guard let result = filter.outputImage,
            let cgImage: CGImage = context.createCGImage(result, from: result.extent) else { return nil }

        return UIImage(cgImage: cgImage, scale: scale, orientation: imageOrientation)
    }

    func with(insets: UIEdgeInsets, backgroundColor: UIColor? = nil) -> UIImage? {
        let newSize = CGSize(width: size.width + insets.left + insets.right, height: size.height + insets.top + insets.bottom)

        UIGraphicsBeginImageContextWithOptions(newSize, _: 0.0 != 0, _: 0.0)

        backgroundColor?.setFill()
        UIRectFill(CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        draw(in: CGRect(x: insets.left, y: insets.top, width: size.width, height: size.height))

        let colorImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return colorImage
    }

    class func singlePixelImage(with color: UIColor) -> UIImage? {
        let rect = CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()

        context?.setFillColor(color.cgColor)
        context?.fill(rect)

        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return image
    }

    class func deviceOptimizedImage(from imageData: Data) -> UIImage? {
        return UIImage(from: imageData, withMaxSize: UIScreen.main.nativeBounds.size.height)
    }

    convenience init?(from imageData: Data, withMaxSize maxSize: CGFloat) {
        guard let source: CGImageSource = CGImageSourceCreateWithData(imageData as CFData, nil),
            let scaledImage = CGImageSourceCreateThumbnailAtIndex(source, 0, UIImage.thumbnailOptions(withMaxSize: maxSize)) else { return nil }

        self.init(cgImage: scaledImage, scale: 2.0, orientation: .up)
    }

    private class func thumbnailOptions(withMaxSize maxSize: CGFloat) -> CFDictionary {
        return [
            kCGImageSourceCreateThumbnailWithTransform : kCFBooleanTrue,
            kCGImageSourceCreateThumbnailFromImageIfAbsent : kCFBooleanTrue,
            kCGImageSourceCreateThumbnailFromImageAlways : kCFBooleanTrue,
            kCGImageSourceThumbnailMaxPixelSize : NSNumber(value: Float(maxSize))
            ] as CFDictionary
    }

    private class func size(for source: CGImageSource) -> CGSize {

        let options = [
            kCGImageSourceShouldCache: kCFBooleanTrue
            ] as CFDictionary

        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, options) as? [CFString: Any] else {
            return .zero
        }

        if let height = properties[kCGImagePropertyPixelHeight] as? CGFloat,
            let width = properties[kCGImagePropertyPixelWidth] as? CGFloat {
            return CGSize(width: width, height: height)
        }

        return .zero
    }

    convenience init?(from imageData: Data, withShorterSideLength shorterSideLength: CGFloat) {
        guard let source: CGImageSource = CGImageSourceCreateWithData(imageData as CFData, nil) else { return nil }

        let size = UIImage.size(for: source)
        if size.width <= 0 || size.height <= 0 {
            return nil
        }

        var longSideLength = shorterSideLength

        if size.width > size.height {
            longSideLength = shorterSideLength * (size.width / size.height)
        } else if size.height > size.width {
            longSideLength = shorterSideLength * (size.height / size.width)
        }

        guard let scaledImage = CGImageSourceCreateThumbnailAtIndex(source, 0, UIImage.thumbnailOptions(withMaxSize: longSideLength)) else { return nil }

        ///TODO: read screen scale
        self.init(cgImage: scaledImage, scale: 2.0, orientation: .up)
    }

    convenience init(color: UIColor, andSize size: CGSize) {
        let rect = CGRect(x: 0.0, y: 0.0, width: size.width, height: size.height)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()

        context?.setFillColor(color.cgColor)
        context?.fill(rect)

        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        self.init(cgImage: (image?.cgImage)!)
    }
}
