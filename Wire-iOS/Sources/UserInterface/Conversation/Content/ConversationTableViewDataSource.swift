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
    public static let defaultBatchSize = 30 // Magic number: amount of messages per screen (upper bound)
    public static let maximumFetchLimitSize = 90 // Magic number: maximum amount of messages visible.
    
    private var fetchController: NSFetchedResultsController<ZMMessage>!
    private var fetchOffset: Int = 0
    private var fetchLimit: Int = ConversationTableViewDataSource.defaultBatchSize

    public var registeredCells: [AnyClass] = []
    public var sectionControllers: [String: ConversationMessageSectionController] = [:]
    
    @objc func resetSectionControllers() {
        sectionControllers = [:]
    }
    
    public var actionControllers: [String: ConversationMessageActionController] = [:]
    
    private func performFetch() {
        createFetchController()
        tableView.reloadData()
    }
    
    private var readerPosition: Int = 0 {
        didSet {
            print("reader position is \(readerPosition)")
            
            // Check if user is about to see the oldest visible messages.
            if readerPosition + 10 > messages.count && !oldestMessageFetched {
                // Do we need to move the frame, or we can simply extend it up?
                if fetchLimit < type(of: self).maximumFetchLimitSize {
                    fetchLimit = fetchLimit + type(of: self).defaultBatchSize
                    performFetch()
                }
                else {
                    // TODO: Problem: method called twice in the row, for message 80 and 81. We increase the frame for 80, so 81 must be ignored.
                    
                    let lastPersistedMessageFrame = tableView.rectForRow(at: IndexPath(row: type(of: self).defaultBatchSize, section: 0))
                    let position = lastPersistedMessageFrame.origin.y
                    // Change the content offset (move down) when adjusting the fetchOffset
                    fetchOffset = fetchOffset + type(of: self).defaultBatchSize
                    performFetch()
                    tableView.contentOffset.y = tableView.contentOffset.y - position
                }
                
            }
            
            // Check if user is about to see the newest visible message.
            if readerPosition < 10 && !newestMessageFetched {
                
                if fetchOffset > 0 {
                    // TODO: Change the content offset (move up) when adjusting the fetchOffset
                    fetchOffset = fetchOffset - type(of: self).defaultBatchSize
                }
                
                performFetch()
            }
        }
    }
    
    public let conversation: ZMConversation
    public let tableView: UITableView
    
    @objc public var firstUnreadMessage: ZMConversationMessage?
    @objc public var selectedMessage: ZMConversationMessage? = nil
    @objc public var editingMessage: ZMConversationMessage? = nil {
        didSet {
            reconfigureVisibleSections()
        }
    }
    
    @objc public weak var conversationCellDelegate: ConversationCellDelegate? = nil
    @objc public weak var messageActionResponder: MessageActionResponder? = nil // TODO: assign it
    
    @objc public var searchQueries: [String] = [] {
        didSet {
            reconfigureVisibleSections()
        }
    }
    
    @objc public var messages: [ZMConversationMessage] {
        return fetchController.fetchedObjects ?? []
    }
    
    @objc public init(conversation: ZMConversation, tableView: UITableView) {
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
        let layoutProperties = self.layoutProperties(for: message, at: sectionIndex)
        
        let sectionController = ConversationMessageSectionController(message: message,
                                                                     context: context,
                                                                     layoutProperties: layoutProperties,
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
        let beforeGivenMessage = NSPredicate(format: "%K < %@", ZMMessageServerTimestampKey, serverTimestamp as NSDate)
    
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [validMessage, beforeGivenMessage])
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(ZMMessage.serverTimestamp), ascending: false)]
        
        let index = try! moc.count(for: fetchRequest)

        // Move the message window to show the message and previous
        let messagesShownBeforeGivenMessage = 5
        fetchOffset = index > messagesShownBeforeGivenMessage ? index - messagesShownBeforeGivenMessage : index
        
        completion?(index)
    }
    
    @objc public var oldestMessageFetched: Bool {
        guard let moc = conversation.managedObjectContext else {
            fatal("conversation.managedObjectContext == nil")
        }
        
        let fetchRequest = self.fetchRequest()
        let totalCount = try! moc.count(for: fetchRequest)
    
        return fetchOffset + ConversationTableViewDataSource.defaultBatchSize >= totalCount
    }
    
    public var newestMessageFetched: Bool {
        return fetchOffset == 0
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
        let topRowLocationInTableViewCoordinates = CGPoint(x: tableView.bounds.width / 2, y: tableView.contentOffset.y + tableView.bounds.height)
        
        let topRow = tableView.indexPathForRow(at: topRowLocationInTableViewCoordinates)?.row ?? tableView.numberOfRows(inSection: 0) - 1
        
        readerPosition = topRow
    }
    
    fileprivate func stopAudioPlayer(for indexPath: IndexPath) {
        guard let audioTrackPlayer = AppDelegate.shared().mediaPlaybackManager?.audioTrackPlayer,
              let sourceMessage = audioTrackPlayer.sourceMessage,
              sourceMessage == self.messages[indexPath.row] else {
            return
        }
        
        audioTrackPlayer.stop()
    }
    
    private func fetchRequest() -> NSFetchRequest<ZMMessage> {
        let fetchRequest = NSFetchRequest<ZMMessage>(entityName: ZMMessage.entityName())
        fetchRequest.fetchBatchSize = type(of: self).defaultBatchSize
        fetchRequest.predicate = conversation.visibleMessagesPredicate
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(ZMMessage.serverTimestamp), ascending: false)]
        return fetchRequest
    }
    
    private func createFetchController() {
        let fetchRequest = self.fetchRequest()
        fetchRequest.fetchLimit = fetchLimit
        fetchRequest.fetchOffset = fetchOffset
        
        fetchController = NSFetchedResultsController<ZMMessage>(fetchRequest: fetchRequest,
                                                                managedObjectContext: conversation.managedObjectContext!,
                                                                sectionNameKeyPath: nil,
                                                                cacheName: nil)
        
        self.fetchController.delegate = self
        try! fetchController.performFetch()
        
        firstUnreadMessage = conversation.firstUnreadMessage
    }
}

