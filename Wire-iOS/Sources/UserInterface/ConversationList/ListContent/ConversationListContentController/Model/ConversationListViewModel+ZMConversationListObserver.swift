
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

fileprivate let log = ZMSLog(tag: "ConversationListViewModel")

extension ConversationListViewModel: ZMConversationListObserver {

    public func conversationInsideList(_ list: ZMConversationList, didChange changeInfo: ConversationChangeInfo) {
        delegate?.listViewModel(self, didUpdateConversationWithChange: changeInfo)
    }

    public func conversationListDidChange(_ changeInfo: ConversationListChangeInfo) {
        guard let userSession = ZMUserSession.shared() else { return }

        ///TODO: check the info instead of compare the lists
        if changeInfo.conversationList == ZMConversationList.conversations(inUserSession: userSession) {
            // If the section was empty in certain cases collection view breaks down on the big amount of conversations,
            // so we prefer to do the simple reload instead.

            updateConversationListAnimated() ///TODO: update oneOneOne also
        } else if changeInfo.conversationList == ZMConversationList.pendingConnectionConversations(inUserSession: userSession) {
            log.info("RELOAD contact requests")

            let sectionIndex = SectionIndex.contactRequests
            updateSection(sectionIndex)

            delegate?.listViewModel(self, didUpdateSectionForReload: sectionIndex.uIntValue)
        }
    }
}


extension ConversationListViewModel {

    @objc
    func updateAllSections() {
        updateSection(sectionIndexs: SectionIndex.allCases)
    }

    func updateSection(_ sectionIndex: SectionIndex, withItems items: [Any]? = nil) {
        updateSection(sectionIndexs: [sectionIndex], withItems: items)
    }

    /// This updates a specific section in the model, by copying the contents locally.
    /// Passing in a value of SectionIndexAll updates all sections. The reason why we need to keep
    /// local copies of the lists is that we get separate notifications for each list,
    /// which means that an update to one can render the collection view out of sync with the datasource.
    ///
    /// - Parameter sectionIndex: the section to update
    func updateSection(sectionIndexs: [SectionIndex], withItems items: [Any]? = nil) {
        if sectionIndexs == SectionIndex.allCases && items != nil {
            assert(true, "Update for all sections with proposed items is not allowed.")
        }

        for sectionIndex in sectionIndexs {
            switch sectionIndex {
            case .contactRequests:
                if let userSession = ZMUserSession.shared(), ZMConversationList.pendingConnectionConversations(inUserSession: userSession).count > 0 {
                    inbox = items ?? [self.contactRequestsItem]
                } else {
                    inbox = []
                }
            case .conversations:
                // Make a new copy of the conversation list
                conversations = items ?? newConversationList()
            case .contactsConversations:
                oneOnOneConversations = items ?? newOneOnOneConversationList()
            }
        }


        ///TODO: use a dictionary instead of fix size array
        // Re-create the aggregate array
        let sections: [Any] = [inbox ?? [],
                               oneOnOneConversations ?? [],
                               conversations ?? []]

        aggregatedItems = AggregateArray(sections: sections)
    }

    func updateConversationListAnimated() {
        if numberOfItems(inSection: SectionIndex.conversations.uIntValue) == 0 &&
           numberOfItems(inSection: SectionIndex.contactsConversations.uIntValue) == 0 {
            reload()
        } else if let oldConversationList = aggregatedItems.section(at: SectionIndex.conversations.uIntValue) as? Array<AnyHashable>,
            let newConversationList = newConversationList() as? Array<AnyHashable>,
            oldConversationList != newConversationList {

            let startState = ZMOrderedSetState(orderedSet: NSOrderedSet(array: oldConversationList))
            let endState = ZMOrderedSetState(orderedSet: NSOrderedSet(array: newConversationList))
            let updatedState = ZMOrderedSetState(orderedSet: [])

            guard let changedIndexes = ZMChangedIndexes(start: startState, end: endState, updatedState: updatedState, moveType: ZMSetChangeMoveType.uiCollectionView) else { return }

            if changedIndexes.requiresReload == true {
                reload()
            } else {
                // We need to capture the state of `newConversationList` to make sure that we are updating the value
                // of the list to the exact new state.
                // It is important to keep the data source of the collection view consistent, since
                // any inconsistency in the delta update would make it throw an exception.
                let modelUpdates = {
                    self.updateSection(.conversations, withItems: newConversationList)
                    }
                delegate?.listViewModel(self, didUpdateSection: SectionIndex.conversations.uIntValue, using: modelUpdates, with: changedIndexes)
            }
        } else if let oldConversationList = aggregatedItems.section(at: SectionIndex.contactsConversations.uIntValue) as? [ZMConversation],
            let newConversationList = newOneOnOneConversationList(),
            oldConversationList != newConversationList {

            let startState = ZMOrderedSetState(orderedSet: NSOrderedSet(array: oldConversationList))
            let endState = ZMOrderedSetState(orderedSet: NSOrderedSet(array: newConversationList))
            let updatedState = ZMOrderedSetState(orderedSet: [])

            guard let changedIndexes = ZMChangedIndexes(start: startState, end: endState, updatedState: updatedState, moveType: ZMSetChangeMoveType.uiCollectionView) else { return }

            if changedIndexes.requiresReload == true {
                reload()
            } else {
                // We need to capture the state of `newConversationList` to make sure that we are updating the value
                // of the list to the exact new state.
                // It is important to keep the data source of the collection view consistent, since
                // any inconsistency in the delta update would make it throw an exception.
                let modelUpdates = {
                    self.updateSection(.contactsConversations, withItems: newConversationList)
                }
                delegate?.listViewModel(self, didUpdateSection: SectionIndex.contactsConversations.uIntValue, using: modelUpdates, with: changedIndexes)

            }
        }
    }

    func newOneOnOneConversationList() -> [ZMConversation]? {
        return ZMUserSession.shared()?.oneOnOneConversations.map { $0 }
    }

}
