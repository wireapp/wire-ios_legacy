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


import UIKit

@objc public class ZMAccentColorValidator: NSObject, ZMPropertyValidator {

    @objc(validateValue:error:)
    public static func validateValue(_ ioValue: AutoreleasingUnsafeMutablePointer<AnyObject?>!) throws {
        var pointee = ioValue.pointee as Any?
        defer { ioValue.pointee = pointee as AnyObject? }
        try validateValue(&pointee)
    }
    
    
    @discardableResult public static func validateValue(_ ioValue: inout Any?) throws -> Bool {
        
        let value = ioValue as? Int16
        
        if value == nil ||
            value < ZMAccentColor.min.rawValue ||
            ZMAccentColor.max.rawValue < value {
            let color = ZMAccentColor(rawValue:
                ZMAccentColor.min.rawValue +
                    Int16(arc4random_uniform(UInt32(ZMAccentColor.max.rawValue - ZMAccentColor.min.rawValue))))
            ioValue = NSNumber(value: color?.rawValue ?? 0)
        }
        
        return true
    }
    
}
