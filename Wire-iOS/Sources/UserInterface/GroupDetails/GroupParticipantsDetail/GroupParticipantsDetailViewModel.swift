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

class GroupParticipantsDetailViewModel: NSObject, SearchHeaderViewControllerDelegate {

    private let internalParticipants: [ZMBareUser]
    private var filterQuery: String?
    
    let selectedParticipants: [ZMBareUser]
    let conversation: ZMConversation
    var participantsDidChange: (() -> Void)? = nil
    
    var participants = [ZMBareUser]() {
        didSet { participantsDidChange?() }
    }

    init(participants: [ZMBareUser], selectedParticipants: [ZMBareUser], conversation: ZMConversation) {
        internalParticipants = participants
        self.conversation = conversation
        self.selectedParticipants = selectedParticipants.sorted { $0.displayName < $1.displayName }
        
        super.init()
        computeVisibleParticipants()
    }
    
    private func computeVisibleParticipants() {
        guard let query = filterQuery, query.isValidQuery else { return participants = internalParticipants }
        participants = (internalParticipants as NSArray).filtered(using: filterPredicate(for: query)) as! [ZMBareUser]
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
