//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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

public struct SearchResult {
    public var contacts: [ZMSearchUser]
    public var teamMembers: [ZMSearchUser]
    public var addressBook: [ZMSearchUser]
    public var directory: [ZMSearchUser]
    public var conversations: [ZMConversation]
    public var services: [ServiceUser]
}

extension SearchResult {

    public init?(payload: [AnyHashable: Any], query: SearchRequest.Query, searchOptions: SearchOptions, contextProvider: ContextProvider) {
        guard let documents = payload["documents"] as? [[String: Any]] else {
            return nil
        }

        let filteredDocuments = documents.filter { (document) -> Bool in
            let name = document["name"] as? String
            let handle = document["handle"] as? String
            return !query.isHandleQuery || name?.hasPrefix("@") ?? true || handle?.contains(query.string.lowercased()) ?? false
        }

        let searchUsers = ZMSearchUser.searchUsers(from: filteredDocuments, contextProvider: contextProvider)

        contacts = []
        addressBook = []
        directory = searchUsers.filter({ !$0.isConnected && !$0.isTeamMember })
        conversations = []
        services = []

        if searchOptions.contains(.teamMembers) &&
           searchOptions.isDisjoint(with: .excludeNonActiveTeamMembers) {
            teamMembers = searchUsers.filter({ $0.isTeamMember })
        } else {
            teamMembers = []
        }
    }

    public init?(servicesPayload servicesFullPayload: [AnyHashable: Any], query: String, contextProvider: ContextProvider) {
        guard let servicesPayload = servicesFullPayload["services"] as? [[String: Any]] else {
            return nil
        }

        let searchUsersServices = ZMSearchUser.searchUsers(from: servicesPayload, contextProvider: contextProvider)

        contacts = []
        teamMembers = []
        addressBook = []
        directory = []
        conversations = []
        services = searchUsersServices
    }

    public init?(userLookupPayload: [AnyHashable: Any], contextProvider: ContextProvider
    ) {
        guard let userLookupPayload = userLookupPayload as? [String: Any],
              let searchUser = ZMSearchUser.searchUser(from: userLookupPayload, contextProvider: contextProvider),
              searchUser.user == nil ||
              searchUser.user?.isTeamMember == false else {
            return nil
        }

        contacts = []
        teamMembers = []
        addressBook = []
        directory = [searchUser]
        conversations = []
        services = []
    }

    mutating func extendWithMembershipPayload(payload: MembershipListPayload) {
        payload.members.forEach { (membershipPayload) in
            let searchUser = teamMembers.first(where: { $0.remoteIdentifier == membershipPayload.userID })
            let permissions = membershipPayload.permissions.flatMap({ Permissions(rawValue: $0.selfPermissions) })
            searchUser?.updateWithTeamMembership(permissions: permissions, createdBy: membershipPayload.createdBy)
        }
    }

    mutating func filterBy(searchOptions: SearchOptions,
                           query: String,
                           contextProvider: ContextProvider) {
        guard searchOptions.contains(.excludeNonActivePartners) else { return }

        let selfUser = ZMUser.selfUser(in: contextProvider.viewContext)
        let isHandleQuery = query.hasPrefix("@")
        let queryWithoutAtSymbol = (isHandleQuery ? String(query[query.index(after: query.startIndex)...]) : query).lowercased()

        teamMembers = teamMembers.filter({
            $0.teamRole != .partner ||
            $0.teamCreatedBy == selfUser.remoteIdentifier ||
            isHandleQuery && $0.handle == queryWithoutAtSymbol
        })
    }

    func copy(on context: NSManagedObjectContext) -> SearchResult {

        let copiedConversations = conversations.compactMap { context.object(with: $0.objectID) as? ZMConversation }

        return SearchResult(contacts: contacts,
                            teamMembers: teamMembers,
                            addressBook: addressBook,
                            directory: directory,
                            conversations: copiedConversations,
                            services: services)
    }

    func union(withLocalResult result: SearchResult) -> SearchResult {
        return SearchResult(contacts: result.contacts,
                            teamMembers: result.teamMembers,
                            addressBook: result.addressBook,
                            directory: directory,
                            conversations: result.conversations,
                            services: services)
    }

    func union(withServiceResult result: SearchResult) -> SearchResult {
        return SearchResult(contacts: contacts,
                            teamMembers: teamMembers,
                            addressBook: addressBook,
                            directory: directory,
                            conversations: conversations,
                            services: result.services)
    }

    func union(withDirectoryResult result: SearchResult) -> SearchResult {
        return SearchResult(contacts: contacts,
                            teamMembers: Array(Set(teamMembers).union(result.teamMembers)),
                            addressBook: addressBook,
                            directory: result.directory,
                            conversations: conversations,
                            services: services)
    }

}
