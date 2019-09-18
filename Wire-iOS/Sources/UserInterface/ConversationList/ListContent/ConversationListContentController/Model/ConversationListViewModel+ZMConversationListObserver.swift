
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
        if changeInfo.conversationList == ZMConversationList.conversations(inUserSession: userSession) {
            // If the section was empty in certain cases collection view breaks down on the big amount of conversations,
            // so we prefer to do the simple reload instead.

            updateConversationListAnimated()
        } else if changeInfo.conversationList == ZMConversationList.pendingConnectionConversations(inUserSession: userSession) {
            log.info("RELOAD contact requests")
            updateSection(.contactRequests)
            delegate.listViewModel(self, didUpdateSectionForReload: UInt(.contactRequests))
        }
    }
}


extension ConversationListViewModel {
    /// This updates a specific section in the model, by copying the contents locally.
    /// Passing in a value of SectionIndexAll updates all sections. The reason why we need to keep
    /// local copies of the lists is that we get separate notifications for each list,
    /// which means that an update to one can render the collection view out of sync with the datasource.
    ///
    /// - Parameter sectionIndex: the section to update
    func updateSection(_ sectionIndex: SectionIndex) {
        updateSection(sectionIndex, withItems: nil)
    }

    func updateSection(_ sectionIndex: SectionIndex, withItems items: [AnyHashable]?) {
        if sectionIndex == .all && items != nil {
            assert(true, "Update for all sections with proposed items is not allowed.")
        }

        ///TODO: switch
        if sectionIndex == .contactRequests || sectionIndex == .all {
            if let userSession = ZMUserSession.shared(), ZMConversationList.pendingConnectionConversations(inUserSession: userSession).count > 0 {
                inbox = items ?? [contactRequestsItem]
            } else {
                inbox = []
            }
        }

        if sectionIndex == .conversations || sectionIndex == .all {
            // Make a new copy of the conversation list
            conversations = items ?? newConversationList()
        }


        ///TODO: use a dictionary instead of fix size array
        // Re-create the aggregate array
        var sections = [Any](repeating: 0, count: 2) ///TODO: still need first section?
        sections.append(inbox ?? [])
        sections.append(conversations ?? [])

        aggregatedItems = AggregateArray(sections: sections)
    }
}
