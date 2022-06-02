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

extension Decodable {

    /// Initialize object from JSON Data
    ///
    /// - parameter jsonData: JSON data as raw bytes

    init?(_ jsonData: Data) {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom({ (decoder) -> Date in
            let container = try decoder.singleValueContainer()
            let rawDate = try container.decode(String.self)

            if let date = NSDate(transport: rawDate) {
                return date as Date
            } else {
                throw DecodingError.dataCorruptedError(in: container,
                                                       debugDescription: "Expected date string to be ISO8601-formatted with fractional seconds")
            }
        })

        do {
            self = try decoder.decode(Self.self, from: jsonData)
        } catch {
            Logging.network.debug("Failed to decode payload: \(error)")
            return nil
        }
    }

}

extension Decodable {

    /// Initialize object from a dictionary
    ///
    /// - parameter payload: Dictionary representing the object
    ///
    /// This only works for dictionaries which only contain type
    /// which can be represented as JSON.

    init?(_ payload: [String: Any]) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: payload, options: .prettyPrinted)
            let decoder = JSONDecoder()
            self = try decoder.decode(Self.self, from: jsonData)
        } catch {
            Logging.network.debug("Failed to decode payload: \(error)")
            return nil
        }
    }

}

extension DateFormatter {
    static let iso8601Full: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
}
