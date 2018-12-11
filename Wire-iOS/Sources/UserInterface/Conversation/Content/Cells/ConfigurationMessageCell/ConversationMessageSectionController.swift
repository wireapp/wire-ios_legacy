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
    let isTimeIntervalSinceLastMessageSignificant: Bool
    let isFirstMessageOfTheDay: Bool
    let isFirstUnreadMessage: Bool
    let isLastMessage: Bool
    let searchQueries: [String]
    let previousMessageIsKnock: Bool
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
    @objc var cellDescriptions: [AnyConversationMessageCellDescription] = []
    
    /// The view descriptors in the order in which the tableview displays them.
    var tableViewCellDescriptions: [AnyConversationMessageCellDescription] {
        return useInvertedIndices ? cellDescriptions.reversed() : cellDescriptions
    }
    
    var context: ConversationMessageContext
    var layoutProperties: ConversationCellLayoutProperties

    /// Whether we need to use inverted indices. This is `true` when the table view is upside down.
    @objc var useInvertedIndices = false

    /// The object that controls actions for the cell.
    @objc var actionController: ConversationMessageActionController?

    /// The message that is being presented.
    @objc var message: ZMConversationMessage

    /// The delegate for cells injected by the list adapter.
    @objc weak var cellDelegate: ConversationCellDelegate?

    /// The object that receives informations from the section.
    @objc weak var sectionDelegate: ConversationMessageSectionControllerDelegate?
    
    /// Whether this section is selected
    private var selected: Bool

    private var changeObservers: [Any] = []
    
    private var hasLegacyContent: Bool = false

    deinit {
        changeObservers.removeAll()
    }

    init(message: ZMConversationMessage, context: ConversationMessageContext, layoutProperties: ConversationCellLayoutProperties, selected: Bool = false) {
        self.message = message
        self.context = context
        self.layoutProperties = layoutProperties
        self.selected = selected
        
        super.init()
        
        if addLegacyContentIfNeeded(layoutProperties: layoutProperties) {
            hasLegacyContent = true
            return
        }
        
        createCellDescriptions(in: context, layoutProperties: layoutProperties)
        
        startObservingChanges(for: message)
        
        if let quotedMessage = message.textMessageData?.quote {
            startObservingChanges(for: quotedMessage)
        }
    }
    
    // MARK: - Content Types
    
    private func addLegacyContentIfNeeded(layoutProperties: ConversationCellLayoutProperties) -> Bool {
        
        if message.isSystem, let systemMessageType = message.systemMessageData?.systemMessageType {
            switch systemMessageType {
            case .ignoredClient:
                let ignoredClientCell = ConversationLegacyCellDescription<ConversationIgnoredDeviceCell>(message: message, layoutProperties: layoutProperties)
                add(description: ignoredClientCell)
                
            case .potentialGap, .reactivatedDevice:
                let missingMessagesCell = ConversationLegacyCellDescription<MissingMessagesCell>(message: message, layoutProperties: layoutProperties)
                add(description: missingMessagesCell)
                
            case .newConversation:
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
    
    private func addContent(context: ConversationMessageContext, layoutProperties: ConversationCellLayoutProperties, isSenderVisible: Bool) {
        
        var contentCellDescriptions: [AnyConversationMessageCellDescription]

        if message.isKnock {
            contentCellDescriptions = addPingMessageCells()
        } else if message.isText {
            contentCellDescriptions = ConversationTextMessageCellDescription.cells(for: message, searchQueries: context.searchQueries)
        } else if message.isImage {
            contentCellDescriptions = [AnyConversationMessageCellDescription(ConversationImageMessageCellDescription(message: message, image: message.imageMessageData!))]
        } else if message.isLocation {
            contentCellDescriptions = addLocationMessageCells()
        } else if message.isAudio {
            contentCellDescriptions = [AnyConversationMessageCellDescription(ConversationAudioMessageCellDescription(message: message))]
        } else if message.isVideo {
            contentCellDescriptions = [AnyConversationMessageCellDescription(ConversationVideoMessageCellDescription(message: message))]
        } else if message.isFile {
            contentCellDescriptions = [AnyConversationMessageCellDescription(ConversationFileMessageCellDescription(message: message))]
        } else if message.isSystem {
            contentCellDescriptions = ConversationSystemMessageCellDescription.cells(for: message, layoutProperties: layoutProperties)
        } else {
            contentCellDescriptions = [AnyConversationMessageCellDescription(UnknownMessageCellDescription())]
        }
        
        if let topContentCellDescription = contentCellDescriptions.first {
            topContentCellDescription.showEphemeralTimer = message.isEphemeral
            
            if isSenderVisible && topContentCellDescription.baseType == ConversationTextMessageCellDescription.self {
                topContentCellDescription.topMargin = 0 // We only do this for text content since the text label already contains the spacing
            }
        }
        
        cellDescriptions.append(contentsOf: contentCellDescriptions)
    }
    
    // MARK: - Content Cells
    
    private func addPingMessageCells() -> [AnyConversationMessageCellDescription] {
        guard let sender = message.sender else {
            return []
        }

        return [AnyConversationMessageCellDescription(ConversationPingCellDescription(message: message, sender: sender))]
    }
    
    private func addLocationMessageCells() -> [AnyConversationMessageCellDescription] {
        guard let locationMessageData = message.locationMessageData else {
            return []
        }
        
        let locationCell = ConversationLocationMessageCellDescription(message: message, location: locationMessageData)
        return [AnyConversationMessageCellDescription(locationCell)]
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
        guard !hasLegacyContent else { return }
        
        selected = true
        configure(at: indexPath.section, in: tableView)
    }
    
    func didDeselect(indexPath: IndexPath, tableView: UITableView) {
        guard !hasLegacyContent else { return }
        
        selected = false
        configure(at: indexPath.section, in: tableView)
    }
    
    private func createCellDescriptions(in context: ConversationMessageContext, layoutProperties: ConversationCellLayoutProperties) {
        cellDescriptions.removeAll()
        
        let isSenderVisible = self.isSenderVisible(in: context) && message.sender != nil
        
        if isBurstTimestampVisible(in: context) {
            add(description: BurstTimestampSenderMessageCellDescription(message: message, context: context))
        }
        if isSenderVisible, let sender = message.sender {
            add(description: ConversationSenderMessageCellDescription(sender: sender, message: message))
        }
        
        addContent(context: context, layoutProperties: layoutProperties, isSenderVisible: isSenderVisible)
        
        if isToolboxVisible(in: context) {
            add(description: ConversationMessageToolboxCellDescription(message: message, selected: selected))
        }
        
        if let topCelldescription = cellDescriptions.first {
            topCelldescription.topMargin = Float(layoutProperties.topPadding)
        }
    }
    
    @objc func configure(at sectionIndex: Int, in tableView: UITableView) {
        configure(in: context, at: sectionIndex, in: tableView)
    }
    
    func configure(in context: ConversationMessageContext, at sectionIndex: Int, in tableView: UITableView) {
        guard !hasLegacyContent else { return }
        
        self.context = context
        tableView.beginUpdates()
        
        let old = ZMOrderedSetState(orderedSet: NSOrderedSet(array: tableViewCellDescriptions.map({ $0.baseType })))
        createCellDescriptions(in: context, layoutProperties: layoutProperties)
        let new = ZMOrderedSetState(orderedSet: NSOrderedSet(array: tableViewCellDescriptions.map({ $0.baseType })))
        let change = ZMChangedIndexes(start: old, end: new, updatedState: new, moveType: .nsTableView)
        
        if let deleted = change?.deletedIndexes.indexPaths(in: sectionIndex) {
            tableView.deleteRows(at: deleted, with: .fade)
        }
        
        if let inserted = change?.insertedIndexes.indexPaths(in: sectionIndex) {
            tableView.insertRows(at: inserted, with: .fade)
        }
        
        tableView.endUpdates()
        
        for (index, description) in tableViewCellDescriptions.enumerated() {
            if let cell = tableView.cellForRow(at: IndexPath(row: index, section: sectionIndex)) {
                cell.accessibilityCustomActions = self.actionController?.makeAccessibilityActions()
                description.configure(cell: cell, animated: true)
            }
        }
    }
    
    func isBurstTimestampVisible(in context: ConversationMessageContext) -> Bool {
        return context.isTimeIntervalSinceLastMessageSignificant ||  context.isFirstUnreadMessage || context.isFirstMessageOfTheDay
    }
    
    func isToolboxVisible(in context: ConversationMessageContext) -> Bool {
        guard !message.isSystem else {
            return false
        }

        return context.isLastMessage || selected || message.deliveryState == .failedToSend || message.hasReactions()
    }
    
    func isSenderVisible(in context: ConversationMessageContext) -> Bool {
        guard message.sender != nil, !message.isKnock, !message.isSystem else {
            return false
        }
        
        return !context.isSameSenderAsPrevious || context.previousMessageIsKnock || message.updatedAt != nil || isBurstTimestampVisible(in: context)
    }
    
    // MARK: - Data Source

    /// The number of child cells in the section that compose the message.
    var numberOfCells: Int {
        return cellDescriptions.count
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
        let description = tableViewCellDescriptions[indexPath.row]
        description.delegate = self.cellDelegate
        description.message = self.message
        description.actionController = self.actionController

        let cell = description.makeCell(for: tableView, at: indexPath)
        cell.accessibilityCustomActions = actionController?.makeAccessibilityActions()
        return cell
    }

    // MARK: - Highlight

    @objc func highlight(in tableView: UITableView, sectionIndex: Int) {
        let cellDescriptions = tableViewCellDescriptions

        let highlightableCells: [HighlightableView] = cellDescriptions.indices.compactMap {
            guard cellDescriptions[$0].containsHighlightableContent else {
                return nil
            }

            let index = IndexPath(row: $0, section: sectionIndex)
            return tableView.cellForRow(at: index) as? HighlightableView
        }

        let highlight = {
            for container in highlightableCells {
                container.highlightContainer.backgroundColor = UIColor.accentDimmedFlat
            }
        }

        let unhighlight = {
            for container in highlightableCells {
                container.highlightContainer.backgroundColor = .clear
            }
        }

        let animationOptions: UIView.AnimationOptions = [.curveEaseIn, .allowUserInteraction]

        UIView.animate(withDuration: 0.2, delay: 0, options: animationOptions, animations: highlight) { _ in
            UIView.animate(withDuration: 1, delay: 0.55, options: animationOptions, animations: unhighlight)
        }
    }

    // MARK: - Changes

    private func startObservingChanges(for message: ZMConversationMessage) {
        if let userSession = ZMUserSession.shared() {
            let observer = MessageChangeInfo.add(observer: self, for: message, userSession: userSession)
            changeObservers.append(observer)
        }
    }

    func messageDidChange(_ changeInfo: MessageChangeInfo) {
        guard !changeInfo.message.hasBeenDeleted else {
            return // Deletions are handled by the window observer
        }
        
        sectionDelegate?.messageSectionController(self, didRequestRefreshForMessage: self.message)
    }

}
