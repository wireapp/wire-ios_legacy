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

extension ConversationContentViewController {
    func saveImage(from message: ZMConversationMessage, view: UIView?) {
        guard let imageMessageData = message.imageMessageData, let imageData = imageMessageData.imageData else { return }

        let savableImage = SavableImage(data: imageData, isGIF: imageMessageData.isAnimatedGIF)

        if let view = view {
            let sourceView: UIView

            if let selectableView = view as? SelectableView {
                sourceView = selectableView.selectionView
            } else {
                sourceView = view
            }

            let snapshot = sourceView.snapshotView(afterScreenUpdates: true)
            let sourceRect = sourceView.convert(sourceView.frame, from: sourceView.superview)

            savableImage.saveToLibrary { success in
                guard nil != self.view.window, success else { return }
                snapshot?.translatesAutoresizingMaskIntoConstraints = true
                self.delegate?.conversationContentViewController(self, performImageSaveAnimation: snapshot, sourceRect: sourceRect)
            }
        } else {
            savableImage.saveToLibrary()
        }
    }
}
