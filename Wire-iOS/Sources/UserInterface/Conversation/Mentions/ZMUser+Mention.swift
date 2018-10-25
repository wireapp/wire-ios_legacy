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

class HashBox<Type: NSObjectProtocol>: Hashable, Equatable {
    static func == (lhs: HashBox<Type>, rhs: HashBox<Type>) -> Bool {
        return lhs.value.isEqual(rhs.value)
    }
    
    let value: Type
    
    init(value: Type) {
        self.value = value
    }
    
    var hashValue: Int {
        return value.hash
    }
}



extension UserType {
    
    var nameTokens: [String] {
        return name?.components(separatedBy: CharacterSet.alphanumerics.inverted) ?? []
    }
}

extension ZMUser {
    static func searchForMentions(in users: [UserType], with query: String) -> [UserType] {
        
        let usersToSearch = users.filter { user in
            return !user.isSelfUser && !user.isServiceUser
        }
        
        if query == "" {
            return usersToSearch
        }
        
        let query = query.lowercased().normalizedForMentionSearch() as String
        let rules: [ ((UserType) -> Bool) ] = [
            { $0.name?.lowercased().normalizedForMentionSearch()?.hasPrefix(query) ?? false },
            { $0.nameTokens.first(where: { $0.lowercased().normalizedForMentionSearch()?.hasPrefix(query) ?? false }) != nil },
            { $0.handle?.lowercased().normalizedForMentionSearch()?.hasPrefix(query) ?? false },
            { $0.name?.lowercased().normalizedForMentionSearch().contains(query) ?? false },
            { $0.handle?.lowercased().normalizedForMentionSearch()?.contains(query) ?? false }
        ]
        
        var foundUsers = Set<HashBox<UserType>>()
        var results: [UserType] = []
        
        rules.forEach { rule in
            let matches = usersToSearch.filter({ rule($0) }).filter { !foundUsers.contains(HashBox(value: $0)) }
                .sorted(by: { $0.name < $1.name })
            foundUsers = foundUsers.union(matches.map(HashBox.init))
            results = results + matches
        }
        
        return results
    }
}
