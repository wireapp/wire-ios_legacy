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

extension ConversationMessageWindowTableViewAdapter: ConversationMessageSectionControllerDelegate {
    
    func messageSectionController(_ controller: ConversationMessageSectionController, didRequestRefreshForMessage message: ZMConversationMessage) {
        let section = messageWindow.messages.index(of: message)

        if section == NSNotFound {
            return
        }

        let controller = self.sectionController(at: section, in: tableView)
        controller?.configure(at: section, in: tableView)
    }
    
}

extension MessageWindowChangeInfo {
    var insertedMessages: [ZMConversationMessage] {
        return self.insertedIndexes.compactMap { conversationMessageWindow.messages[$0] as? ZMConversationMessage }
    }
}

extension ZMConversationMessage {
    var isSentFromThisDevice: Bool {
        guard let sender = sender else {
            return false
        }
        return sender.isSelfUser && deliveryState == .pending
    }
}

extension ConversationMessageWindowTableViewAdapter: ZMConversationMessageWindowObserver {
    
    func reconfigureSectionController(at index: Int, tableView: UITableView) {
        guard let sectionController = self.sectionController(at: index, in: tableView) else { return }
        
        let context = messageWindow.context(for: sectionController.message, firstUnreadMessage: firstUnreadMessage, searchQueries: self.searchQueries ?? [])
        sectionController.configure(in: context, at: index, in: tableView)
    }
    
    public func conversationWindowDidChange(_ changeInfo: MessageWindowChangeInfo) {
        
        let isLoadingInitialContent = messageWindow.messages.count == changeInfo.insertedIndexes.count && changeInfo.deletedIndexes.count == 0
        let isExpandingMessageWindow = changeInfo.insertedIndexes.count > 0 && changeInfo.insertedIndexes.last == messageWindow.messages.count - 1
        let shouldJumpToTheConversationEnd = changeInfo.insertedMessages.any(\.isSentFromThisDevice)
        
        stopAudioPlayer(forDeletedMessages: changeInfo.deletedObjects)
        
        if isLoadingInitialContent ||
            (isExpandingMessageWindow && changeInfo.deletedIndexes.count == 0) ||
            changeInfo.needsReload ||
            shouldJumpToTheConversationEnd {

            tableView.reloadData()
        } else {
            tableView.beginUpdates()
            
            if changeInfo.deletedIndexes.count > 0 {
                for deletedMessage in changeInfo.deletedObjects {
                    if let deletedMessage = deletedMessage as? ZMConversationMessage {
                        sectionControllers.removeObject(forKey: deletedMessage)
                    }
                }
                tableView.deleteSections(changeInfo.deletedIndexes, with: .fade)
            }
            
            if changeInfo.insertedIndexes.count > 0 {
                tableView.insertSections(changeInfo.insertedIndexes, with: .fade)
            }
            
            for movedIndexPair in changeInfo.zm_movedIndexPairs {
                tableView.moveSection(Int(movedIndexPair.from), toSection: Int(movedIndexPair.to))
            }
            
            tableView.endUpdates()
            
            // Re-evalulate visible cells in all sections, this is necessary because if a message is inserted/moved the
            // neighbouring messages may no longer want to display sender, toolbox or burst timestamp.
            reconfigureVisibleSections()
        }
        
        if shouldJumpToTheConversationEnd {
            // The action has to be performed on the next run loop, since the current one already has the call to scroll
            // the table view back to the previous position.
            self.tableView.scrollToBottom(animated: false)
            self.tableView.lockContentOffset = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.tableView.lockContentOffset = false
            }
        }
    }

    @objc func reconfigureVisibleSections() {
        tableView.beginUpdates()
        if let indexPathsForVisibleRows = tableView.indexPathsForVisibleRows {
            let visibleSections = Set(indexPathsForVisibleRows.map(\.section))
            for section in visibleSections {
                reconfigureSectionController(at: section, tableView: tableView)
            }
        }
        tableView.endUpdates()
    }
    
}

extension ConversationMessageWindowTableViewAdapter: UITableViewDataSource {

    @objc func sectionController(at sectionIndex: Int, in tableView: UITableView) -> ConversationMessageSectionController? {
        guard let message = messageWindow.messages.object(at: sectionIndex) as? ZMConversationMessage else { return nil }
        let messageIdentifier = message.objectIdentifier as NSString

        if let cachedEntry = sectionControllers.object(forKey: messageIdentifier) as? ConversationMessageSectionController {
            return cachedEntry
        }

        let context = messageWindow.context(for: message, firstUnreadMessage: firstUnreadMessage, searchQueries: self.searchQueries ?? [])
        let layoutProperties = messageWindow.layoutProperties(for: message, firstUnreadMessage: firstUnreadMessage)
        
        let sectionController = ConversationMessageSectionController(message: message,
                                                                     context: context,
                                                                     layoutProperties: layoutProperties,
                                                                     selected: message.isEqual(selectedMessage))
        sectionController.useInvertedIndices = true
        sectionController.cellDelegate = conversationCellDelegate
        sectionController.sectionDelegate = self
        sectionController.actionController = actionController(for: message)
        
        sectionControllers.setObject(sectionController, forKey: messageIdentifier)
        
        return sectionController
    }

    func previewableMessage(at indexPath: IndexPath, in tableView: UITableView) -> ZMConversationMessage? {
        guard let message = messageWindow.messages.object(at: indexPath.section) as? ZMConversationMessage else { return nil }
        let messageIdentifier = message.objectIdentifier as NSString

        guard let sectionController = sectionControllers.object(forKey: messageIdentifier) as? ConversationMessageSectionController else {
            return nil
        }

        let descriptions = sectionController.tableViewCellDescriptions

        guard descriptions.indices.contains(indexPath.row) else {
            return nil
        }

        let cellDescription = sectionController.tableViewCellDescriptions[indexPath.row]
        return cellDescription.supportsActions ? message : nil
    }
    
    @objc(indexPathForMessage:)
    public func indexPath(for message: ZMConversationMessage) -> IndexPath? {
        let section = self.messageWindow.messages.index(of: message)
        
        guard section != NSNotFound else {
            return nil
        }
        
        return IndexPath(row: 0, section: section)
    }
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return self.messageWindow.messages.count
    }
    
    @objc
    func select(indexPath: IndexPath) {
        sectionController(at: indexPath.section, in: tableView)?.didSelect(indexPath: indexPath, tableView: tableView)
    }
    
    @objc
    func deselect(indexPath: IndexPath) {
        sectionController(at: indexPath.section, in: tableView)?.didDeselect(indexPath: indexPath, tableView: tableView)
    }

    @objc(highlightMessage:)
    func highlight(message: ZMConversationMessage) {
        guard
            let section = indexPath(for: message)?.section,
            let sectionController = self.sectionController(at: section, in: tableView)
        else {
            return
        }

        sectionController.highlight(in: tableView, sectionIndex: section)
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionController = self.sectionController(at: section, in: tableView)!
        return sectionController.numberOfCells
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let sectionController = self.sectionController(at: indexPath.section, in: tableView)!
        
        for description in sectionController.cellDescriptions {
            registerCellIfNeeded(description, in: tableView)
        }
        
        return sectionController.makeCell(for: tableView, at: indexPath)
    }
}
