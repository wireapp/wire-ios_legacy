//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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

/// This class is used to retrieve specific arguments passed on the 
/// command line when running automation tests. 
/// These values typically do not need to be stored in `Settings`.
@objc final class AutomationHelper: NSObject {

    private static let defaults = NSUserDefaults.standardUserDefaults()

    ///  - returns: The value specified for the `UseHockey` argument on the command line
    class var useHockey: Bool {
        return defaults.boolForKey("UseHockey")
    }

    ///  - returns: The value specified for the `SkipLoginAlerts` argument on the command line
    class var skipFirstLoginAlerts: Bool {
        return defaults.boolForKey("SkipLoginAlerts")
    }

}
