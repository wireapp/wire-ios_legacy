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

extension ConversationContentViewController {
    @objc(saveImageFromMessage:cell:)
    func saveImage(from message: ZMConversationMessage?, cell: ImageMessageCell?) {
        var savableImage: SavableImage?
        var snapshot: UIView?
        var sourceRect: CGRect?

        if let cell = cell {
            savableImage = cell.savableImage
            snapshot = cell.fullImageView.snapshotView(afterScreenUpdates: true)
            sourceRect = self.view.convert(cell.fullImageView.frame, from: cell.fullImageView.superview)
        } else {
            if let imageData = message?.imageMessageData?.imageData {
                savableImage = SavableImage(data: imageData, orientation: .up)
                /// TODO: savableImage is not reteined?

                if let savableImage = savableImage {
                    snapshot = UIImageView(image: UIImage(data: savableImage.imageData))
                    savableImage.saveToLibrary()
                }
                sourceRect = self.view.frame

            }
        }

        savableImage?.saveToLibrary(withCompletion: {(_ success: Bool) -> Void in
            if nil != self.view.window && success == true {
                snapshot?.translatesAutoresizingMaskIntoConstraints = true
                self.delegate.conversationContentViewController(self, performImageSaveAnimation: snapshot, sourceRect: sourceRect!)
            }
        })

    }
}
