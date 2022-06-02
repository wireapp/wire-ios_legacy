//
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

public struct AVSIdentifier: Hashable, Equatable {
    public let identifier: UUID
    public let domain: String?

    public init(identifier: UUID, domain: String?) {
        self.identifier = identifier
        self.domain = APIVersion.isFederationEnabled ? domain : nil
    }
}

extension AVSIdentifier {

    public var serialized: String {
        var serializedIdentifier = identifier.transportString()

        if let domain = domain {
            serializedIdentifier += "@\(domain)"
        }

        return serializedIdentifier
    }

    /// Creates a non optional AVSIdentifier from a string. Crashes when the string format is wrong.
    /// Expected string format: "E621E1F8-C36C-495A-93FC-0C247A3E6E5F@wire.link"
    /// - Parameter string: A string composed of a UUID string and an optional domain. Components should be separated by "@"
    /// - Returns: The avs identifier

    public static func from(string: String) -> AVSIdentifier {
        guard let identifier = AVSIdentifier(string: string) else {
            fatalError("Wrong format of string passed to AVSIdentifier")
        }

        return identifier
    }

    /// Inits AVSIdentifier from a serialized string. Returns nil if the string format is wrong.
    /// The string should be composed of a UUID string and an optional domain. Components should be separated by "@".
    /// Example: "E621E1F8-C36C-495A-93FC-0C247A3E6E5F@wire.link"

    init?(string: String) {
        let components = string.components(separatedBy: "@")

        guard
            1...2 ~= components.count,
            let identifier = UUID(uuidString: components[0])
        else {
            return nil
        }

        let domain = components.count == 2 ? components[1] : nil

        self.init(identifier: identifier, domain: domain)
    }
}
