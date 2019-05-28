//
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
/*
@objc
protocol UIImageView: NSObjectProtocol { ///TODO: remove
    var UIImage: UIImage? { get set }
}

///TODO: remove
extension UIImageView: UIImageView {

    override var UIImage: UIImage? {
        get {
            return animatedImage ?? image
        }

        set {
            if let newValue = newValue {
                if newValue.isGIF() == true {
                    animatedImage = newValue as? FLAnimatedImage
                } else {
                    image = (newValue as? UIImage)?.downsizedImage()
                }

            } else {
                image = nil
                animatedImage = nil
            }

        }
    }

}

extension UIImageView: UIImageView {

    var UIImage: UIImage? {
        get {
            return image
        }

        set {
            if let newValue = newValue {
                if !newValue.isGIF() { ///TODO: update this method
                    image = (newValue as? UIImage)?.downsizedImage()
                }
            } else {
                image = nil
            }
        }
    }

}

extension UIImageView {
    convenience init(UIImage: UIImage) { ///TODO: retire UIImage
        if UIImage.isGIF() {
            self.init()
            if let image = UIImage as? UIImage {
                self.setGifImage(image)
            }
        } else {
            self.init(image: (UIImage as? UIImage)?.downsizedImage())
        }
    }

}
*/
