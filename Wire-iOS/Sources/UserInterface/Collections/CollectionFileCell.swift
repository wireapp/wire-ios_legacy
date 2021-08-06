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
import WireSystem
import WireDataModel
import WireCommonComponents

final class CollectionFileCell: CollectionCell {
    private var containerView = UIView()
    private let fileTransferView = FileTransferView()
    private let restrictionView = FileMessageRestrictionView()
    private let headerView = CollectionCellHeader()

    override func updateForMessage(changeInfo: MessageChangeInfo?) {
        super.updateForMessage(changeInfo: changeInfo)

        guard let message = self.message else {
            return
        }

        headerView.message = message
        if message.isRestricted {
            setup(restrictionView)
            restrictionView.configure(for: message)
        } else {
            fileTransferView.delegate = self

            setup(fileTransferView)
            fileTransferView.configure(for: message, isInitial: changeInfo == .none)
        }
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.loadView()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.loadView()
    }

    func loadView() {
        headerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.translatesAutoresizingMaskIntoConstraints = false

        secureContentsView.layoutMargins = UIEdgeInsets(top: 16, left: 4, bottom: 4, right: 4)
        secureContentsView.addSubview(self.headerView)
        secureContentsView.addSubview(containerView)

        NSLayoutConstraint.activate([
            // headerView
            headerView.topAnchor.constraint(equalTo: secureContentsView.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: secureContentsView.leadingAnchor, constant: 12),
            headerView.trailingAnchor.constraint(equalTo: secureContentsView.trailingAnchor, constant: -12),

            // containerView
            containerView.leadingAnchor.constraint(equalTo: secureContentsView.leadingAnchor),
            containerView.topAnchor.constraint(equalTo: secureContentsView.topAnchor),
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

        containerView.addSubview(view)

        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            view.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 4),
            view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
    }
}

extension CollectionFileCell: TransferViewDelegate {
    func transferView(_ view: TransferView, didSelect action: MessageAction) {
        self.delegate?.collectionCell(self, performAction: action)
    }
}
