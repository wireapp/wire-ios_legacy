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

    var isConfigured: Bool  = false
    var isSelected: Bool = false

    func configure(with object: Configuration) {
        isConfigured = true
        backgroundColor = object.backgroundColor
    }
}

class MockCellDescription<T>: ConversationMessageCellDescription {
    typealias View = MockCell
    let configuration: View.Configuration

    var isFullWidth: Bool = false
    var supportsActions: Bool = true

    weak var message: ZMConversationMessage?
    weak var delegate: ConversationCellDelegate?
    weak var actionController: ConversationCellActionController?

    init() {
        let backgroundColor = UIColor(for: .vividRed)!
        configuration = View.Configuration(backgroundColor: backgroundColor)
    }
}
