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


import UIKit


@objcMembers public class CookieLabel: NSObject {

    private static var _label: CookieLabel?
    public static var _testOverrideLabel: CookieLabel?

    public private(set) var value: String

    public init(value: String) {
        self.value = value
        super.init()
    }

    private override convenience init() {
        self.init(value: UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString)
    }

    public var length: Int {
        return value.count
    }

    public static var current: CookieLabel {
        if let label = _testOverrideLabel {
            return label
        } else if let label = _label {
            return label
        } else {
            let label = CookieLabel()
            _label = label
            return label
        }
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? CookieLabel else { return false }
        return value == other.value
    }

}
