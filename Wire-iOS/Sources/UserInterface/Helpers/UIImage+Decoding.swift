//
//  UIImage+Decoding.swift
//  Wire-iOS
//
//  Created by Jacob Persson on 06.07.18.
//  Copyright © 2018 Zeta Project Germany GmbH. All rights reserved.
//

import Foundation

extension UIImage {
    
    /// Decode UIIMage. This will prevent it from happening later in the rendering path.
    public var decoded: UIImage? {
        guard let rawImage = cgImage else {
            return  nil
        }
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        guard let context = CGContext(data: nil, width: rawImage.width, height: rawImage.height, bitsPerComponent: 8, bytesPerRow: rawImage.width * 4, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            return nil
        }
        
        let imageBounds = CGRect(x: 0, y: 0, width: rawImage.width, height: rawImage.height)
        context.draw(rawImage, in: imageBounds)
        
        guard let rawDecodedImage = context.makeImage() else {
            return nil
        }
        
        return UIImage(cgImage: rawDecodedImage)
    }
    
}
