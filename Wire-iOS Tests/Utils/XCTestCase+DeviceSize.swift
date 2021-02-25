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

import XCTest

extension XCTestCase {
    static let DeviceSizeIPhone5          = CGSize(width: 320, height: 568)
    static let DeviceSizeIPhone6          = CGSize(width: 375, height: 667)
    static let DeviceSizeIPhone6Plus      = CGSize(width: 414, height: 736)
    static let DeviceSizeIPhoneX          = CGSize(width: 375, height: 812)
    static let DeviceSizeIPhoneXR         = CGSize(width: 414, height: 896) ///same size as iPhone Xs Max
    static let DeviceSizeIPadPortrait     = CGSize(width: 768, height: 1024)
    static let DeviceSizeIPadLandscape    = CGSize(width: 1024, height: 768)

    static let phoneScreenSizes: [String: CGSize] = [
        "iPhone-4_0_Inch": DeviceSizeIPhone5,
        "iPhone-4_7_Inch": DeviceSizeIPhone6,
        "iPhone-5_5_Inch": DeviceSizeIPhone6Plus,
        "iPhone-5_8_Inch": DeviceSizeIPhoneX,
        "iPhone-6_5_Inch": DeviceSizeIPhoneXR
    ]

    /// we should add iPad Pro sizes
    static let tabletScreenSizes: [String: CGSize] = [
        "iPad-Portrait": DeviceSizeIPadPortrait,
        "iPad-Landscape": DeviceSizeIPadLandscape
    ]

    static var deviceScreenSizes: [String: CGSize] = {
        return phoneScreenSizes.merging(tabletScreenSizes) { $1 }
    }()

    func phoneWidths() -> Set<CGFloat> {
        return Set(XCTestCase.phoneScreenSizes.map( { size in
            return size.value.width
        }))
    }

    var smallestWidth: CGFloat {
        return XCTestCase.phoneScreenSizes.map( { size in
            return size.value.width
        }).sorted().first!
    }

    func tabletWidths() -> Set<CGFloat> {
        return Set(XCTestCase.tabletScreenSizes.map( { size in
            return size.value.width
        }))
    }

    /// return the smallest iPhone screen size that Wire app supports
    public var defaultIPhoneSize: CGSize {
        return XCTestCase.DeviceSizeIPhone5
    }
}
