//
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

public enum PushTokenStorage {

    private enum Keys: String {
        case pushToken = "PushToken"
    }

    static var storage: UserDefaults = .standard

    public static var pushToken: PushToken? {
        get {
            guard let storedValue = storage.object(forKey: Keys.pushToken.rawValue) as? Data else { return nil }
            return try? JSONDecoder().decode(PushToken.self, from: storedValue)
        }

        set {
            guard
               let value = newValue,
               let data = try? JSONEncoder().encode(value)
            else {
               return storage.set(nil, forKey: Keys.pushToken.rawValue)
            }
            storage.set(data, forKey: Keys.pushToken.rawValue)
        }
    }

}
