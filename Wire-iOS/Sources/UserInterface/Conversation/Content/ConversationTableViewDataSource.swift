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

import WireDataModel
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
        guard let sender = senderUser else {
            return false
        }
        return sender.isSelfUser && deliveryState == .pending
    }
}

final class ConversationTableViewDataSource: NSObject {
    static let defaultBatchSize = 30 // Magic number: amount of messages per screen (upper bound).

    private var fetchController: NSFetchedResultsController<ZMMessage>?
    private var lastFetchedObjectCount: Int = 0

    var registeredCells: [AnyClass] = []
    var sectionControllers: [String: ConversationMessageSectionController] = [:]

    private(set) var hasOlderMessagesToLoad = false
    private(set) var hasNewerMessagesToLoad = false

    func resetSectionControllers() {
        sectionControllers = [:]
        calculateSections()
    }

    var actionControllers: [String: ConversationMessageActionController] = [:]

    let conversation: ZMConversation
    let tableView: UpsideDownTableView

    var firstUnreadMessage: ZMConversationMessage?
    var selectedMessage: ZMConversationMessage?
    var editingMessage: ZMConversationMessage?

    weak var conversationCellDelegate: ConversationMessageCellDelegate?
    weak var messageActionResponder: MessageActionResponder?

    var searchQueries: [String] = [] {
        didSet {
            currentSections = calculateSections()
            tableView.reloadData()
        }
    }

    var messages: [ZMConversationMessage] {
        // NOTE: We limit the number of messages to the `lastFetchedObjectCount` since the
        // NSFetchResultsController will add objects to `fetchObjects` if they are modified after
        // the initial fetch, which results in unwanted table view updates. This is normally what
        // we want when new message arrive but not when fetchOffset > 0.

        if fetchController?.fetchRequest.fetchOffset > 0 {
            return Array(fetchController?.fetchedObjects?.suffix(lastFetchedObjectCount) ?? [])
        } else {
            return fetchController?.fetchedObjects ?? []
        }
    }

    var previousSections: [ArraySection<String, AnyConversationMessageCellDescription>] = []
    var currentSections: [ArraySection<String, AnyConversationMessageCellDescription>] = []

