////
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

public struct PushToken: Equatable {

    // MARK: - Types

    public enum TokenType: Int, Codable {

        case standard
        case voip

        public var transportType: String {
            switch self {
            case .standard: return "APNS"
            case .voip: return "APNS_VOIP"
            }
        }
    }

    // MARK: - Properties

    public let deviceToken: Data
    public let appIdentifier: String
    public let transportType: String
    public let tokenType: TokenType

    // MARK: - Life cycle

    public init(
        deviceToken: Data,
        appIdentifier: String,
        transportType: String,
        tokenType: TokenType
    ) {
        self.deviceToken = deviceToken
        self.appIdentifier = appIdentifier
        self.transportType = transportType
        self.tokenType = tokenType
    }

    // MARK: - Methods

    public var deviceTokenString: String {
        return deviceToken.zmHexEncodedString()
    }

}

// MARK: - Codable

extension PushToken: Codable {

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        deviceToken = try container.decode(Data.self, forKey: .deviceToken)
        appIdentifier = try container.decode(String.self, forKey: .appIdentifier)
        transportType = try container.decode(String.self, forKey: .transportType)

        // Property 'tokenType' was added to use two token types: voip (old) and apns (new). All old clients with voip token did not have this property, so we need to set it by default as .voip.
        tokenType = try container.decodeIfPresent(TokenType.self, forKey: .tokenType) ?? .voip
    }

    enum CodingKeys: String, CodingKey {

        case deviceToken
        case appIdentifier
        case transportType
        case tokenType

    }

}
