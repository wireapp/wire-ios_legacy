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

enum AudioButtonOverlayState {
    case hidden, expanded(CGFloat), `default`
    
    var width: CGFloat {
        return 40
    }
    
    var height: CGFloat {
        switch self {
        case .hidden: return 0
        case .default: return 96
        case .expanded: return 120
        }
    }
    
    var alpha: CGFloat {
        switch self {
        case .hidden: return 0
        default: return 1
        }
    }
}

// MARK: Animation

extension AudioButtonOverlayState {
    
    var animatable: Bool {
        if case .hidden = self {
            return false
        }
        
        return true
    }
    
    var springDampening: CGFloat {
        switch self {
        case .expanded: return 0.6
        case .default: return 0.7
        default: return 0
        }
    }
    
    var springVelocity: CGFloat {
        switch self {
        case .expanded: return 0.4
        case .default: return 0.3
        default: return 0
        }
    }
    
    var duration: TimeInterval {
        switch self {
        case .expanded, .default: return 0.3
        default: return 0.2
        }
    }
    
    var sendButtonTransform: CGAffineTransform {
        switch self {
        case .hidden: return CGAffineTransform(rotationAngle: 90)
        default: return CGAffineTransform.identity
        }
    }
    
    func colorWithColors(_ color: UIColor, highlightedColor: UIColor) -> UIColor {
        if case .expanded(let amount) = self {
            return color.mix(highlightedColor, amount: Double(amount))
        }
        return color
    }
}
