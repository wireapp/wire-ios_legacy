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
import WireDataModel
import WireCommonComponents

final class CollectionVideoCell: CollectionCell {
    private let videoMessageView = VideoMessageView()

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.loadView()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.loadView()
    }

    override func updateForMessage(changeInfo: MessageChangeInfo?) {
        super.updateForMessage(changeInfo: changeInfo)

        guard let message = self.message else {
            return
        }

        videoMessageView.configure(for: message, isInitial: true)
    }

    func loadView() {

        self.videoMessageView.delegate = self
        self.videoMessageView.clipsToBounds = true
        self.videoMessageView.timeLabelHidden = true
        self.secureContentsView.addSubview(self.videoMessageView)

        constrain(self.contentView, self.videoMessageView) { contentView, videoMessageView in
            videoMessageView.edges == contentView.edges
        }
    }

    override var obfuscationIcon: StyleKitIcon {
        return .movie
    }

}

extension CollectionVideoCell: TransferViewDelegate {
    func transferView(_ view: TransferView, didSelect action: MessageAction) {
        self.delegate?.collectionCell(self, performAction: action)
    }
}
