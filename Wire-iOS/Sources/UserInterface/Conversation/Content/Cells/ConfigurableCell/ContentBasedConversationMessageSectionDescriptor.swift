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

import UIKit

class ContentBasedConversationMessageSectionDescriptor<Content: ConversationMessageSectionDescription>: ConversationMessageSectionDescription {

    let message: ZMConversationMessage
    let configuration: MessageCellConfiguration
    let contentDescriptor: Content

    enum CellPosition {
        case timestamp, sender, content(UInt)

        init(rowIndex: UInt) {
            switch rowIndex {
            case 0:
                self = .timestamp
            case 1:
                self = .sender
            default:
                self = .content(rowIndex - 2)
            }
        }

        func isValid(for configuration: MessageCellConfiguration) -> Bool {
            switch self {
            case .timestamp:
                return configuration.contains(.showBurstTimestamp)
            case .sender:
                return configuration.contains(.showSender)
            case .content:
                return true
            }
        }
    }

    init(message: ZMConversationMessage, configuration: MessageCellConfiguration, content: Content) {
        self.message = message
        self.configuration = configuration
        self.contentDescriptor = content
    }

    var numberOfCells: Int {
        var cells = 0

        if configuration.contains(.showBurstTimestamp) {
            cells += 1
        }

        if configuration.contains(.showSender) {
            cells += 1
        }

        // TODO: take child section into account
        return cells
    }

    func cell(tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell {
        guard let position = self.position(for: UInt(indexPath.row)) else {
            fatalError()
        }

        message.locationMessageData?.

        switch position {
        case .sender:
            tableView.dequeueConfigurableCell(configuration: <#T##Equatable#>, for: <#T##IndexPath#>)
            
        }
    }

    private func position(for row: UInt) -> CellPosition? {
        guard let proposedPosition = CellPosition(rowIndex: row) else {
            return nil
        }

        let options = CellPosition.allCases.suffix(from: proposedPosition.rawValue)
        return options.first(where: { $0.isValid(for: self.configuration) })
    }

}

class TextConversationMessageSectionDescriptor: ContentBasedConversationMessageSectionDescriptor {

}
