//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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

// Use SwiftGen
extension UIColor {
    static var blueNew: UIColor {
        return UIColor(named: "blueNew") ?? .clear
    }

    static var greenNew: UIColor {
        return UIColor(named: "greenNew") ?? .clear
    }

    static var petrolNew: UIColor {
        return UIColor(named: "petrolNew") ?? .clear
    }
}

public enum DefaultStyle {

    public enum Colors {

        public static let label: UIColor = {
            if #available(iOS 13.0, *) {
                return UIColor.label
            } else {
                return .black
            }
        }()
    }
}

extension UIColor {
    static var customAccent: UIColor {
        if #available(iOS 13, *) {
            return UIColor { (traitCollection: UITraitCollection) -> UIColor in
                if traitCollection.userInterfaceStyle == .dark {
                    return UIColor.blueNew
                } else {
                    return UIColor.blue
                }
            }
        } else {
            return UIColor.red
        }
    }
}


//extension UIColor {
//    var customColor: UIColor {
//        if #available(iOS 13.0, *) {
//            UIColor(dynamicProvider: { traitCollection in
//                switch traitCollection.userInterfaceStyle {
//                case .dark:
//                    return UIColor.yellow
//                case .light:
//                    return UIColor.blue
//                case .unspecified:
//                    return UIColor.clear
//                }
//            })
//            // Test
//            return UIColor.red
//        } else {
//            // Fallback on earlier versions
//            return UIColor.blue
//        }
//    }
//}


//extension UIColor {
//    static func dynamicColor(light: UIColor, dark: UIColor) -> UIColor {
//        guard #available(iOS 13.0, *) else { return light }
//        return UIColor { $0.userInterfaceStyle == .dark ? dark : light }
//    }
//}
