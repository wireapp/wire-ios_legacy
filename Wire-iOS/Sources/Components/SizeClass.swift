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

@objc open class SizeClass: NSObject {

    @objc static var isIPad: Bool {
        return UIDevice.current.userInterfaceIdiom == .pad
    }

    @objc static var isIPadInFullScreenMode: Bool {
        return isIPad && UIApplication.shared.keyWindow?.traitCollection.horizontalSizeClass == .regular
    }

    @objc static var isIPadLandscapeLayoutInFullScreenMode: Bool {
        return isIPadInFullScreenMode && UIInterfaceOrientationIsLandscape(UIApplication.shared.statusBarOrientation)
    }
    
    @objc static var isIPadPortraitLayoutInFullScreenMode: Bool {
        return isIPadInFullScreenMode && UIInterfaceOrientationIsPortrait(UIApplication.shared.statusBarOrientation)
    }
}

