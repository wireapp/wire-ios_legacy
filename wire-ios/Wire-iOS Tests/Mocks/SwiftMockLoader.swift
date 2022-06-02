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

final class SwiftMockLoader {

    class func mockUsers() -> [MockUserType] {
        return mockUsers(fromResource: "people-01.json")
    }

    class func mockUsers(fromResource resource: String) -> [MockUserType] {
        let fileName = (resource as NSString).deletingPathExtension
        let fileExtension = (resource as NSString).pathExtension

        guard let url = Bundle(for: self).url(forResource: fileName, withExtension: fileExtension) else {
            fatalError("Couldn't find resource in bundle: \(resource)")
        }

        guard let data = try? Data(contentsOf: url) else {
            fatalError("Couldn't load data from resource: \(resource)")
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode([MockUserType].self, from: data)
        } catch {
            fatalError("Couldn't decode Mockuser: \(error.localizedDescription)")
        }
    }

}
