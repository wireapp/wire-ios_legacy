// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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

extension JSONDecoder {

    static var defaultDecoder: JSONDecoder {
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

        return decoder
    }
}

extension JSONEncoder {

    static var defaultEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .custom({ (date, encoder) in
            var container = encoder.singleValueContainer()
            try container.encode((date as NSDate).transportString())
        })

        return encoder
    }
}

extension Decodable {

    /// Initialize object from JSON Data or log an error if fails
    ///
    /// - parameter payloadData: JSON data as raw bytes

    init?(_ payloadData: Data, decoder: JSONDecoder = .defaultDecoder) {
        do {
            self = try JSONDecoder.defaultDecoder.decode(Self.self, from: payloadData)
        } catch let error {
            Logging.network.warn("Failed to decode payload: \(error)")
            return nil
        }
    }

    /// Initialize object from a transport response
    ///
    /// - parameter response: ZMTransportResponse with a JSON payload

    init?(_ response: ZMTransportResponse, decoder: JSONDecoder = .defaultDecoder) {
        guard let rawData = response.rawData else {
            return nil
        }

        self.init(rawData, decoder: decoder)
    }

}

extension Encodable {

    /// Encode object to binary payload and log an error if it fails
    ///
    /// - parameter encoder: JSONEncoder to use

    func payloadData(encoder: JSONEncoder = .defaultEncoder) -> Data? {
        do {
            return try encoder.encode(self)
        } catch let error {
            Logging.network.warn("Failed to encode payload: \(error)")
            return nil
        }
    }

}
