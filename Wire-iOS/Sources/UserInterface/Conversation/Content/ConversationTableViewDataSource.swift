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
// but WITHOUT ANY WARRANTY without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
//

import Foundation
import WireDataModel
import WireUtilities

extension ZMConversationMessage {
    var isSentFromThisDevice: Bool {
        guard let sender = sender else {
            return false
        }
        return sender.isSelfUser && deliveryState == .pending
    }
}

final class ConversationTableViewDataSource: NSObject {
    public static let defaultBatchSize = 30 // Magic number: amount of messages per screen (upper bound).
    
    private var fetchController: NSFetchedResultsController<ZMMessage>!
    
    private var fetchLimit = defaultBatchSize {
        didSet {
            createFetchController()
            tableView.reloadData()
        }
    }
    
    public var registeredCells: [AnyClass] = []
    public var sectionControllers: [String: ConversationMessageSectionController] = [:]
    @objc private(set) var hasFetchedAllMessages: Bool = false
    
    @objc func resetSectionControllers() {
        sectionControllers = [:]
    }
    
    public var actionControllers: [String: ConversationMessageActionController] = [:]
    
    public let conversation: ZMConversation
    public let tableView: UpsideDownTableView
    
    @objc public var firstUnreadMessage: ZMConversationMessage?
    @objc public var selectedMessage: ZMConversationMessage? = nil
    @objc public var editingMessage: ZMConversationMessage? = nil {
        didSet {
            reconfigureVisibleSections()
        }
    }
    
    @objc public weak var conversationCellDelegate: ConversationMessageCellDelegate? = nil
    @objc public weak var messageActionResponder: MessageActionResponder? = nil
    
    @objc public var searchQueries: [String] = [] {
        didSet {
            reconfigureVisibleSections()
        }
    }
    
    @objc public var messages: [ZMConversationMessage] {
        return fetchController.fetchedObjects ?? []
    }
    
    var messagesBeforeUpdate: [ZMConversationMessage] = []
    var updatedMessages: [ZMConversationMessage] = []
    
    @objc public init(conversation: ZMConversation, tableView: UpsideDownTableView) {
        self.conversation = conversation
        self.tableView = tableView
        
        super.init()
        
        tableView.dataSource = self
        
        createFetchController()
    }
    
    @objc func actionController(for message: ZMConversationMessage) -> ConversationMessageActionController {
        if let cachedEntry = actionControllers[message.objectIdentifier] {
            return cachedEntry
        }
        let actionController = ConversationMessageActionController(responder: self.messageActionResponder,
                                                                   message: message,
                                                                   context: .content)
        actionControllers[message.objectIdentifier] = actionController
        
        return actionController
        
    }
    
    @objc func sectionController(at sectionIndex: Int, in tableView: UITableView) -> ConversationMessageSectionController? {
        let message = messages[sectionIndex]
        
        if let cachedEntry = sectionControllers[message.objectIdentifier] {
            return cachedEntry
        }
        
        let context = self.context(for: message, at: sectionIndex, firstUnreadMessage: firstUnreadMessage, searchQueries: self.searchQueries)
        
        let sectionController = ConversationMessageSectionController(message: message,
                                                                     context: context,
                                                                     selected: message.isEqual(selectedMessage))
        sectionController.useInvertedIndices = true
        sectionController.cellDelegate = conversationCellDelegate
        sectionController.sectionDelegate = self
        sectionController.actionController = actionController(for: message)
        
        sectionControllers[message.objectIdentifier] = sectionController
        
        return sectionController
    }
    
    func previewableMessage(at indexPath: IndexPath, in tableView: UITableView) -> ZMConversationMessage? {
        let message = messages[indexPath.section]
        
        guard let sectionController = sectionControllers[message.objectIdentifier] else {
            return nil
        }
        
        let descriptions = sectionController.tableViewCellDescriptions
        
        guard descriptions.indices.contains(indexPath.row) else {
            return nil
        }
        
        let cellDescription = sectionController.tableViewCellDescriptions[indexPath.row]
        return cellDescription.supportsActions ? message : nil
    }
    
