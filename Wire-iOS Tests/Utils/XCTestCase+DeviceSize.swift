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

extension XCTestCase {
    static let ZMDeviceSizeIPhone5          = CGSize(width: 320, height: 568)
    static let ZMDeviceSizeIPhone6          = CGSize(width: 375, height: 667)
    static let ZMDeviceSizeIPhone6Plus      = CGSize(width: 414, height: 736)
    static let ZMDeviceSizeIPhoneX          = CGSize(width: 375, height: 812)
    static let ZMDeviceSizeIPhoneXR         = CGSize(width: 414, height: 896)
    static let ZMDeviceSizeIPadPortrait     = CGSize(width: 768, height: 1024)
    static let ZMDeviceSizeIPadLandscape    = CGSize(width: 1024, height: 768)

    /// return the smallest iPhone screen size that Wire app supports
    public var defaultIPhoneSize: CGSize {
        return XCTestCase.ZMDeviceSizeIPhone5
    }
}
