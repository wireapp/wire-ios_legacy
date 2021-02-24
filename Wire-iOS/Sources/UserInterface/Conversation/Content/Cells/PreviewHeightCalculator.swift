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
import UIKit

class PreviewHeightCalculator: NSObject {
    
    static let standardCellHeight: CGFloat = 200.0
    static let compressedCellHeight: CGFloat = 160.0
    static let videoViewHeight: CGFloat = 160.0
    
    static func heightForImage(_ image: UIImage?) -> CGFloat {
        var height: CGFloat = 0.0
        if let image = image, image.size.height < standardCellHeight {
            height = image.size.height
        } else {
            height = standardCellHeight
        }
        
        return calculateFinalHeight(for: height)
    }
    
    static func compressedSizeForView(_ view: UIView) -> CGFloat {
        return view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
    }
    
    static func heightForVideo() -> CGFloat {
        return calculateFinalHeight(for: videoViewHeight)
    }
    
    private static func calculateFinalHeight(for height: CGFloat) -> CGFloat {
        return min((UIScreen.main.isCompact ? compressedCellHeight : standardCellHeight), height)
    }

}
