
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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
import MobileCoreServices

extension ImagePickerConfirmationController {

    @objc
    func assetPreview(fromMediaInfo info: [AnyHashable : Any]?, resultBlock: @escaping (_ media: Any?) -> Void) {
        
        guard let url = info?[UIImagePickerController.InfoKey.referenceURL] as? URL else {
            resultBlock(nil)
            return
        }

        let assetUTI = url.UTI()

        if (assetUTI == kUTTypeGIF as String) {
            UIImagePickerController.imageData(fromMediaInfo: info, resultBlock: { imageData in
                if let imageData = imageData {
                    resultBlock(try? UIImage(gifData: imageData))
                } else {
                    resultBlock(nil)
                }
            })
        } else {
            UIImagePickerController.image(fromMediaInfo: info, resultBlock: { image in
                resultBlock(image)
            })
        }
    }

}
