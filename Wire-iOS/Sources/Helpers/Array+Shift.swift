//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

extension Array {
    
    /// Shifts the array by the given amount
    /// Negatives shift left, positives shift right
    ///
    /// [1, 2, 3]
    /// shifted by 1 => [3, 1, 2]
    /// shifted by -1 => [2, 3, 1]
    func shifted(by amount: Int) -> Array {
        // accounts for negative amount:
        // - addition: results in the positive equivalent of amount to shift
        // - modulo: ensures we stay in range
        let rightShiftAmount = (count + amount) % count
        
        // no operation if shift is 0
        guard rightShiftAmount != 0 else { return self }
        
        // get index for the split
        guard let i = index(endIndex, offsetBy: -rightShiftAmount, limitedBy: startIndex) else {
            return self
        }
        
        // split
        let front = self[i..<endIndex]
        let back = self[startIndex..<i]
        
        return Array(front + back)
    }
}
