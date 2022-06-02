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

 /// A struct containing a token to validate login requests
 /// received via url schemes.
public struct CompanyLoginVerificationToken: Codable, Equatable {

    /// The unique identifier of the token.
    let uuid: UUID
    /// The creation date of the token.
    let creationDate: Date
    /// The amount of seconds the token should be considered valid.
    let timeToLive: TimeInterval

    /// Creates a new validation token with an expiration time
    /// of 30 minutes if not specified otherwise.
    init(uuid: UUID = .init(), creationDate: Date = .init(), timeToLive: TimeInterval = 60 * 30) {
        self.uuid = uuid
        self.creationDate = creationDate
        self.timeToLive = timeToLive
    }

    /// Whether the token is no langer valid (older than its time to live).
    var isExpired: Bool {
        return abs(creationDate.timeIntervalSinceNow) >= timeToLive
    }

    /// Validates a passed in UUID against the token.
    /// - parameter identifier: The uuid which should be validated against the token.
    /// - returns: Whether the UUID matches the token and the token is still valid.
    func matches(identifier: UUID) -> Bool {
        return uuid == identifier && !isExpired
    }
}

public func == (lhs: CompanyLoginVerificationToken, rhs: CompanyLoginVerificationToken) -> Bool {
    return lhs.uuid == rhs.uuid
}

public extension CompanyLoginVerificationToken {

    private static let defaultsKey = "CompanyLoginVerificationTokenDefaultsKey"

    /// Returns the currently stored verification token.
    /// - parameter defaults: The defaults to retrieve the token from.
    static func current(in defaults: UserDefaults = .shared()) -> CompanyLoginVerificationToken? {
        return defaults.data(forKey: CompanyLoginVerificationToken.defaultsKey).flatMap {
            try? JSONDecoder().decode(CompanyLoginVerificationToken.self, from: $0)
        }
    }

    /// Stores the token in the provided defaults.
    /// - parameter defaults: The defaults to store the token in.
    /// - returns: Whether the write operation succeeded.
    @discardableResult func store(in defaults: UserDefaults = .shared()) -> Bool {
        do {
            let data = try JSONEncoder().encode(self)
            defaults.set(data, forKey: CompanyLoginVerificationToken.defaultsKey)
            return true
        } catch {
            return false
        }
    }

    /// Deletes the current verification token.
    /// - parameter defaults: The defaults to delete the token from.
    static func flush(in defaults: UserDefaults = .shared()) {
        defaults.removeObject(forKey: defaultsKey)
    }

    /// Deletes the current verification token if it is expired.
    /// - parameter defaults: The defaults to delete the token from.
    static func flushIfNeeded(in defaults: UserDefaults = .shared()) {
        guard let token = current(in: defaults), token.isExpired else { return }
        flush(in: defaults)
    }

}
