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


@objcMembers public class KeyboardHeight: NSObject {

    /// The height of the system keyboard with the prediction row
    public static var current: CGFloat {
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            return UIApplication.shared.statusBarOrientation.isPortrait ? 264 : 352
        default:
            return phoneKeyboardHeight()
        }
    }

    private static func phoneKeyboardHeight() -> CGFloat {
        switch UIScreen.main.bounds.height {
        case 667: return 258
        case 736: return 271
        case 812: return 253 + UIScreen.safeArea.bottom
        default: return 253
        }
    }

}
