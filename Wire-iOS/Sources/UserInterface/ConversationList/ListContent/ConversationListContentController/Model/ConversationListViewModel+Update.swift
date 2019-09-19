
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

extension ConversationListViewModel {

    ///TODO: for debug
    func toggleSort() {
        isFolderEnable = !isFolderEnable

        updateAllSections()
        delegate?.listViewModelShouldBeReloaded()
    }


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
        let sections: [Any]

        if isFolderEnable {
            sections = [inbox ?? [],
                        oneOnOneConversations ?? [],
                        conversations ?? []]
        } else {
            sections = [inbox ?? [],
                        conversations ?? []]
        }

        aggregatedItems = AggregateArray(sections: sections)
    }

    @discardableResult
    func updateForConvoType(sectionIndex: SectionIndex) -> Bool {
        let sectionNumber = sectionIndex.sectionNumber(isFolderEnable: isFolderEnable)

        if let oldConversationList = aggregatedItems.section(at: sectionNumber) as? Array<AnyHashable>,
            let newConversationList = newConversationList() as? Array<AnyHashable>,
            oldConversationList != newConversationList {

            ///TODO: use diff kit and retire requiresReload
            let startState = ZMOrderedSetState(orderedSet: NSOrderedSet(array: oldConversationList))
            let endState = ZMOrderedSetState(orderedSet: NSOrderedSet(array: newConversationList))
            let updatedState = ZMOrderedSetState(orderedSet: [])

            guard let changedIndexes = ZMChangedIndexes(start: startState, end: endState, updatedState: updatedState, moveType: ZMSetChangeMoveType.uiCollectionView) else { return true}

            if changedIndexes.requiresReload == true {
                reload()
            } else {
                // We need to capture the state of `newConversationList` to make sure that we are updating the value
                // of the list to the exact new state.
                // It is important to keep the data source of the collection view consistent, since
                // any inconsistency in the delta update would make it throw an exception.
                let modelUpdates = {
                    self.updateSection(sectionIndex, withItems: newConversationList)
                }
                delegate?.listViewModel(self, didUpdateSection: sectionNumber, using: modelUpdates, with: changedIndexes)
            }

            return true
        }

        return false
    }

    func updateConversationListAnimated() {
        ///TODO: folder and non folder mode handling
        if numberOfItems(inSection: SectionIndex.conversations.sectionNumber(isFolderEnable: isFolderEnable)) == 0 &&
            numberOfItems(inSection: SectionIndex.contactsConversations.sectionNumber(isFolderEnable: isFolderEnable)) == 0 {

            reload()
        } else if !updateForConvoType(sectionIndex: .conversations) {
            updateForConvoType(sectionIndex: .contactsConversations)
        }
    }

    func newOneOnOneConversationList() -> [ZMConversation]? {
        return ZMUserSession.shared()?.oneOnOneConversations.map { $0 }
    }

    @objc(selectItem:)
    @discardableResult
    func select(itemToSelect: Any?) -> Bool {
        guard let itemToSelect = itemToSelect else {
            selectedItem = nil
            delegate?.listViewModel(self, didSelectItem: nil)

            return false
        }

        let indexPath: IndexPath? = self.indexPath(forItem: itemToSelect as! NSObjectProtocol)

        // Couldn't find the item
        if indexPath == nil,
            let conversation = itemToSelect as? ZMConversation {

            let containedInOtherLists = conversation.revealClearedOrArchived(userSession: ZMUserSession.shared(), completionHandler: nil)

            if containedInOtherLists {
                selectedItem = itemToSelect
                delegate?.listViewModel(self, didSelectItem: itemToSelect)

                return true
            }

            return false
        }

        selectedItem = itemToSelect as? UITabBarItem
        delegate?.listViewModel(self, didSelectItem: itemToSelect)

        return true
    }

    @objc
    func subscribeToTeamsUpdates() {
        if let session = ZMUserSession.shared() {
            selfUserObserver = UserChangeInfo.add(observer: self, for: ZMUser.selfUser(), userSession: session)
        }
    }
}