    public func find(_ message: ZMConversationMessage, completion: ((Int?)->())? = nil) {
        guard let moc = conversation.managedObjectContext, let serverTimestamp = message.serverTimestamp else {
            fatal("conversation.managedObjectContext == nil or serverTimestamp == nil")
        }
        
        let fetchRequest = NSFetchRequest<ZMMessage>(entityName: ZMMessage.entityName())
        let validMessage = conversation.visibleMessagesPredicate!
        let beforeGivenMessage = NSPredicate(format: "%K > %@", ZMMessageServerTimestampKey, serverTimestamp as NSDate)
            
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [validMessage, beforeGivenMessage])
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(ZMMessage.serverTimestamp), ascending: false)]
        
        let index = try! moc.count(for: fetchRequest)

        // Move the message window to show the message and previous
        let messagesShownBeforeGivenMessage = 5
        let offset = index > messagesShownBeforeGivenMessage ? index - messagesShownBeforeGivenMessage : index
        fetchLimit = offset + ConversationTableViewDataSource.defaultBatchSize
        
        completion?(index)
    }
    
    @objc func indexOfMessage(_ message: ZMConversationMessage) -> Int {
        guard let index = index(of: message) else {
            return NSNotFound
        }
        return index
    }
    
    public func index(of message: ZMConversationMessage) -> Int? {
        if let indexPath = fetchController.indexPath(forObject: message as! ZMMessage) {
            return indexPath.row
        }
        else {
            return nil
        }
    }
    
    @objc(indexPathForMessage:)
    public func indexPath(for message: ZMConversationMessage) -> IndexPath? {
        guard let section = index(of: message) else {
            return nil
        }
        
        return IndexPath(row: 0, section: section)
    }
    
    @objc(tableViewDidScroll:) public func didScroll(tableView: UITableView) {
        let scrolledToTop = (tableView.contentOffset.y + tableView.bounds.height) - tableView.contentSize.height > 0
        
        if scrolledToTop, !hasFetchedAllMessages {
            fetchLimit = fetchLimit + ConversationTableViewDataSource.defaultBatchSize
        }
    }
    
    fileprivate func stopAudioPlayer(for messages: Set<ZMMessage>) {
        guard let audioTrackPlayer = AppDelegate.shared().mediaPlaybackManager?.audioTrackPlayer,
              let sourceMessage = audioTrackPlayer.sourceMessage as? ZMMessage,
              messages.contains(sourceMessage) else {
            return
        }
        
        audioTrackPlayer.stop()
    }
    
    private func fetchRequest() -> NSFetchRequest<ZMMessage> {
        let fetchRequest = NSFetchRequest<ZMMessage>(entityName: ZMMessage.entityName())
        fetchRequest.predicate = conversation.visibleMessagesPredicate
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(ZMMessage.serverTimestamp), ascending: false)]
        return fetchRequest
    }
    
    private func createFetchController() {
        let fetchRequest = self.fetchRequest()
        fetchRequest.fetchLimit = fetchLimit
        fetchRequest.fetchOffset = 0
        
        fetchController = NSFetchedResultsController<ZMMessage>(fetchRequest: fetchRequest,
                                                                managedObjectContext: conversation.managedObjectContext!,
                                                                sectionNameKeyPath: nil,
                                                                cacheName: nil)
        
        self.fetchController.delegate = self
        try! fetchController.performFetch()
        
        hasFetchedAllMessages =  messages.count < fetchRequest.fetchLimit
        firstUnreadMessage = conversation.firstUnreadMessage
    }
}

extension ConversationTableViewDataSource: NSFetchedResultsControllerDelegate {
    
    func reconfigureSectionController(at index: Int, tableView: UITableView) {
        guard let sectionController = self.sectionController(at: index, in: tableView) else { return }
        
        let context = self.context(for: sectionController.message, at: index, firstUnreadMessage: firstUnreadMessage, searchQueries: self.searchQueries)
        sectionController.configure(in: context, at: index, in: tableView)
    }
    
