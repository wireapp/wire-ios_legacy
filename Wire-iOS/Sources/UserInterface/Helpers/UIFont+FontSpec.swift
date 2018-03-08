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

// Objective-C compatiblity layer for the Swift only FontSpec
@objc
extension UIFont {
    
    // MARK: - Small
    
    class var smallLightFont: UIFont {
        return FontSpec.init(.small, .light).font!
    }
    
    class var smallRegularFont: UIFont {
        return FontSpec.init(.small, .regular).font!
    }
    
    class var smallMediumFont: UIFont {
        return FontSpec.init(.small, .medium).font!
    }
    

    // MARK: - Normal
    
    class var normalLightFont: UIFont {
        return FontSpec.init(.small, .light).font!
    }
    
    class var normalRegularFont: UIFont {
        return FontSpec.init(.small, .regular).font!
    }
    
    class var normalMediumFont: UIFont {
        return FontSpec.init(.small, .medium).font!
    }
    
    // MARK: - Large
    
    class var largeThinFont: UIFont {
        return FontSpec.init(.large, .thin).font!
    }
    
    class var largeLightFont: UIFont {
        return FontSpec.init(.large, .light).font!
    }
    
    class var largeRegularFont: UIFont {
        return FontSpec.init(.large, .regular).font!
    }
    
    class var largeMediumFont: UIFont {
        return FontSpec.init(.large, .medium).font!
    }
    
    class var largeSemiboldFont: UIFont {
        return FontSpec.init(.large, .semibold).font!
    }
    
}
