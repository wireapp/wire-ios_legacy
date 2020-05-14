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
import UIKit
import WireSyncEngine

private var ZM_UNUSED = "UI"
private var overridenAccentColor: ZMAccentColor = .undefined


extension UIColor {
    
    
    /// Set accent color on self user to this index.
    ///
    /// - Parameter accentColor: the accent color
    class func setAccent(_ accentColor: ZMAccentColor) {
        ZMUserSession.shared()?.enqueue {
            SelfUser.provider?.selfUser.accentColorValue = accentColor
        }
    }
    
    class func indexedAccentColor() -> ZMAccentColor {
        // priority 1: overriden color
        if overridenAccentColor != .undefined {
            return overridenAccentColor
        }

        guard
            let activeUserSession = SessionManager.shared?.activeUserSession,
            activeUserSession.selfUser.accentColorValue != .undefined
        else {
            // priority 3: default color
            return .strongBlue
        }
        
        // priority 2: color from self user
        return activeUserSession.selfUser.accentColorValue
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

    static var accentDarken: UIColor {
        return accent().mix(.black, amount: 0.1).withAlphaComponent(0.32)
    }

    static var accentDimmedFlat: UIColor {
        if ColorScheme.default.variant == .light {
            return accent().withAlphaComponent(0.16).removeAlphaByBlending(with: .white)
        } else {
            return accentDarken
        }
    }

    class func accent() -> UIColor {
        return UIColor(fromZMAccentColor: indexedAccentColor())
    }

    static func buttonEmptyText(variant: ColorSchemeVariant) -> UIColor {
        switch variant {
        case .dark:
            return .white
        case .light:
            return accent()
        }
    }
}