    func reconfigureVisibleSections(doBatchUpdate: Bool) {
        tableView.beginUpdates()
        if let indexPathsForVisibleRows = tableView.indexPathsForVisibleRows {
            let visibleSections = Set(indexPathsForVisibleRows.map(\.section))
            for section in visibleSections {
                reconfigureSectionController(at: section, tableView: tableView)
            }
        }
        tableView.endUpdates()
    }
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        messagesBeforeUpdate = messages
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange anObject: Any,
                    at indexPath: IndexPath?,
                    for changeType: NSFetchedResultsChangeType,
                    newIndexPath: IndexPath?) {
        // no-op
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange sectionInfo: NSFetchedResultsSectionInfo,
                    atSectionIndex sectionIndex: Int,
                    for changeType: NSFetchedResultsChangeType) {
        // no-op
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        applyDeltaChanges()
    }
    
    func applyDeltaChanges() {
        let old = ZMOrderedSetState(orderedSet: NSOrderedSet(array: messagesBeforeUpdate))
        let new = ZMOrderedSetState(orderedSet: NSOrderedSet(array: messages))
        
        guard old != new else { return }
        
        let update = ZMOrderedSetState(orderedSet: NSOrderedSet())
        let changeInfo = ZMChangedIndexes(start: old, end: new, updatedState: update, moveType: .nsTableView)!
        
        let isLoadingInitialContent = messages.count == changeInfo.insertedIndexes.count && changeInfo.deletedIndexes.count == 0
        let isExpandingMessageWindow = changeInfo.insertedIndexes.count > 0 && changeInfo.insertedIndexes.last == messages.count - 1
        let shouldJumpToTheConversationEnd = changeInfo.insertedIndexes.compactMap { messages[$0] }.any(\.isSentFromThisDevice)
        
        if let deletedObjects = changeInfo.deletedObjects {
            stopAudioPlayer(for: Set(deletedObjects.map { $0 as! ZMMessage }))
        }
        
        if isLoadingInitialContent ||
            (isExpandingMessageWindow && changeInfo.deletedIndexes.count == 0) ||
            shouldJumpToTheConversationEnd {
            
            tableView.reloadData()
        } else {
            tableView.beginUpdates()
            
            if changeInfo.deletedIndexes.count > 0 {
                for deletedMessage in changeInfo.deletedObjects {
                    if let deletedMessage = deletedMessage as? ZMConversationMessage {
                        sectionControllers.removeValue(forKey: deletedMessage.objectIdentifier)
                    }
                }
                tableView.deleteSections(changeInfo.deletedIndexes, with: .fade)
            }
            
            if changeInfo.insertedIndexes.count > 0 {
                tableView.insertSections(changeInfo.insertedIndexes, with: .fade)
            }
            
            changeInfo.enumerateMovedIndexes { (from, to) in
                self.tableView.moveSection(Int(from), toSection: Int(to))
            }
            
            tableView.endUpdates()
            
            // Re-evalulate visible cells in all sections, this is necessary because if a message is inserted/moved the
            // neighbouring messages may no longer want to display sender, toolbox or burst timestamp.
            reconfigureVisibleSections()
        }
        
        if shouldJumpToTheConversationEnd {
            // The action has to be performed on the next run loop, since the current one already has the call to scroll
            // the table view back to the previous position.
            tableView.scrollToBottom(animated: false)
            tableView.lockContentOffset = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.tableView.lockContentOffset = false
            }
        }
        
        messagesBeforeUpdate = []
    }
    
    @objc
    func selectLastMessage() {
        
        if let lastMessage = conversation.recentMessages.last,
            let lastIndex = self.indexPath(for: lastMessage) {
            
            if let selectedMessage = selectedMessage,
                let selectedIndex = self.indexPath(for: selectedMessage) {
                self.selectedMessage = nil
                deselect(indexPath: selectedIndex)
                tableView.deselectRow(at: selectedIndex, animated: true)
            }
            
            self.selectedMessage = lastMessage
            select(indexPath: lastIndex)
            tableView.selectRow(at: lastIndex, animated: true, scrollPosition: .none)
        }
    }
    
    @objc
    func reconfigureVisibleSections() {
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

extension ConversationTableViewDataSource: UITableViewDataSource {
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return messages.count
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
    
    func registerCellIfNeeded(with description: AnyConversationMessageCellDescription, in tableView: UITableView) {
        guard !registeredCells.contains(where: { obj in
            obj == description.baseType
        }) else {
            return
        }
        
        description.register(in: tableView)
        registeredCells.append(description.baseType)
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let sectionController = self.sectionController(at: indexPath.section, in: tableView)!
        
        for description in sectionController.cellDescriptions {
            registerCellIfNeeded(with: description, in: tableView)
        }
        
        return sectionController.makeCell(for: tableView, at: indexPath)
    }
}

extension ConversationTableViewDataSource: ConversationMessageSectionControllerDelegate {
    
    func messageSectionController(_ controller: ConversationMessageSectionController, didRequestRefreshForMessage message: ZMConversationMessage) {
        guard let section = self.index(of: message) else {
            return
        }
        
        let controller = self.sectionController(at: section, in: tableView)
        controller?.configure(at: section, in: tableView)
    }
    
}


extension ConversationTableViewDataSource {
    
    func messagePrevious(to message: ZMConversationMessage, at index: Int) -> ZMConversationMessage? {
        guard (index + 1) < messages.count else {
            return nil
        }
        
        return messages[index + 1]
    }
    
    func isPreviousSenderSame(forMessage message: ZMConversationMessage?, at index: Int) -> Bool {
        guard let message = message,
            Message.isNormal(message),
            !Message.isKnock(message) else { return false }
        
        guard let previousMessage = messagePrevious(to: message, at: index),
            previousMessage.sender == message.sender,
            Message.isNormal(previousMessage) else { return false }
        
        return true
    }
    
    public func context(for message: ZMConversationMessage,
                        at index: Int,
                        firstUnreadMessage: ZMConversationMessage?,
                        searchQueries: [String]) -> ConversationMessageContext {
        let significantTimeInterval: TimeInterval = 60 * 45; // 45 minutes
        let isTimeIntervalSinceLastMessageSignificant: Bool
        let previousMessage = messagePrevious(to: message, at: index)
        
        if let timeIntervalToPreviousMessage = timeIntervalToPreviousMessage(from: message, at: index) {
            isTimeIntervalSinceLastMessageSignificant = timeIntervalToPreviousMessage > significantTimeInterval
        } else {
            isTimeIntervalSinceLastMessageSignificant = false
        }
        
        return ConversationMessageContext(
            isSameSenderAsPrevious: isPreviousSenderSame(forMessage: message, at: index),
            isTimeIntervalSinceLastMessageSignificant: isTimeIntervalSinceLastMessageSignificant,
            isFirstMessageOfTheDay: isFirstMessageOfTheDay(for: message, at: index),
            isFirstUnreadMessage: message.isEqual(firstUnreadMessage),
            isLastMessage: index == 0,
            searchQueries: searchQueries,
            previousMessageIsKnock: previousMessage?.isKnock == true,
            spacing: message.isSystem || previousMessage?.isSystem == true || isTimeIntervalSinceLastMessageSignificant ? 16 : 12
        )
    }
    
    fileprivate func timeIntervalToPreviousMessage(from message: ZMConversationMessage, at index: Int) -> TimeInterval? {
        guard let currentMessageTimestamp = message.serverTimestamp, let previousMessageTimestamp = messagePrevious(to: message, at: index)?.serverTimestamp else {
            return nil
        }
        
        return currentMessageTimestamp.timeIntervalSince(previousMessageTimestamp)
    }
    
    fileprivate func isFirstMessageOfTheDay(for message: ZMConversationMessage, at index: Int) -> Bool {
        guard let previous = messagePrevious(to: message, at: index)?.serverTimestamp, let current = message.serverTimestamp else { return false }
        return !Calendar.current.isDate(current, inSameDayAs: previous)
    }
    
}
