// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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

// MARK: - Current

extension APIVersion {

    private enum Keys: String {
        case apiVersion = "currentAPIVersion"
        case domain = "APIVersionDomain"
        case federation = "APIVersionFederation"
    }

    /// Where the api version information (i.e current version, local domain and federation
    /// flag) is stored.
    ///
    /// **Important:** set this value to a UserDefaults instance with a suite name
    /// matching the App Group id so that the values are accessible not only from
    /// the main app but also the app extensions.

    public static var storage: UserDefaults = .standard

    /// The API version against which all new backend requests should be made.
    ///
    /// The current version should be the highest value in common between the set
    /// of supported versions of the client (represented by `APIVersion` cases)
    /// and the set of supported versions of the backend (obtainable via `GET /api-version`).
    ///
    /// A `nil` value indicates that no version is selected yet and therefore one
    /// should be (re-)negotiated with the backend.

    public static var current: Self? {
        get {
            // Fetching an integer will default to 0 if no value exists for the key,
            // so explicitly check there is a value.
            guard storage.hasValue(for: Keys.apiVersion.rawValue) else { return nil }
            let storedValue = storage.integer(forKey: Keys.apiVersion.rawValue)
            return APIVersion(rawValue: Int32(storedValue))
        }

        set {
            storage.set(newValue?.rawValue, forKey: Keys.apiVersion.rawValue)
        }
    }

    /// The domain of the backend to which the app is connected to.

    public static var domain: String? {
        get { storage.string(forKey: Keys.domain.rawValue) }
        set { storage.set(newValue, forKey: Keys.domain.rawValue) }
    }

    /// Whether the connected backend has federation enabled.
    ///
    /// If the backend has federation enabled, then it may be federating with other backends.

    public static var isFederationEnabled: Bool {
        get { storage.bool(forKey: Keys.federation.rawValue) }
        set { storage.set(newValue, forKey: Keys.federation.rawValue) }
    }

}

// MARK: - Find the highest common version

extension APIVersion {

    public static func highestSupportedVersion(in versions: [Int32]) -> Self? {
        versions
            .compactMap { APIVersion(rawValue: Int32($0)) }
            .max()
    }

}

// MARK: - Helper

private extension UserDefaults {

    func hasValue(for key: String) -> Bool {
        return object(forKey: key) != nil
    }

}
