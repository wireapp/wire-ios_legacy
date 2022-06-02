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
import UIKit
import WireDataModel

final class ConversationVideoMessageCell: RoundedView, ConversationMessageCell {

    struct Configuration {
        let message: ZMConversationMessage
        var isObfuscated: Bool {
            return message.isObfuscated
        }
    }

    private var containerView = UIView()
    private let transferView = VideoMessageView(frame: .zero)
    private let obfuscationView = ObfuscationView(icon: .videoMessage)
    private let restrictionView = VideoMessageRestrictionView()

    weak var delegate: ConversationMessageCellDelegate?
    weak var message: ZMConversationMessage?

    var isSelected: Bool = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureSubview()
        configureConstraints()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureSubview() {
        shape = .rounded(radius: 4)
        backgroundColor = .from(scheme: .placeholderBackground)
        clipsToBounds = true

        addSubview(containerView)
    }

    private func configureConstraints() {
        containerView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // containerView
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    func configure(with object: Configuration, animated: Bool) {
        if object.isObfuscated {
            setup(obfuscationView)
        } else if !object.message.canBeShared {
            setup(restrictionView, heightMultiplier: 9/16)
            restrictionView.configure()
        } else {
            transferView.delegate = self
            setup(transferView)
            transferView.configure(for: object.message, isInitial: false)
        }
    }

    private func setup(_ view: UIView) {
        containerView.removeSubviews()
        containerView.addSubview(view)

        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.heightAnchor.constraint(equalToConstant: 160),
            view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            view.topAnchor.constraint(equalTo: containerView.topAnchor),
            view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
    }

    private func setup(_ view: UIView, heightMultiplier: CGFloat) {
        containerView.removeSubviews()
        containerView.addSubview(view)

        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.heightAnchor.constraint(equalTo: widthAnchor, multiplier: heightMultiplier),
            view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            view.topAnchor.constraint(equalTo: containerView.topAnchor),
            view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
    }

    override public var tintColor: UIColor! {
        didSet {
            self.transferView.tintColor = self.tintColor
        }
    }

    var selectionView: UIView! {
        return transferView
    }

    var selectionRect: CGRect {
        return transferView.bounds
    }

}

extension ConversationVideoMessageCell: TransferViewDelegate {
    func transferView(_ view: TransferView, didSelect action: MessageAction) {
        guard let message = message else { return }

        delegate?.perform(action: action, for: message, view: self)
    }
}

final class ConversationVideoMessageCellDescription: ConversationMessageCellDescription {
    typealias View = ConversationVideoMessageCell
    let configuration: View.Configuration

    var topMargin: Float = 8
    var showEphemeralTimer: Bool = false

    let isFullWidth: Bool = false
    let supportsActions: Bool = true
    let containsHighlightableContent: Bool = true

    weak var message: ZMConversationMessage?
    weak var delegate: ConversationMessageCellDelegate?
    weak var actionController: ConversationMessageActionController?

    var accessibilityIdentifier: String? {
        return configuration.isObfuscated ? "ObfuscatedVideoCell" : "VideoCell"
    }

    let accessibilityLabel: String? = nil

    init(message: ZMConversationMessage) {
        self.configuration = View.Configuration(message: message)
    }

}
