////
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

public enum ZMUserKeys {
    public static let RichProfile = "richProfile"
}

@objc public class UserRichProfileField: NSObject, Codable {
    public var type: String
    public var value: String
    @objc public init(type: String, value: String) {
        self.type = type
        self.value = value
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? UserRichProfileField else { return false }
        return self.type == other.type && self.value == other.value
    }

}

extension ZMUser {
    private enum Keys {
        static let RichProfile = "richProfile"
    }

    @NSManaged private var primitiveRichProfile: Data?
    public var richProfile: [UserRichProfileField] {
        get {
            self.willAccessValue(forKey: ZMUserKeys.RichProfile)
            let fields: [UserRichProfileField]
            if let data = primitiveRichProfile {
                fields = (try? JSONDecoder().decode([UserRichProfileField].self, from: data)) ?? []
            } else {
                fields = []
            }
            self.didAccessValue(forKey: ZMUserKeys.RichProfile)
            return fields
        }
        set {
            if newValue != richProfile {
                self.willChangeValue(forKey: ZMUserKeys.RichProfile)
                primitiveRichProfile = try? JSONEncoder().encode(newValue)
                self.didChangeValue(forKey: ZMUserKeys.RichProfile)
            }
        }
    }
}
