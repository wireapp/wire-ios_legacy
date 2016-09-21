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

extension Float {
    func clamp(_ lower: Float, upper: Float) -> Float {
        return max(lower, min(upper, self))
    }
}

extension CGFloat {
    func clamp(_ lower: CGFloat, upper: CGFloat) -> CGFloat {
        return fmax(lower, fmin(upper, self))
    }
}

// MARK: Decibel Normalization

extension Float {
    
    /**
      Calculates a nomrlaized value between 0 and 1 
      when called on  a `decibel` value, see:
      http://stackoverflow.com/questions/31598410/how-can-i-normalized-decibel-value-and-make-it-between-0-and-1
      Value is bumped 4x to match the usual voice loudness level (0-160 dB is from absolute silence to military jet aircraft take-off)
     - returns: Normalized loudness value between 0 and 1
     */
    func normalizedDecibelValue() -> Float {
        return (pow(10, self / 20) * 4.0).clamp(0, upper: 1)
    }
}
