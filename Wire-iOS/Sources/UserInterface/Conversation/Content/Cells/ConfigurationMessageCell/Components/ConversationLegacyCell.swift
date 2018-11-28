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

extension ConversationCell: ConversationMessageCell {

    struct Configuration {
        let message: ZMConversationMessage
        let layoutProperties: ConversationCellLayoutProperties
    }

    func configure(with object: Configuration, animated: Bool = false) {
        self.configure(for: object.message, layoutProperties: object.layoutProperties)
    }

}

class ConversationLegacyCellDescription<T: ConversationCell>: ConversationMessageCellDescription {
    typealias View = T
    let configuration: View.Configuration

    var message: ZMConversationMessage?
    weak var delegate: ConversationCellDelegate? 
    weak var actionController: ConversationMessageActionController?
    
    var showEphemeralTimer: Bool = false
    var topMargin: Float = 0

    let isFullWidth: Bool = false
    let supportsActions: Bool = false
    let containsHighlightableContent: Bool = true

    let accessibilityIdentifier: String? = nil
    let accessibilityLabel: String? = nil

    init(message: ZMConversationMessage, layoutProperties: ConversationCellLayoutProperties) {
        configuration = View.Configuration(message: message, layoutProperties: layoutProperties)
    }

    func register(in tableView: UITableView) {
        tableView.register(View.self, forCellReuseIdentifier: String(describing: View.self))
    }

    func makeCell(for tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: View.self)) as! ConversationCell
        cell.delegate = self.delegate
        cell.configure(with: configuration)
        return cell
    }

}
