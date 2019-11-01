//
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

import Foundation

private var ZM_UNUSED = "UI"
private var overridenAccentColor: ZMAccentColor = .undefined


extension UIColor {
    
    
    /// Set accent color on self user to this index.
    ///
    /// - Parameter accentColor: the accent color
    class func setAccent(_ accentColor: ZMAccentColor) {
        ZMUserSession.shared()?.enqueueChanges({
            ZMUser.selfUser()?.accentColorValue = accentColor
        })
    }
    
    class func accentOverrideColor() -> ZMAccentColor? {
        return ZMUser.selfUser()?.accentColorValue
    }
    
    class func indexedAccentColor() -> ZMAccentColor {
        // priority 1: overriden color
        if overridenAccentColor != .undefined {
            return overridenAccentColor
        }
        
        guard let activeUserSession = SessionManager.shared?.activeUserSession,
            ZMUser.selfUser(inUserSession: activeUserSession).accentColorValue != .undefined else {
            // priority 3: default color
            return .strongBlue
        }

        // priority 2: color from self user
        return ZMUser.selfUser(inUserSession: activeUserSession).accentColorValue
    }
    
    
    /// Set override accent color. Can set to ZMAccentColorUndefined to remove override.
    ///
    /// - Parameter overrideColor: the override color
    class func setAccentOverride(_ overrideColor: ZMAccentColor) {
        if overridenAccentColor == overrideColor {
            return
        }
        
        overridenAccentColor = overrideColor
    }
    
//    func isEqual(to object: Any?) -> Bool {
//        if !(object is UIColor) {
//            return false
//        }
//        let lhs = self
//        let rhs = object as? UIColor
//
//        let rgba1 = [CGFloat](repeating: 0.0, count: 4)
//        lhs.getRed(rgba1 + 0, green: rgba1 + 1, blue: rgba1 + 2, alpha: rgba1 + 3)
//        let rgba2 = [CGFloat](repeating: 0.0, count: 4)
//        rhs.getRed(rgba2 + 0, green: rgba2 + 1, blue: rgba2 + 2, alpha: rgba2 + 3)
//
//        return (rgba1[0] == rgba2[0]) && (rgba1[1] == rgba2[1]) && (rgba1[2] == rgba2[2]) && (rgba1[3] == rgba2[3])
//    }
}
