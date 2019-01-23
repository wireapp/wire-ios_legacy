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
import DifferenceKit

extension Int: Differentiable { }
extension String: Differentiable { }
extension AnyConversationMessageCellDescription: Differentiable {
    
    typealias DifferenceIdentifier = String
    
    var differenceIdentifier: String {
        return message!.objectIdentifier + String(describing: baseType)
    }
    
    override var debugDescription: String {
        return differenceIdentifier
    }
    
    func isContentEqual(to source: AnyConversationMessageCellDescription) -> Bool {
        return isConfigurationEqual(with: source)
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
    @objc public var editingMessage: ZMConversationMessage? = nil
    
    @objc public weak var conversationCellDelegate: ConversationMessageCellDelegate? = nil
    @objc public weak var messageActionResponder: MessageActionResponder? = nil
    
    @objc public var searchQueries: [String] = [] {
        didSet {
            currentSections = calculateSections()
            tableView.reloadData()
        }
    }
    
    @objc public var messages: [ZMConversationMessage] {
        return fetchController.fetchedObjects ?? []
    }
    
    var previousSections: [ArraySection<String, AnyConversationMessageCellDescription>] = []
    var currentSections: [ArraySection<String, AnyConversationMessageCellDescription>] = []
    
    func calculateSections() -> [ArraySection<String, AnyConversationMessageCellDescription>] {
        return messages.enumerated().map { tuple in
            let sectionIdentifier = tuple.element.objectIdentifier
            let context = self.context(for: tuple.element, at: tuple.offset, firstUnreadMessage: firstUnreadMessage, searchQueries: searchQueries)
            let sectionController = self.sectionController(for: tuple.element, at: tuple.offset)
            
            // Re-create cell description if the context has changed (message has been moved around or received new neighbours).
            if sectionController.context != context {
                sectionController.recreateCellDescriptions(in: context)
            }
            
            return ArraySection(model: sectionIdentifier, elements: sectionController.tableViewCellDescriptions)
        }
    }
    
    func calculateSections(updating sectionController: ConversationMessageSectionController) -> [ArraySection<String, AnyConversationMessageCellDescription>] {
        let sectionIdentifier = sectionController.message.objectIdentifier
        
        guard let section = currentSections.firstIndex(where: { $0.model == sectionIdentifier }) else { return currentSections }
        
        for (row, description ) in sectionController.tableViewCellDescriptions.enumerated() {
            if let cell = tableView.cellForRow(at: IndexPath(row: row, section: section)) {
                cell.accessibilityCustomActions = sectionController.actionController?.makeAccessibilityActions()
                description.configure(cell: cell, animated: true)
            }
        }

        let context = self.context(for: sectionController.message, at: section, firstUnreadMessage: firstUnreadMessage, searchQueries: searchQueries)
        sectionController.recreateCellDescriptions(in: context)
        
        var updatedSections = currentSections
        updatedSections[section] = ArraySection(model: sectionIdentifier, elements: sectionController.tableViewCellDescriptions)
        
        return updatedSections
    }
    
    @objc public init(conversation: ZMConversation, tableView: UpsideDownTableView, actionResponder: MessageActionResponder, cellDelegate: ConversationMessageCellDelegate) {
        self.messageActionResponder = actionResponder
        self.conversationCellDelegate = cellDelegate
        self.conversation = conversation
        self.tableView = tableView
        
        super.init()
        
        tableView.dataSource = self
        
        createFetchController()
    }
    
    @objc(cellForMessage:)
    func cell(for message: ZMConversationMessage) -> UITableViewCell? {
        guard let section = currentSections.firstIndex(where: { $0.model == message.objectIdentifier }) else { return nil }
        
        return tableView.cellForRow(at: IndexPath(row: 0, section: section))
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
    
    func sectionController(for message: ZMConversationMessage, at index: Int) -> ConversationMessageSectionController {
        if let cachedEntry = sectionControllers[message.objectIdentifier] {
            return cachedEntry
        }
        
        let context = self.context(for: message, at: index, firstUnreadMessage: firstUnreadMessage, searchQueries: self.searchQueries)
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
    
    @objc func sectionController(at sectionIndex: Int, in tableView: UITableView) -> ConversationMessageSectionController {
        let message = messages[sectionIndex]
        
        return sectionController(for: message, at: sectionIndex)
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
            // NOTE: we dispatch async because `didScroll(tableView:` can be called inside a `performBatchUpdate()`,
            // which would cause data source inconsistency if change the fetchLimit.
            DispatchQueue.main.async {
                self.fetchLimit = self.fetchLimit + ConversationTableViewDataSource.defaultBatchSize
            }
        }
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
        currentSections = calculateSections()
    }
}

extension ConversationTableViewDataSource: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        // no-op
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
        reloadSections(newSections: calculateSections())
    }
    
    func reloadSections(newSections: [ArraySection<String, AnyConversationMessageCellDescription>]) {
        previousSections = currentSections
        
        let stagedChangeset = StagedChangeset(source: previousSections, target: newSections)
        
        tableView.reload(using: stagedChangeset, with: .fade) { data in
            currentSections = data
        }
    }
    
}

extension ConversationTableViewDataSource: UITableViewDataSource {
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return currentSections.count
    }
    
    @objc
    func select(indexPath: IndexPath) {
        let sectionController = self.sectionController(at: indexPath.section, in: tableView)
        sectionController.didSelect()
        reloadSections(newSections: calculateSections(updating: sectionController))
    }
    
    @objc
    func deselect(indexPath: IndexPath) {
        let sectionController = self.sectionController(at: indexPath.section, in: tableView)
        sectionController.didDeselect()
        reloadSections(newSections: calculateSections(updating: sectionController))
    }
    
    @objc(highlightMessage:)
    func highlight(message: ZMConversationMessage) {
        guard let section = indexPath(for: message)?.section else {
            return
        }
        
        let sectionController = self.sectionController(at: section, in: tableView)
        sectionController.highlight(in: tableView, sectionIndex: section)
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentSections[section].elements.count
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
        let section = currentSections[indexPath.section]
        let cellDescription = section.elements[indexPath.row]
        
        registerCellIfNeeded(with: cellDescription, in: tableView)
        
        return cellDescription.makeCell(for: tableView, at: indexPath)
    }
}

extension ConversationTableViewDataSource: ConversationMessageSectionControllerDelegate {
    
    func messageSectionController(_ controller: ConversationMessageSectionController, didRequestRefreshForMessage message: ZMConversationMessage) {
        reloadSections(newSections: calculateSections(updating: controller))
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
