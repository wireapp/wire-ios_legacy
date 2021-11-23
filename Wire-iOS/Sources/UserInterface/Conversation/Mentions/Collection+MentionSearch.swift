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
import WireDataModel

extension Collection where Iterator.Element: UserType {

    func searchForMentions(withQuery query: String) -> [UserType] {
        let usersToSearch = filter { !$0.isSelfUser && !$0.isServiceUser }

        guard !query.isEmpty else { return usersToSearch }

        let query = query.lowercased().normalizedForMentionSearch() as String

        var rules = [(UserType) -> Bool]()
        rules.append({ $0.name?.lowercased().normalizedForMentionSearch()?.hasPrefix(query) ?? false })
        rules.append({ $0.nameTokens.first(where: { $0.lowercased().normalizedForMentionSearch()?.hasPrefix(query) ?? false }) != nil })
        rules.append({ $0.handle?.lowercased().normalizedForMentionSearch()?.hasPrefix(query) ?? false })
        rules.append({ $0.name?.lowercased().normalizedForMentionSearch().contains(query) ?? false })
        rules.append({ $0.handle?.lowercased().normalizedForMentionSearch()?.contains(query) ?? false })

        var foundUsers = Set<HashBoxUser>()
        var results: [UserType] = []

        rules.forEach { rule in
            let matches = usersToSearch
                .filter { rule($0) }
                .filter { !foundUsers.contains(HashBox(value: $0)) }
                .sorted { $0.name < $1.name }

            foundUsers = foundUsers.union(matches.map(HashBox.init))
            results += matches
        }

        return results
    }

}

private extension UserType {

    var nameTokens: [String] {
        return name?.components(separatedBy: CharacterSet.alphanumerics.inverted) ?? []
    }

}
