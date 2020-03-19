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


extension ButtonMessageState {
    var localizedName: String {
        return "buttonMessageCell.state.\(self)".localized
    }
}

final class ConversationButtonMessageCell: UIView, ConversationMessageCell {
    private let button = SpinnerButton(style: .empty)
    var isSelected: Bool = false
    private var buttonAction: Completion?

    weak var message: ZMConversationMessage?
    weak var delegate: ConversationMessageCellDelegate?
    private var config: Configuration? {
        didSet {
            guard config != oldValue else { return }
            
            updateUI()
        }
    }

    private func updateUI() {
        guard let config = config else { return }
        
        buttonAction = config.buttonAction
        button.setTitle(config.text, for: .normal)

        switch config.state {
        case .unselected:
            button.style = .empty
        case .selected:
            button.style = .full
        case .confirmed:
            button.style = .full
            button.isEnabled = false
            ///TODO: style for expired state
        }
        
        button.accessibilityValue = config.state.localizedName
    }
    
    func configure(with object: Configuration, animated: Bool) {
        config = object
    }

    enum State {
        case unselected
        case selected
        case loading
    }

    struct Configuration {
        let text: String?
        let state: ButtonMessageState
        let buttonAction: Completion
        ///TODO: state/spinner ?
    }

    convenience init() {
        self.init(frame: .zero)
    }
    
    override init(frame: CGRect) {
        super.init(frame: .zero)

        configureViews()
        createConstraints()
        
        button.addTarget(self, action: #selector(buttonTouched), for: .touchUpInside)
    }
    
    @objc
    private func buttonTouched() {
        buttonAction?()
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

    init(text: String?,
         state: ButtonMessageState,
         buttonAction: @escaping Completion) {
        configuration = View.Configuration(text: text, state: state, buttonAction: buttonAction)
    }
}

extension ConversationButtonMessageCell.Configuration: Hashable {
    static func == (lhs: ConversationButtonMessageCell.Configuration, rhs: ConversationButtonMessageCell.Configuration) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(text)
        hasher.combine(state)
    }
}
