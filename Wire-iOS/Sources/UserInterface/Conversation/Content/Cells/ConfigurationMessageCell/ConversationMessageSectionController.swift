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

struct ConversationMessageContext {
    let isSameSenderAsPrevious: Bool
    let isLastMessageSentBySelfUser: Bool
    let isTimeIntervalSinceLastMessageSignificant: Bool
    let isFirstMessageOfTheDay: Bool
    let isFirstUnreadMessage: Bool
}

extension IndexSet {
    
    func indexPaths(in section: Int) -> [IndexPath] {
        return enumerated().map({ (_, index) in
            return IndexPath(row: index, section: section)
        })
    }
    
}


@objc protocol ConversationMessageSectionControllerDelegate: class {
    func messageSectionController(_ controller: ConversationMessageSectionController, didRequestRefreshForMessage message: ZMConversationMessage)
}

/**
 * An object that provides an interface to build list sections for a single message.
 *
 * A message will be represented as a table/collection section, and the components that make
 * the view of the message (timestamp, reply, content...) will be displayed as individual cells,
 * to reduce the number of cells that are instanciated at a given time.
 *
 * To achieve this, each section controller is assigned a cell description, that is responsible for dequeing
 * the cells from the table or collection view and configuring them with a message.
 */

@objc class ConversationMessageSectionController: NSObject, ZMMessageObserver {

    /// The view descriptor of the section.
    @objc var visibleCellDescriptions: [AnyConversationMessageCellDescription] = []
    @objc var cellDescriptions: [AnyConversationMessageCellDescription] = []
    
    /// The view descriptors in the order in which the tableview displays them.
    var tableViewVisibleCellDescriptions: [AnyConversationMessageCellDescription] {
        return useInvertedIndices ? visibleCellDescriptions.reversed() : visibleCellDescriptions
    }
    
    var context: ConversationMessageContext
    var layoutProperties: ConversationCellLayoutProperties

    /// Wheater this section is selected
    @objc var selected: Bool = false

    /// Whether we need to use inverted indices. This is `true` when the table view is upside down.
    @objc var useInvertedIndices = false

    /// The object that controls actions for the cell.
    @objc var actionController: ConversationCellActionController?

    /// The message that is being presented.
    @objc var message: ZMConversationMessage

    /// The delegate for cells injected by the list adapter.
    @objc weak var cellDelegate: ConversationCellDelegate?

    /// The object that receives informations from the section.
    @objc weak var sectionDelegate: ConversationMessageSectionControllerDelegate?

    private var changeObservers: [Any] = []

    deinit {
        changeObservers.removeAll()
    }

    init(message: ZMConversationMessage, context: ConversationMessageContext, layoutProperties: ConversationCellLayoutProperties) {
        self.message = message
        self.context = context
        self.layoutProperties = layoutProperties
        
        super.init()
        
        createCellDescriptions(in: context, layoutProperties: layoutProperties)
        
        visibleCellDescriptions = visibleDescriptions(in: context)
        
        startObservingChanges(for: message)
        
        if let quotedMessage = message.textMessageData?.quote {
            startObservingChanges(for: quotedMessage)
        }
    }
    
    
    // MARK: - Content Types
    
    private func addLegacyContentIfNeeded(layoutProperties: ConversationCellLayoutProperties) -> Bool {
        
        if message.isVideo {
            let videoCell = ConversationLegacyCellDescription<VideoMessageCell>(message: message, layoutProperties: layoutProperties)
            add(description: videoCell)
            
        } else if message.isAudio {
            let audioCell = ConversationLegacyCellDescription<AudioMessageCell>(message: message, layoutProperties: layoutProperties)
            add(description: audioCell)
            
        } else if message.isFile {
            let fileCell = ConversationLegacyCellDescription<FileTransferCell>(message: message, layoutProperties: layoutProperties)
            add(description: fileCell)
            
        } else if message.isImage {
            let imageCell = ConversationLegacyCellDescription<ImageMessageCell>(message: message, layoutProperties: layoutProperties)
            add(description: imageCell)
            
        } else if message.isSystem, let systemMessageType = message.systemMessageData?.systemMessageType {
            switch systemMessageType {
            case .newClient, .usingNewDevice:
                let newClientCell = ConversationLegacyCellDescription<ConversationNewDeviceCell>(message: message, layoutProperties: layoutProperties)
                add(description: newClientCell)
                
            case .ignoredClient:
                let ignoredClientCell = ConversationLegacyCellDescription<ConversationIgnoredDeviceCell>(message: message, layoutProperties: layoutProperties)
                add(description: ignoredClientCell)
                
            case .potentialGap, .reactivatedDevice:
                let missingMessagesCell = ConversationLegacyCellDescription<MissingMessagesCell>(message: message, layoutProperties: layoutProperties)
                add(description: missingMessagesCell)
                
            case .participantsAdded, .participantsRemoved, .newConversation, .teamMemberLeave:
                let participantsCell = ConversationLegacyCellDescription<ParticipantsCell>(message: message, layoutProperties: layoutProperties)
                add(description: participantsCell)
                
            default:
                return false
            }
        } else {
            return false
        }
        
        return true
    }
    
    private func addContent(context: ConversationMessageContext, layoutProperties: ConversationCellLayoutProperties) {
        
        if message.isKnock {
            addPing()
        } else if message.isText {
            addTextMessageAndAttachments()
        } else if message.isLocation {
            addLocationMessage()
        } else if message.isSystem {
            addSystemMessage(layoutProperties: layoutProperties)
        } else {
            add(description: UnknownMessageCellDescription())
        }
    }
    
