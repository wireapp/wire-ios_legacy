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
@testable import Wire

class MockCell: UIView, ConversationMessageCell {
    struct Configuration {
        let backgroundColor: UIColor
    }

    weak var message: ZMConversationMessage?
    weak var delegate: ConversationMessageCellDelegate?

    var isConfigured: Bool  = false
    var isSelected: Bool = false

    func configure(with object: Configuration, animated: Bool) {
        isConfigured = true
        backgroundColor = object.backgroundColor
    }
}

final class MockCellDescription<T>: ConversationMessageCellDescription {
    typealias View = MockCell
    let configuration: View.Configuration

    var showEphemeralTimer: Bool = false
    var topMargin: Float = 0
    var isFullWidth: Bool = false
    var supportsActions: Bool = true
    var containsHighlightableContent: Bool = true

    weak var message: ZMConversationMessage?
    weak var delegate: ConversationMessageCellDelegate?
    weak var actionController: ConversationMessageActionController?

    var accessibilityIdentifier: String?
    var accessibilityLabel: String?

    init() {
        let backgroundColor = UIColor(for: .vividRed)
        configuration = View.Configuration(backgroundColor: backgroundColor)
    }
}
