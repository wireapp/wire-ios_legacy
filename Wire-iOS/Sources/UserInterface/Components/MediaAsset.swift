// 
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

import FLAnimatedImage

protocol MediaAsset: class, NSObjectProtocol {
    var size: CGSize { get }
    var data: Data? { get }
    var isGIF: Bool { get }
    var isTransparent: Bool { get }
}

protocol MediaAssetView: class, NSObjectProtocol {
    func mediaAsset() -> MediaAsset?
    func setMediaAsset(_ asset: MediaAsset?)
}

extension FLAnimatedImage: MediaAsset {
    var data: Data? {
        return self.data
    }
    
    var isGIF: Bool {
        return true
    }
    
    var isTransparent: Bool {
        return false
    }
}


extension UIImageView: MediaAssetView {
    func imageData() -> Data? {
        return image?.data
    }
    
    func setImageData(_ imageData: Data?) {
        if let imageData = imageData {
            image = UIImage(data: imageData)
        }
    }
    
    convenience init(mediaAsset image: MediaAsset) {
        if image.isGIF {
            let animatedImageView = FLAnimatedImageView()
            animatedImageView.animatedImage = image as? FLAnimatedImage ///TODO:
        } else {
            self.init(image: (image as? UIImage)?.downsized())
        }
    }
    
    func mediaAsset() -> MediaAsset? {
        return image
    }
    
    func setMediaAsset(_ image: MediaAsset?) {
        if image == nil {
            self.image = nil
        } else if image?.isGIF == true {
            self.image = (image as? UIImage)?.downsized()
        }
    }
}

extension FLAnimatedImageView: MediaAssetView {
    var mediaAsset: MediaAsset? {
        get {
        return animatedImage ?? image
        }

        set {
            if let image = image {
                if image.isGIF == true {
                    animatedImage = image
                } else {
                    self.image = (image as? UIImage)?.downsized()
                }
            } else {
                self.image = nil
                animatedImage = nil
            }
        }
    }
}