    // MARK: - Content Cells
    
    private func addPing() {
        guard let sender = message.sender else {
            return
        }
        
        let pingCell = ConversationPingCellDescription(message: message, sender: sender)
        add(description: pingCell)
    }
    
    private func addSystemMessage(layoutProperties: ConversationCellLayoutProperties) {
        let cells = ConversationSystemMessageCellDescription.cells(for: message, layoutProperties: layoutProperties)
        cellDescriptions.append(contentsOf: cells)
    }
    
    private func addTextMessageAndAttachments() {
        let cells = ConversationTextMessageCellDescription.cells(for: message)
        cellDescriptions.append(contentsOf: cells)
    }
    
    private func addLocationMessage() {
        guard let locationMessageData = message.locationMessageData else {
            return
        }
        
        let locationCell = ConversationLocationMessageCellDescription(message: message, location: locationMessageData)
        add(description: locationCell)
    }

    // MARK: - Composition

    /**
     * Adds a cell description to the section.
     * - parameter description: The cell to add to the message section.
     */

    func add<T: ConversationMessageCellDescription>(description: T) {
        cellDescriptions.append(AnyConversationMessageCellDescription(description))
    }
    
    func didSelect(indexPath: IndexPath, tableView: UITableView) {
        selected = true
        configure(in: context, at: indexPath.section, in: tableView)
    }
    
    func didDeselect(indexPath: IndexPath, tableView: UITableView) {
        selected = false
        configure(in: context, at: indexPath.section, in: tableView)
    }
    
    private func createCellDescriptions(in context: ConversationMessageContext, layoutProperties: ConversationCellLayoutProperties) {
        cellDescriptions.removeAll()
        
        let burstTimestampDescription = AnyConversationMessageCellDescription(BurstTimestampSenderMessageCellDescription(message: message, context: context))
        let toolboxDescription = AnyConversationMessageCellDescription(ConversationMessageToolboxCellDescription(message: message))
        let senderDescription = AnyConversationMessageCellDescription(ConversationSenderMessageCellDescription(sender: message.sender, message: message))
        
        cellDescriptions.append(burstTimestampDescription)
        cellDescriptions.append(senderDescription)
        addContent(context: context, layoutProperties: layoutProperties)
        cellDescriptions.append(toolboxDescription)
    }
    
    func configure(at sectionIndex: Int, in tableView: UITableView) {
        createCellDescriptions(in: context, layoutProperties: layoutProperties)
        configure(in: context, at: sectionIndex, in: tableView)
    }
    
    func configure(in context: ConversationMessageContext, at sectionIndex: Int, in tableView: UITableView) {
        self.context = context
        tableView.beginUpdates()
        
        let old = ZMOrderedSetState(orderedSet: NSOrderedSet(array: tableViewVisibleCellDescriptions.map({ $0.baseType })))
        visibleCellDescriptions = visibleDescriptions(in: context)
        let new = ZMOrderedSetState(orderedSet: NSOrderedSet(array: tableViewVisibleCellDescriptions.map({ $0.baseType })))
        let change = ZMChangedIndexes(start: old, end: new, updatedState: new, moveType: .nsTableView)
        
        if let deleted = change?.deletedIndexes.indexPaths(in: sectionIndex) {
            tableView.deleteRows(at: deleted, with: .fade)
        }
        
        if let inserted = change?.insertedIndexes.indexPaths(in: sectionIndex) {
            tableView.insertRows(at: inserted, with: .fade)
        }
        
        tableView.endUpdates()
        
        for (index, description) in tableViewVisibleCellDescriptions.enumerated() {
            if let cell = tableView.cellForRow(at: IndexPath(row: index, section: sectionIndex)) {
                description.configure(cell: cell)
            }
        }
    }
    
    func visibleDescriptions(in context: ConversationMessageContext) -> [AnyConversationMessageCellDescription] {
        return cellDescriptions.filter { (description) -> Bool in
            return description.visible(in: context, selected: selected)
        }
    }
    
    // MARK: - Data Source

    /// The number of child cells in the section that compose the message.
    var numberOfCells: Int {
        return visibleCellDescriptions.count
    }

    /**
     * Create the cell for the child cell at the given index path.
     * It is the responsibility of the section description to determine what the `row` represents,
     * to dequeue the appropriate cell, and to configure it with a message.
     * - parameter tableView: The table view where the cell will be displayed.
     * - parameter indexPath: The index path of the child cell that will be displayed. Use the `row` property
     * to determine the type of child cell that needs to be displayed.
     */

    func makeCell(for tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell {
        let description = tableViewVisibleCellDescriptions[indexPath.row]
        description.delegate = self.cellDelegate
        description.message = self.message
        description.actionController = self.actionController

        let cell = description.makeCell(for: tableView, at: indexPath)
        return cell
    }

    // MARK: - Changes

    private func startObservingChanges(for message: ZMConversationMessage) {
        if let userSession = ZMUserSession.shared() {
            let observer = MessageChangeInfo.add(observer: self, for: message, userSession: userSession)
            changeObservers.append(observer)
        }
    }

    func messageDidChange(_ changeInfo: MessageChangeInfo) {
        sectionDelegate?.messageSectionController(self, didRequestRefreshForMessage: self.message)
    }

}
