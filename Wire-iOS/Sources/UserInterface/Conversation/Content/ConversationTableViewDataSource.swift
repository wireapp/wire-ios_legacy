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


extension ConversationCell {
    static var allCellTypes: [ConversationCell.Type] = [
    TextMessageCell.self,
    ImageMessageCell.self,
    ConversationRenamedCell.self,
    PingCell.self,
    PerformedCallCell.self,
    MissedCallCell.self,
    ConnectionRequestCell.self,
    ConversationNewDeviceCell.self,
    ConversationVerifiedCell.self,
    MissingMessagesCell.self,
    ConversationIgnoredDeviceCell.self,
    CannotDecryptCell.self,
    FileTransferCell.self,
    VideoMessageCell.self,
    AudioMessageCell.self,
    ParticipantsCell.self,
    LocationMessageCell.self,
    MessageDeletedCell.self,
    UnknownMessageCell.self,
    MessageTimerUpdateCell.self
    ]
}

final class ConversationTableViewDataSource: NSObject {
    public static let defaultBatchSize = 30 // Magic number: amount of messages per screen (upper bound)
    public static let maximumWindowSize = 100 // Magic number: maximum amount of messages visible.
    
    private var fetchController: NSFetchedResultsController<ZMMessage>!
    private var fetchOffset: Int = 0 {
        didSet {
            createFetchController()
            tableView.reloadData()
            faultInvisibleMessages()
        }
    }

    private var readerPosition: Int = 0 {
        didSet {
            // TODO adjust fetchOffset
        }
    }
    
    private var deletedIndexPathsInCurrentUpdate = IndexSet()
    
    public let conversation: ZMConversation
    public let tableView: UITableView
    
    public var firstUnreadMessage: ZMConversationMessage?
    public var selectedMessage: ZMConversationMessage? = nil
    public var editingMessage: ZMConversationMessage? = nil {
        didSet {
            reconfigureVisibleCells()
        }
    }
    
    public weak var conversationCellDelegate: ConversationCellDelegate? = nil
    
    public var searchQueries: [String] = [] {
        didSet {
            reconfigureVisibleCells()
        }
    }
    
    public var messages: [ZMConversationMessage] {
        return fetchController.fetchedObjects ?? []
    }
    
