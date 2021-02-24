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
import Cartography
import UIKit
import WireSystem
import WireDataModel
import WireCommonComponents

final class CollectionFileCell: CollectionCell {
    private let fileTransferView = FileTransferView()
    private let headerView = CollectionCellHeader()

    override func updateForMessage(changeInfo: MessageChangeInfo?) {
        super.updateForMessage(changeInfo: changeInfo)

        guard let message = self.message else {
            return
        }
        headerView.message = message
        fileTransferView.configure(for: message, isInitial: changeInfo == .none)
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
        self.fileTransferView.delegate = self
        self.fileTransferView.layer.cornerRadius = 4
        self.fileTransferView.clipsToBounds = true

        self.secureContentsView.layoutMargins = UIEdgeInsets(top: 16, left: 4, bottom: 4, right: 4)
        self.secureContentsView.addSubview(self.headerView)
        self.secureContentsView.addSubview(self.fileTransferView)

        constrain(self.secureContentsView, self.fileTransferView, self.headerView) { contentView, fileTransferView, headerView in
            headerView.top == contentView.topMargin
            headerView.leading == contentView.leadingMargin + 12
            headerView.trailing == contentView.trailingMargin - 12

            fileTransferView.top == headerView.bottom + 4

            fileTransferView.left == contentView.leftMargin
            fileTransferView.right == contentView.rightMargin
            fileTransferView.bottom == contentView.bottomMargin
        }
    }

    override var obfuscationIcon: StyleKitIcon {
        return .document
    }

}

extension CollectionFileCell: TransferViewDelegate {
    func transferView(_ view: TransferView, didSelect action: MessageAction) {
        self.delegate?.collectionCell(self, performAction: action)
    }
}
