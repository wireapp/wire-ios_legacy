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

import Foundation

extension CGSize {
    enum DeviceScreen {
        // iPhone 5
        static let iPhone4_0Inch = CGSize(width: 320, height: 568)
        // iPhone 6
        static let iPhone4_7Inch = CGSize(width: 375, height: 667)
        // iPhone 6 plus
        static let iPhone5_5Inch = CGSize(width: 414, height: 736)
        // iPhone X
        static let iPhone5_8Inch = CGSize(width: 375, height: 812)
        // iPhone XR
        static let iPhone6_5Inch = CGSize(width: 414, height: 896)

        static let iPadPortrait =  CGSize(width: 768, height: 1024)
        static let iPadLandscape = CGSize(width: 1024, height: 768)
    }
}
