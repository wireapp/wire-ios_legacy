// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

final class ConversationButtonMessageCell: UIView, ConversationMessageCell {
    private let button = SpinnerButton(style: .empty)
    var isSelected: Bool = false

    weak var message: ZMConversationMessage?

    weak var delegate: ConversationMessageCellDelegate?

    func configure(with object: ConversationButtonMessageCell.Configuration, animated: Bool) {
        button.setTitle(object.text, for: .normal)
        switch object.state {
        case .unselected:
            button.style = .empty
        case .selected:
            button.style = .full
        case .confirmed:
            button.isEnabled = false
            ///TODO: style?
        }
    }

    enum State {
        case unselected
        case selected
        case loading
    }

    struct Configuration {
        let text: String?
        let state: ButtonMessageState
        ///TODO: state/spinner ?
    }

    init() {
        super.init(frame: .zero)

        configureViews()
        createConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureViews() {
        addSubview(button)
    }

    private func createConstraints() {
        button.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: topAnchor),
            button.bottomAnchor.constraint(equalTo: bottomAnchor),
            button.leadingAnchor.constraint(equalTo: leadingAnchor),
            button.trailingAnchor.constraint(equalTo: trailingAnchor)])
    }
}

final class ConversationButtonMessageCellDescription: ConversationMessageCellDescription {
    typealias View = ConversationButtonMessageCell

    var topMargin: Float = Float.ConversationButtonMessageCell.verticalInset

    var isFullWidth: Bool = false ///TODO:

    var supportsActions: Bool = false ///TODO:

    var showEphemeralTimer: Bool = false

    var containsHighlightableContent: Bool = false

    var message: ZMConversationMessage?

    var delegate: ConversationMessageCellDelegate?

    var actionController: ConversationMessageActionController?

    var configuration: View.Configuration

    var accessibilityIdentifier: String? = "PollCell"

    var accessibilityLabel: String?

    init(text: String?, state: ButtonMessageState) {
        configuration = View.Configuration(text: text, state: state)
    }
}
