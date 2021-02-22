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

import XCTest
@testable import Wire

extension UIColor {    
    class var accentOverrideColor: ZMAccentColor? {
        return ZMUser.selfUser()?.accentColorValue
    }
}

extension XCTestCase {
    /// If this is set the accent color will be overriden for the tests
    static var accentColor: ZMAccentColor {
        set {
            UIColor.setAccentOverride(newValue)
        }
        get {
            return UIColor.accentOverrideColor!
        }
    }

    var accentColor: ZMAccentColor {
        set {
            XCTestCase.accentColor = newValue
        }
        get {
            return XCTestCase.accentColor
        }
    }
}
