//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

import CoreGraphics

enum AspectRatio {
    case portrait
    case landscape
    case square
}

extension UIDeviceOrientation {
    var aspectRatio: AspectRatio {
        return isLandscape ? .landscape : .portrait
    }
}

extension CGSize {

    var aspectRatio: AspectRatio {
        if width < height {
            return .portrait
        } else if width > height {
            return .landscape
        } else {
            return .square
        }
    }
    
    var isLandscape: Bool {
        return aspectRatio == .landscape
    }
    
    var isPortrait: Bool {
        return aspectRatio == .portrait
    }
    
    var isSquare: Bool {
        return aspectRatio == .square
    }
    
    func flipped() -> CGSize {
        return CGSize(width: height, height: width)
    }
    
    func withOrientation(_ orientation: UIDeviceOrientation) -> CGSize {
        guard orientation.aspectRatio != aspectRatio else { return self }
        return flipped()
    }

}
