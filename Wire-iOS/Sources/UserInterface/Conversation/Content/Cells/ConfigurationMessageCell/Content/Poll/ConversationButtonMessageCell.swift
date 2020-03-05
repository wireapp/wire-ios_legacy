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

    override init(frame: CGRect) { ///TODO: init?
        super.init(frame: frame)

        configureViews()
        createConstraints()
    }

    private func configureViews() {
        addSubview(button)
    }

    private func createConstraints() {
        button.translatesAutoresizingMaskIntoConstraints = false

        let inset = UIEdgeInsets.zero ///TODO: read from UI spec

        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: topAnchor, constant: inset.top),
            button.bottomAnchor.constraint(equalTo: bottomAnchor, constant: inset.bottom),
            button.leadingAnchor.constraint(equalTo: leadingAnchor, constant: inset.left),
            button.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -inset.right)
            ])
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

final class ConversationButtonMessageCellDescription: ConversationMessageCellDescription {
    typealias View = ConversationButtonMessageCell

    var topMargin: Float = 10 ///TODO: read from design spec

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

    init(text: String?, state: ButtonMessageState) { /// TODO: state conversion?
        configuration = View.Configuration(text: text, state: state)
    }
}