    public init(conversation: ZMConversation, tableView: UITableView) {
        self.conversation = conversation
        self.tableView = tableView
        tableView.dataSource = self
        tableView.prefetchDataSource = self
        
        super.init()
        
        registerTableCellClasses()
        createFetchController()
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
    
    private func moveUp(by numberOfMessages: Int) -> Bool {
        guard !oldestMessageFetched else {
            return false
        }
        
        fetchOffset = fetchOffset + numberOfMessages
        return true
    }
    
    private func moveDown(by numberOfMessages: Int) -> Bool {
        guard !newestMessageFetched else {
            return false
        }
        
        fetchOffset = fetchOffset - numberOfMessages
        return true
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
    
    @objc(tableViewDidScroll:) public func didScroll(tableView: UITableView) {
        // TODO: adjust readerPosition
    }
    
    private func configure(_ conversationCell: ConversationCell, with message: ZMConversationMessage, at index: Int) {
        // If a message has been deleted, we don't try to configure it
        guard !message.hasBeenDeleted else { return }
        
        let layoutProperties = self.layoutProperties(for: message, at: index)
    
        conversationCell.isSelected = (message == self.selectedMessage)
        conversationCell.beingEdited = (message == self.editingMessage)
        
        conversationCell.configure(for: message, layoutProperties: layoutProperties)
    }
    
    private func reconfigureVisibleCells(withDeleted deletedIndexes: IndexSet = IndexSet()) {
        tableView.visibleCells.forEach { cell in
            guard let conversationCell = cell as? ConversationCell,
                  let indexPath = self.tableView.indexPath(for: cell),
                    !deletedIndexes.contains(indexPath.row) else {
                return
            }
            
            conversationCell.searchQueries = self.searchQueries
            self.configure(conversationCell, with: conversationCell.message, at: indexPath.row)
        }
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
        fetchRequest.fetchLimit = ConversationTableViewDataSource.defaultBatchSize
        fetchRequest.fetchOffset = fetchOffset
        
        fetchController = NSFetchedResultsController<ZMMessage>(fetchRequest: fetchRequest,
                                                                managedObjectContext: conversation.managedObjectContext!,
                                                                sectionNameKeyPath: nil,
                                                                cacheName: nil)
        
        self.fetchController.delegate = self
        try! fetchController.performFetch()
        
        firstUnreadMessage = conversation.firstUnreadMessage
    }
    
    private func faultInvisibleMessages() {
        guard let invisibleMessages = fetchController.fetchedObjects?.suffix(ConversationTableViewDataSource.defaultBatchSize) else {
            return
        }
        invisibleMessages.forEach {
            conversation.managedObjectContext!.refresh($0, mergeChanges: $0.hasChanges)
        }
    }
}

extension ConversationTableViewDataSource: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange anObject: Any,
                    at indexPath: IndexPath?,
                    for changeType: NSFetchedResultsChangeType,
                    newIndexPath: IndexPath?) {
        
        switch changeType {
        case .insert:
            guard let insertedIndexPath = newIndexPath else {
                fatal("Missing new index path")
            }
            
            tableView.insertRows(at: [insertedIndexPath], with: .fade)
        case .delete:
            guard let indexPathToRemove = indexPath else {
                fatal("Missing index path")
            }
            deletedIndexPathsInCurrentUpdate.insert(indexPathToRemove.row)
            tableView.deleteRows(at: [indexPathToRemove], with: .fade)
            self.stopAudioPlayer(for: indexPathToRemove)
        case .update:
            guard let indexPathToUpdate = indexPath,
                  let message = anObject as? ZMMessage,
                  let loadedCell = tableView.cellForRow(at: indexPathToUpdate) as? ConversationCell else {
                return
            }
            
            loadedCell.configure(for: message, layoutProperties: loadedCell.layoutProperties)
            
        case .move:
            if let indexPath = indexPath {
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
            
            if let newIndexPath = newIndexPath {
                tableView.insertRows(at: [newIndexPath], with: .fade)
            }
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange sectionInfo: NSFetchedResultsSectionInfo,
                    atSectionIndex sectionIndex: Int,
                    for changeType: NSFetchedResultsChangeType) {
        let indexSet = IndexSet(integer: sectionIndex)
        
        switch changeType {
        case .delete:
            tableView.deleteSections(indexSet, with: .fade)
        case .update:
            tableView.reloadSections(indexSet, with: .fade)
        case .insert:
            tableView.insertSections(indexSet, with: .fade)
        case .move:
            fatal("Unexpected change type")
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        reconfigureVisibleCells(withDeleted: deletedIndexPathsInCurrentUpdate)
        deletedIndexPathsInCurrentUpdate.removeAll()
        tableView.endUpdates()
    }
}

extension ConversationTableViewDataSource {
    fileprivate func registerTableCellClasses() {
        ConversationCell.allCellTypes.forEach {
            tableView.register($0, forCellReuseIdentifier: $0.reuseIdentifier)
        }
    }
}

extension ConversationTableViewDataSource: UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = messages[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: message.cellClass.reuseIdentifier, for: indexPath)
        guard let conversationCell = cell as? ConversationCell else { fatal("Unknown cell") }

        // Newly created cells will have a size of {320, 44}, which leads to layout problems when they contain `UICollectionViews`.
        // This is needed as long as `ParticipantsCell` contains a `UICollectionView`.
        var bounds = conversationCell.bounds
        bounds.size.width = tableView.bounds.size.width
        conversationCell.bounds = bounds
        
        conversationCell.searchQueries = searchQueries
        conversationCell.delegate = conversationCellDelegate
        // Configuration of the cell is not possible when `ZMUserSession` is not available.
        if let _ = ZMUserSession.shared() {
            configure(conversationCell, with: message, at: indexPath.row)
        }
        return conversationCell
    }
}

extension ConversationTableViewDataSource: UITableViewDataSourcePrefetching {
    public func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        // TODO: adjust readerPosition
    }
    
    public func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
        // TODO: adjust readerPosition
    }
}

extension ZMConversationMessage {
    var cellClass: ConversationCell.Type {
        
        if isText {
            return TextMessageCell.self
        } else if isVideo {
            return VideoMessageCell.self
        } else if isAudio {
            return AudioMessageCell.self
        } else if isLocation {
            return LocationMessageCell.self
        } else if isFile {
            return FileTransferCell.self
        } else if isImage {
            return ImageMessageCell.self
        } else if isKnock {
            return PingCell.self
        } else if isSystem, let systemMessageType = systemMessageData?.systemMessageType {
            switch systemMessageType {
            case .connectionRequest:
                return ConnectionRequestCell.self
            case .conversationNameChanged:
                return ConversationRenamedCell.self
            case .missedCall:
                return MissedCallCell.self
            case .newClient, .usingNewDevice:
                return ConversationNewDeviceCell.self
            case .ignoredClient:
                return ConversationIgnoredDeviceCell.self
            case .conversationIsSecure:
                return ConversationVerifiedCell.self
            case .potentialGap, .reactivatedDevice:
                return MissingMessagesCell.self
            case .decryptionFailed, .decryptionFailed_RemoteIdentityChanged:
                return CannotDecryptCell.self
            case .participantsAdded, .participantsRemoved, .newConversation, .teamMemberLeave:
                return ParticipantsCell.self
            case .messageDeletedForEveryone:
                return MessageDeletedCell.self
            case .performedCall:
                return PerformedCallCell.self
            case .messageTimerUpdate:
                return MessageTimerUpdateCell.self
            default:
                fatal("Unknown cell")
            }
        } else {
            return UnknownMessageCell.self
        }
        
        fatal("Unknown cell")
    }
}

