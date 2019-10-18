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
import FormatterKit

/**
 * A namespace to generate formatted text from raw data.
 *
 * It currently supports:
 * - list formatting from an array
 */

enum FormattedText {

    private static let legacayArrayFormatter: TTTArrayFormatter = {
        let formatter = TTTArrayFormatter()
        formatter.conjunction = ""
        return formatter
    }()

    /**
     * Creates a string that describes an array separated by commas.
     * - parameter array: The array to describe.
     * - returns: The description of the array.
     */

    static func list(from array: [String]) -> String {
        // TODO iOS 13: Use the Foundation list formatter.
        return legacayArrayFormatter.string(from: array)
    }

}