    /// calculate cell sections
    ///
    /// - Parameter forceRecalculate: true if force recreate cell with context check
    /// - Returns: arraySection of cell desctiptions
    @discardableResult
    func calculateSections(forceRecalculate: Bool = false) -> [ArraySection<String, AnyConversationMessageCellDescription>] {
        return messages.enumerated().map { tuple in
            let sectionIdentifier = tuple.element.objectIdentifier
            let context = self.context(for: tuple.element, at: tuple.offset, firstUnreadMessage: firstUnreadMessage, searchQueries: searchQueries)
            let sectionController = self.sectionController(for: tuple.element, at: tuple.offset)

            // Re-create cell description if the context has changed (message has been moved around or received new neighbours).
            if sectionController.context != context || forceRecalculate {
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

    init(conversation: ZMConversation, tableView: UpsideDownTableView, actionResponder: MessageActionResponder, cellDelegate: ConversationMessageCellDelegate) {
        self.messageActionResponder = actionResponder
        self.conversationCellDelegate = cellDelegate
        self.conversation = conversation
        self.tableView = tableView

        super.init()

        tableView.dataSource = self
    }

    func section(for message: ZMConversationMessage) -> Int? {
        return currentSections.firstIndex(where: { $0.model == message.objectIdentifier })
    }

    func actionController(for message: ZMConversationMessage) -> ConversationMessageActionController {
        if let cachedEntry = actionControllers[message.objectIdentifier] {
            return cachedEntry
        }

        let actionController = ConversationMessageActionController(responder: messageActionResponder,
                                                                   message: message,
                                                                   context: .content,
                                                                   view: tableView)

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

    func sectionController(at sectionIndex: Int, in tableView: UITableView) -> ConversationMessageSectionController {
        let message = messages[sectionIndex]

        return sectionController(for: message, at: sectionIndex)
    }

    func loadMessages(near message: ZMConversationMessage,
                      forceRecalculate: Bool = false,
                      completion: ((IndexPath?) -> Void)? = nil) {
        guard let moc = conversation.managedObjectContext, let serverTimestamp = message.serverTimestamp else {
            if message.hasBeenDeleted {
                completion?(nil)
                return
            } else {
                fatal("conversation.managedObjectContext == nil or serverTimestamp == nil")
            }
        }

        let fetchRequest = NSFetchRequest<ZMMessage>(entityName: ZMMessage.entityName())
        let validMessage = conversation.visibleMessagesPredicate!

        let beforeGivenMessage = NSPredicate(format: "%K > %@", ZMMessageServerTimestampKey, serverTimestamp as NSDate)

        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [validMessage, beforeGivenMessage])
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(ZMMessage.serverTimestamp), ascending: false)]

        // It's the number of messages that are newer than the `message`
        let index = try! moc.count(for: fetchRequest)

        let offset = max(0, index - ConversationTableViewDataSource.defaultBatchSize)
        let limit = ConversationTableViewDataSource.defaultBatchSize * 2

        loadMessages(offset: offset, limit: limit, forceRecalculate: forceRecalculate)

        let indexPath = self.topIndexPath(for: message)
        completion?(indexPath)
    }

    func loadMessages(offset: Int = 0,
                      limit: Int = ConversationTableViewDataSource.defaultBatchSize,
                      forceRecalculate: Bool = false) {
        let fetchRequest = self.fetchRequest()
        fetchRequest.fetchLimit = limit + 5 // We need to fetch a bit more than requested so that there is overlap between messages in different fetches
        fetchRequest.fetchOffset = offset

        fetchController = NSFetchedResultsController<ZMMessage>(fetchRequest: fetchRequest,
                                                                managedObjectContext: conversation.managedObjectContext!,
                                                                sectionNameKeyPath: nil,
                                                                cacheName: nil)

        fetchController?.delegate = self
        try! fetchController?.performFetch()

        lastFetchedObjectCount = fetchController?.fetchedObjects?.count ?? 0
        hasOlderMessagesToLoad = messages.count == fetchRequest.fetchLimit
        hasNewerMessagesToLoad = offset > 0
        firstUnreadMessage = conversation.firstUnreadMessage
        currentSections = calculateSections(forceRecalculate: forceRecalculate)
        tableView.reloadData()
    }

    private func loadOlderMessages() {
        guard let currentOffset = fetchController?.fetchRequest.fetchOffset,
              let currentLimit = fetchController?.fetchRequest.fetchLimit else { return }

        let newLimit = currentLimit + ConversationTableViewDataSource.defaultBatchSize

        loadMessages(offset: currentOffset, limit: newLimit)
    }

    func loadNewerMessages() {
        guard let currentOffset = fetchController?.fetchRequest.fetchOffset,
            let currentLimit = fetchController?.fetchRequest.fetchLimit else { return }

        let newOffset = max(0, currentOffset - ConversationTableViewDataSource.defaultBatchSize)

        loadMessages(offset: newOffset, limit: currentLimit)
    }

    func indexOfMessage(_ message: ZMConversationMessage) -> Int {
        guard let index = index(of: message) else {
            return NSNotFound
        }
        return index
    }

    func index(of message: ZMConversationMessage) -> Int? {
        if let indexPath = fetchController?.indexPath(forObject: message as! ZMMessage) {
            return indexPath.row
        } else {
            return nil
        }
    }

    func topIndexPath(for message: ZMConversationMessage) -> IndexPath? {
        guard let section = index(of: message) else {
            return nil
        }

        // The table view is upside down. The first visible cell of the message has the last index
        // in the message section.
        let numberOfMessageComponents = tableView.numberOfRows(inSection: section)

        return IndexPath(row: numberOfMessageComponents - 1, section: section)
    }

    func didScroll(tableView: UITableView) {
        let scrolledToTop = (tableView.contentOffset.y + tableView.bounds.height) - tableView.contentSize.height > 0

        if scrolledToTop && hasOlderMessagesToLoad {
            // NOTE: we dispatch async because `didScroll(tableView:)` can be called inside a `performBatchUpdate()`,
            // which would cause data source inconsistency if change the fetchLimit.
            DispatchQueue.main.async {
                self.loadOlderMessages()
            }
        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let scrolledToBottom = scrollView.contentOffset.y < 0
        guard scrolledToBottom && hasNewerMessagesToLoad else { return }

        // We are at the bottom and should load new messages

        // To avoid loosing scroll position:
        // 1. Remember the newest message now
        let newestMessageBeforeReload = messages.first
        // 2. Load more messages
        loadNewerMessages()

        // 3. Get the index path of the message that should stay displayed
        if let newestMessageBeforeReload = newestMessageBeforeReload,
           let sectionIndex = self.index(of: newestMessageBeforeReload) {

            // 4. Get the frame of that message
            let indexPathRect = tableView.rect(forSection: sectionIndex)

            // 5. Update content offset so it stays visible. To reduce flickering compensate for empty space below the message
            scrollView.contentOffset = CGPoint(x: 0, y: indexPathRect.minY - 16)
        }
    }

    private func fetchRequest() -> NSFetchRequest<ZMMessage> {
        let fetchRequest = NSFetchRequest<ZMMessage>(entityName: ZMMessage.entityName())
        fetchRequest.predicate = conversation.visibleMessagesPredicate
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(ZMMessage.serverTimestamp), ascending: false)]
        return fetchRequest
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

    func numberOfSections(in tableView: UITableView) -> Int {
        return currentSections.count
    }

    func select(indexPath: IndexPath) {
        let sectionController = self.sectionController(at: indexPath.section, in: tableView)
        sectionController.didSelect()
        reloadSections(newSections: calculateSections(updating: sectionController))
    }

    func deselect(indexPath: IndexPath) {
        let sectionController = self.sectionController(at: indexPath.section, in: tableView)
        sectionController.didDeselect()
        reloadSections(newSections: calculateSections(updating: sectionController))
    }

    func highlight(message: ZMConversationMessage) {
        guard let section = index(of: message) else {
            return
        }

        let sectionController = self.sectionController(at: section, in: tableView)
        sectionController.highlight(in: tableView, sectionIndex: section)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard currentSections.indices.contains(section) else { return 0 }

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

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard currentSections.indices.contains(indexPath.section) else {
            fatal("currentSections has \(currentSections.count) elements, but try to access #\(indexPath)")
        }

        let section = currentSections[indexPath.section]

        guard section.elements.indices.contains(indexPath.row) else {
            fatal("section.elements has \(section.elements.count) elements, but try to access #\(indexPath)")
        }

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
            previousMessage.senderUser === message.senderUser,
            Message.isNormal(previousMessage) else { return false }

        return true
    }

    func context(for message: ZMConversationMessage,
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

        let isLastMessage = (index == 0) && !hasNewerMessagesToLoad
        return ConversationMessageContext(
            isSameSenderAsPrevious: isPreviousSenderSame(forMessage: message, at: index),
            isTimeIntervalSinceLastMessageSignificant: isTimeIntervalSinceLastMessageSignificant,
            isFirstMessageOfTheDay: isFirstMessageOfTheDay(for: message, at: index),
            isFirstUnreadMessage: message.isEqual(firstUnreadMessage),
            isLastMessage: isLastMessage,
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
