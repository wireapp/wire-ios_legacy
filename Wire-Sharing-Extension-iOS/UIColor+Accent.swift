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


import UIKit
import zshare
import WireExtensionComponents
import Classy

let LastUserAccentColorKey = "lastUserAccentColorKey"

extension UIColor {
    
    static var accentColor: UIColor {
        get {
            if let number = UserDefaults.standard.object(forKey: LastUserAccentColorKey) as? NSNumber,
                let accentColor = AccentColor(rawValue: number.integerValue) {
                return self.colorForZMColor(accentColor)
            } else {
                return self.colorForZMColor(AccentColor.ZMAccentColorStrongBlue)
            }
        }
    }
    
    class func setAccentColor(_ color: AccentColor) {
        UserDefaults.standardUserDefaults().setObject(NSNumber(integer: color.rawValue), forKey: LastUserAccentColorKey)
    }
    
    public class func colorForZMColor(_ color: AccentColor) -> UIColor! {
        return self.colorTable[color]
    }
    
    fileprivate static var colorTable: [AccentColor: UIColor] =
    [
        AccentColor.ZMAccentColorStrongBlue:        rgb( 36, 146, 211),
        AccentColor.ZMAccentColorStrongLimeGreen:   rgb(  0, 200,   0),
        AccentColor.ZMAccentColorBrightYellow:      rgb(254, 191,   2),
        AccentColor.ZMAccentColorVividRed:          rgb(255, 39,    0),
        AccentColor.ZMAccentColorBrightOrange:      rgb(255, 137,   0),
        AccentColor.ZMAccentColorSoftPink:          rgb(254,  94, 189),
        AccentColor.ZMAccentColorViolet:            rgb(157,   0, 255),
    ]
}

func rgb(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat) -> UIColor {
    return UIColor(red: red / 255.0, green: green / 255.0, blue: blue / 255.0, alpha: 1.0)
}
