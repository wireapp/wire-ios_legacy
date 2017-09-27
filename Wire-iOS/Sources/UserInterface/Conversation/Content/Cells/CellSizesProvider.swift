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

@objc class CellSizesProvider: NSObject {
    
    static let standardCellHeight : CGFloat = 200.0
    static let compressedCellHeight : CGFloat = 160.0
    static let videoViewHeight : CGFloat = 160.0
    static let minimumMediaSize : CGFloat = 48.0
    
    static func heightForImage(_ image: UIImage?) -> CGFloat {
        var height : CGFloat = 0.0
        if let image = image, image.size.height < standardCellHeight {
            height = image.size.height
        } else {
            height = standardCellHeight
        }
        
        return getFinalHeight(for: height)
    }
    
    static func originalSize(for image: ZMImageMessageData) -> CGSize {
        let scaleFactor: CGFloat = image.isAnimatedGIF ? 1 : 0.5;
        return (image.originalSize).applying(CGAffineTransform(scaleX: scaleFactor, y: scaleFactor));
    }
    
    static func heightForVideo() -> CGFloat {
        return getFinalHeight(for: videoViewHeight)
    }
    
    static func compressedSizeForView(_ view: UIView) -> CGFloat {
        return view.systemLayoutSizeFitting(UILayoutFittingCompressedSize).height;
    }
    
    private static func getFinalHeight(for height: CGFloat) -> CGFloat {
        return min((UIScreen.isCompact() ? compressedCellHeight : standardCellHeight), height)
    }
    
    static func getMinimumSize(for size: CGSize) -> CGSize {
        return CGSize(width: max(minimumMediaSize, size.width), height: max(minimumMediaSize, size.height))
    }
    
}
