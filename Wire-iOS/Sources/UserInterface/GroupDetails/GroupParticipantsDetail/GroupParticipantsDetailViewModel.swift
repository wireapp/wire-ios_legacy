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

fileprivate extension String {
    var isValidQuery: Bool {
        return !isEmpty && self != "@"
    }
}

fileprivate extension ZMUser {
    private func name(in conversation: ZMConversation) -> String {
        return conversation.activeParticipants.contains(self)
            ? displayName(in: conversation)
            : displayName
    }
}

class GroupParticipantsDetailViewModel: NSObject, SearchHeaderViewControllerDelegate, ZMConversationObserver {

    private var internalParticipants: [UserType]
    private var filterQuery: String?
    
    let selectedParticipants: [UserType]
    let conversation: ZMConversation
    var participantsDidChange: (() -> Void)? = nil
    
    fileprivate var token: NSObjectProtocol?

    var indexOfFirstSelectedParticipant: Int? {
        guard let first = selectedParticipants.first as? ZMUser else { return nil }
        return internalParticipants.index {
            ($0 as? ZMUser)?.remoteIdentifier == first.remoteIdentifier
        }
    }
    
    var participants = [UserType]() {
        didSet { participantsDidChange?() }
    }

    init(participants: [UserType], selectedParticipants: [UserType], conversation: ZMConversation) {
        internalParticipants = participants
        self.conversation = conversation
        self.selectedParticipants = selectedParticipants.sorted { $0.displayName < $1.displayName }
        
        super.init()
        token = ConversationChangeInfo.add(observer: self, for: conversation)
        computeVisibleParticipants()
    }
    
    func isUserSelected(_ user: UserType) -> Bool {
        guard let id = (user as? ZMUser)?.remoteIdentifier else { return false }
        return selectedParticipants.contains { ($0 as? ZMUser)?.remoteIdentifier == id}
    }
    
    private func computeVisibleParticipants() {
        guard let query = filterQuery, query.isValidQuery else { return participants = internalParticipants }
        participants = (internalParticipants as NSArray).filtered(using: filterPredicate(for: query)) as! [UserType]
    }
    
    private func filterPredicate(for query: String) -> NSPredicate {
        var predicates = [
            NSPredicate(format: "name contains[cd] %@", query),
            NSPredicate(format: "handle contains[cd] %@", query)
        ]

        if query.hasPrefix("@") {
            predicates.append(.init(format: "handle contains[cd] %@", String(query.dropFirst())))
        }
        
        return NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
    }
    
    func conversationDidChange(_ changeInfo: ConversationChangeInfo) {
        guard changeInfo.participantsChanged else { return }
        internalParticipants = conversation.sortedOtherParticipants
        computeVisibleParticipants()
    }
    
    // MARK: - SearchHeaderViewControllerDelegate
    
    func searchHeaderViewController(
        _ searchHeaderViewController: SearchHeaderViewController,
        updatedSearchQuery query: String
        ) {
        filterQuery = query
        computeVisibleParticipants()
    }
    
    func searchHeaderViewControllerDidConfirmAction(_ searchHeaderViewController: SearchHeaderViewController) {
        // no-op
    }

}