extension ConversationTableViewDataSource: NSFetchedResultsControllerDelegate {
    
    func reconfigureSectionController(at index: Int, tableView: UITableView) {
        guard let sectionController = self.sectionController(at: index, in: tableView) else { return }
        
        let context = self.context(for: sectionController.message, at: index, firstUnreadMessage: firstUnreadMessage, searchQueries: self.searchQueries)
        sectionController.configure(in: context, at: index, in: tableView)
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
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange anObject: Any,
                    at indexPath: IndexPath?,
                    for changeType: NSFetchedResultsChangeType,
                    newIndexPath: IndexPath?) {
        
        func rowToSection(_ indexPath: IndexPath) -> Int {
            return self.messages.count - 1 - indexPath.row
        }
        
        switch changeType {
        case .insert:
            guard let insertedIndexPath = newIndexPath else {
                fatal("Missing new index path")
            }
            
            tableView.insertSections([rowToSection(insertedIndexPath)], with: .fade)
        case .delete:
            guard let indexPathToRemove = indexPath else {
                fatal("Missing index path")
            }
            let deletedMessage = anObject as! ZMMessage
            
            sectionControllers.removeValue(forKey: deletedMessage.objectIdentifier)
            tableView.deleteSections([rowToSection(indexPathToRemove)], with: .fade)
            
            self.stopAudioPlayer(for: indexPathToRemove)
        case .update:
            guard let indexPathToUpdate = indexPath else {
                return
            }
            
            reconfigureSectionController(at: rowToSection(indexPathToUpdate), tableView: tableView)
        case .move:
            guard let indexPath = indexPath, let newIndexPath = newIndexPath else {
                return
            }
            
            tableView.moveSection(rowToSection(indexPath),
                                  toSection: rowToSection(newIndexPath))
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange sectionInfo: NSFetchedResultsSectionInfo,
                    atSectionIndex sectionIndex: Int,
                    for changeType: NSFetchedResultsChangeType) {
        fatal("Unexpected change")
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        // Re-evalulate visible cells in all sections, this is necessary because if a message is inserted/moved the
        // neighbouring messages may no longer want to display sender, toolbox or burst timestamp.
        reconfigureVisibleSections()
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
    
    func shouldShowDaySeparator(for message: ZMConversationMessage, at index: Int) -> Bool {
        guard let previous = messagePrevious(to: message, at: index)?.serverTimestamp, let current = message.serverTimestamp else { return false }
        return !Calendar.current.isDate(current, inSameDayAs: previous)
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
    
    static let burstSeparatorTimeDifference: TimeInterval = 60 * 45
    
    public func layoutProperties(for message: ZMConversationMessage, at index: Int) -> ConversationCellLayoutProperties {
        let layoutProperties = ConversationCellLayoutProperties()
        
        layoutProperties.showSender            = shouldShowSender(for: message, at: index)
        layoutProperties.showUnreadMarker      = (message == firstUnreadMessage)
        layoutProperties.showBurstTimestamp    = shouldShowBurstSeparator(for: message, at: index) || layoutProperties.showUnreadMarker
        layoutProperties.showDayBurstTimestamp = shouldShowDaySeparator(for: message, at: index)
        layoutProperties.topPadding            = topPadding(for: message, at: index, showingSender:layoutProperties.showSender, showingTimestamp:layoutProperties.showBurstTimestamp)
        layoutProperties.alwaysShowDeliveryState = shouldShowAlwaysDeliveryState(for: message)
        
        return layoutProperties
    }
    
    func shouldShowAlwaysDeliveryState(for message: ZMConversationMessage) -> Bool {
        if let sender = message.sender, sender.isSelfUser,
            let conversation = message.conversation,
            conversation.conversationType == .oneOnOne,
            let lastSentMessage = conversation.lastMessageSent(by: sender),
            message == lastSentMessage {
            return true
        }
        return false
    }
    
    func shouldShowSender(for message: ZMConversationMessage, at index: Int) -> Bool {
        if let systemMessageData = message.systemMessageData,
            systemMessageData.systemMessageType == .messageDeletedForEveryone {
            return true
        }
        
        if !message.isSystem {
            if !self.isPreviousSenderSame(forMessage: message, at: index) || message.updatedAt != nil {
                return true
            }
            
            if let previousMessage = self.messagePrevious(to: message, at: index) {
                return previousMessage.isKnock
            }
        }
        
        return false
    }
    
    func shouldShowBurstSeparator(for message: ZMConversationMessage, at index: Int) -> Bool {
        if let systemMessageData = message.systemMessageData {
            switch systemMessageData.systemMessageType {
            case .newClient, .conversationIsSecure, .reactivatedDevice, .newConversation, .usingNewDevice, .messageDeletedForEveryone, .missedCall, .performedCall:
                return false
            default:
                return true
            }
        }
        
        if message.isKnock {
            return false
        }
        
        if !message.isNormal && !message.isSystem {
            return false
        }
        
        guard let previousMessage = self.messagePrevious(to: message, at: index),
            let currentMessageServerTimestamp = message.serverTimestamp,
            let previousMessageServerTimestamp = previousMessage.serverTimestamp else {
                return true
        }
        
        return currentMessageServerTimestamp.timeIntervalSince(previousMessageServerTimestamp) > type(of: self).burstSeparatorTimeDifference
    }
    
    func topPadding(for message: ZMConversationMessage, at index: Int, showingSender: Bool, showingTimestamp: Bool) -> CGFloat {
        guard let previousMessage = self.messagePrevious(to: message, at: index) else {
            return self.topMargin(for: message, showingSender: showingSender, showingTimestamp: showingTimestamp)
        }
        
        return max(self.topMargin(for: message, showingSender: showingSender, showingTimestamp: showingTimestamp), self.bottomMargin(for: previousMessage))
    }
    
    func topMargin(for message: ZMConversationMessage, showingSender: Bool, showingTimestamp: Bool) -> CGFloat {
        if message.isSystem || showingTimestamp {
            return 16
        }
        else if message.isNormal {
            return 12
        }
        else {
            return 0
        }
    }
    
    func bottomMargin(for message: ZMConversationMessage) -> CGFloat {
        if message.isSystem {
            return 16
        }
        else if message.isNormal {
            return 12
        }
        else {
            return 0
        }
    }
    
    public func context(for message: ZMConversationMessage,
                        at index: Int,
                        firstUnreadMessage: ZMConversationMessage?,
                        searchQueries: [String]) -> ConversationMessageContext {
        let significantTimeInterval: TimeInterval = 60 * 45; // 45 minutes
        let isTimeIntervalSinceLastMessageSignificant: Bool
        
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
            previousMessageIsKnock: messagePrevious(to: message, at: index)?.isKnock == true
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
