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
import FLAnimatedImage
import UIKit
import WireDataModel

extension ZMConversationMessage {

    func copy(in pasteboard: UIPasteboard) {
        if self.isText {
            if let text = textMessageData?.messageText, !text.isEmpty {
                pasteboard.string = text
            }
        } else if isImage,
                  let imageData = imageMessageData?.imageData {

            let mediaAsset: MediaAsset?
            if imageMessageData?.isAnimatedGIF == true {
                mediaAsset = FLAnimatedImage(animatedGIFData: imageData)
            } else {
                mediaAsset = UIImage(data: imageData)
            }

            UIPasteboard.general.setMediaAsset(mediaAsset)
        } else if self.isLocation {
            if let locationName = locationMessageData?.name {
                pasteboard.string = locationName
            }
        }
    }

}
