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
import ImageIO
import MobileCoreServices

public enum MetadataError: Error {
    case unknownFormat
    case cannotCreate
}

public extension NSData {

    private static let nullMetadataProperties: CFDictionary = {
        var swiftMetadataProperties: [String: AnyObject] = [:]
        swiftMetadataProperties[String(kCGImagePropertyExifDictionary)] = kCFNull
        swiftMetadataProperties[String(kCGImagePropertyExifAuxDictionary)] = kCFNull
        swiftMetadataProperties[String(kCGImagePropertyTIFFDictionary)] = kCFNull
        swiftMetadataProperties[String(kCGImagePropertyGPSDictionary)] = kCFNull
        swiftMetadataProperties[String(kCGImagePropertyIPTCDictionary)] = kCFNull
        swiftMetadataProperties[String(kCGImagePropertyCIFFDictionary)] = kCFNull
        swiftMetadataProperties[String(kCGImagePropertyMakerAppleDictionary)] = kCFNull
        // TODO: iOS8 is crashing when the following symbols are imported from ImageIO.
        // It looks like a linker issue, since the symbols are marked as available from iOS4.
        swiftMetadataProperties["{MakerCanon}"]   = kCFNull // kCGImagePropertyMakerCanonDictionary
        swiftMetadataProperties["{MakerNikon}"]   = kCFNull // kCGImagePropertyMakerNikonDictionary
        swiftMetadataProperties["{MakerMinolta}"] = kCFNull // kCGImagePropertyMakerMinoltaDictionary
        swiftMetadataProperties["{MakerFuji}"]    = kCFNull // kCGImagePropertyMakerFujiDictionary
        swiftMetadataProperties["{MakerOlympus}"] = kCFNull // kCGImagePropertyMakerOlympusDictionary
        swiftMetadataProperties["{MakerPentax}"]  = kCFNull // kCGImagePropertyMakerPentaxDictionary
        
        return swiftMetadataProperties as CFDictionary
    }()
    
    
    // Removes the privacy-related metadata tags from the binary image (see nullMetadataProperties).
    // Supports JPEG, TIFF, PNG and other image (container) formats/types.
    // @throws MetadataError
    @objc
    func wr_imageDataWithoutMetadata() throws -> NSData {
        guard let imageSource = CGImageSourceCreateWithData(self, nil),
              let type = CGImageSourceGetType(imageSource) else {
            throw MetadataError.unknownFormat
        }

        // GIF file does not have properties in nullMetadataProperties. Tested some recreated GIF data from CGImageDestinationAddImageFromSource have the file size increased and lost animation. e.g. 1.6MB -> 9MB
        if type == kUTTypeGIF {
            return self
        }
        
        let count = CGImageSourceGetCount(imageSource)
        let mutableData = NSMutableData(data: self as Data)
        guard let imageDestination = CGImageDestinationCreateWithData(mutableData, type, count, nil) else {
            throw MetadataError.cannotCreate
        }
        
        for sourceIndex in 0..<count {
            CGImageDestinationAddImageFromSource(imageDestination, imageSource, sourceIndex, NSData.nullMetadataProperties)
        }
        
        guard CGImageDestinationFinalize(imageDestination) else {
            throw MetadataError.cannotCreate
        }
        
        return mutableData
    }
    
    // Retrieves image metadata from the binary image.
    // @throws MetadataError
    @objc
    func wr_metadata() throws -> [String: Any] {
        guard let imageSource = CGImageSourceCreateWithData(self, nil) else {
            throw MetadataError.unknownFormat
        }
        
        return CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String : Any] ?? [:]
    }
}

public extension Data {
    
    // Removes the privacy-related metadata tags from the binary image (see nullMetadataProperties).
    // Supports JPEG, TIFF, PNG and other image (container) formats/types.
    // @throws MetadataError
    func wr_removingImageMetadata() throws -> Data {
        return try (self as NSData).wr_imageDataWithoutMetadata() as Data
    }
    
    // Retrieves image metadata from the binary image.
    // @throws MetadataError
    func wr_metadata() throws -> [String: Any] {
        return try (self as NSData).wr_metadata()
    }
}
