//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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
import WireCommonComponents

final class CollectionFileCell: CollectionCell {
    private var containerView = UIView()
    private let fileTransferView = FileTransferView()
    private let restrictionView = FileMessageRestrictionView()
    private let headerView = CollectionCellHeader()

    override func updateForMessage(changeInfo: MessageChangeInfo?) {
        typealias ConversationSearch = L10n.Accessibility.ConversationSearch

        super.updateForMessage(changeInfo: changeInfo)

        guard let message = self.message else {
            return
        }

        headerView.message = message
        if message.canBeShared {
            fileTransferView.delegate = self

            setup(fileTransferView)
            fileTransferView.configure(for: message, isInitial: changeInfo == .none)
        } else {
            setup(restrictionView)
            restrictionView.configure(for: message)
        }
        accessibilityLabel = ConversationSearch.SentBy.description(message.senderName)
                            + ", \(message.serverTimestamp?.formattedDate ?? ""), "
                            + (fileTransferView.accessibilityLabel ?? "")
        accessibilityHint = ConversationSearch.Item.hint
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        loadView()
        setupAccessibility()
    }

    func loadView() {
        headerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.translatesAutoresizingMaskIntoConstraints = false

        secureContentsView.addSubview(headerView)
        secureContentsView.addSubview(containerView)

        NSLayoutConstraint.activate([
            // headerView
            headerView.topAnchor.constraint(equalTo: secureContentsView.topAnchor, constant: 16),
            headerView.leadingAnchor.constraint(equalTo: secureContentsView.leadingAnchor, constant: 16),
            headerView.trailingAnchor.constraint(equalTo: secureContentsView.trailingAnchor, constant: -16),

            // containerView
            containerView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 4),
            containerView.leadingAnchor.constraint(equalTo: secureContentsView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: secureContentsView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: secureContentsView.bottomAnchor)
        ])
    }

    override var obfuscationIcon: StyleKitIcon {
        return .document
    }

    private func setup(_ view: UIView) {
        view.layer.cornerRadius = 4
        view.clipsToBounds = true

        containerView.removeSubviews()
        containerView.addSubview(view)

        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: containerView.topAnchor),
            view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 4),
            view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -4),
            view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -4)
        ])
    }

    private func setupAccessibility() {
        isAccessibilityElement = true
        accessibilityTraits = .button
    }
}

extension CollectionFileCell: TransferViewDelegate {
    func transferView(_ view: TransferView, didSelect action: MessageAction) {
        self.delegate?.collectionCell(self, performAction: action)
    }
}
