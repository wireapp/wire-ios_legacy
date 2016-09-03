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


import AssetsLibrary

@objc final public class SavableImage: NSObject {

    typealias ImageSaveCompletion = () -> Void
    
    private let imageData: NSData
    private let imageOrientation: UIImageOrientation
    private let library = ALAssetsLibrary()
    private var writeInProgess = false
    private let saveCompletion: ImageSaveCompletion?
    
    init(data: NSData, orientation: UIImageOrientation, completion: ImageSaveCompletion?) {
        imageData = data
        imageOrientation = orientation
        saveCompletion = completion
        super.init()
    }
    
    public func saveToLibrary() {
        guard !writeInProgess else { return }
        writeInProgess = true
        
        let metadata: [String: NSObject] = [ALAssetPropertyOrientation: imageOrientation.exifOrientiation]
        library.writeImageDataToSavedPhotosAlbum(imageData, metadata: metadata) { _, _ in
            self.saveCompletion?()
        }
    }

}

extension UIImageOrientation {
    var exifOrientiation: UInt {
        switch self {
        case .Up: return 1
        case .Down: return 3
        case .Left: return 8
        case .Right: return 6
        case .UpMirrored: return 2
        case .DownMirrored: return 4
        case .LeftMirrored: return 5
        case .RightMirrored: return 7
        }
    }
}