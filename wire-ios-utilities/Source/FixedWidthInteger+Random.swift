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

public extension FixedWidthInteger {
    
    private var abs: Self {
        if self < 0 {
            return 0 - self
        } else {
            return self
        }
    }
    
    /// Returns a random number within the range [0, upperBound) using the
    /// Data.secureRandomData(length:) method. This implementation is
    /// modulo bias free.
    ///
    static func secureRandomNumber(upperBound: Self) -> Self {
        
        assert(upperBound != 0 && upperBound != Self.min, "Upper bound should not be zero or equal to the minimum possible value")
        
        var random: Self
        
        // To eliminate modulo bias, we must ensure range of possible random
        // numbers is evenly divisible by the upper bound. We do this by
        // trimming the excess remainder off the lower bound (0)
        //
        let min = (Self.min &- upperBound) % upperBound
        
        repeat {
            // get enough random bytes to fill UInt
            let data = Data.secureRandomData(length: UInt(MemoryLayout<Self>.size))
            
            // extract the UInt
            random = data.withUnsafeBytes { (pointer: UnsafeRawBufferPointer) -> Self in
                return pointer.bindMemory(to: Self.self).baseAddress!.pointee
            }
            
        } while random.abs < min
        
        return random % upperBound
    }
}

/// Extension for NSNumber so we can support ObjC
public extension NSNumber {
    @objc static func secureRandomNumber(upperBound: UInt32) -> UInt32 {
        return UInt32.secureRandomNumber(upperBound: upperBound)
    }
}

