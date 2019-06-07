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
import MobileCoreServices

extension UIPasteboard {

    func pasteboardType(forMediaAsset mediaAsset: MediaAsset) -> String {
        if mediaAsset.isGIF() {
            return kUTTypeGIF as String
        } else if mediaAsset.isTransparent() {
            return kUTTypePNG as String
        } else {
            return kUTTypeJPEG as String
        }
    }

    @objc
    public func mediaAssets() -> [MediaAsset] {

        var mediaAssets = [MediaAsset]()

        for i in 0..<numberOfItems {
            let indexSet = IndexSet(integer: i)

            if let types = types(forItemSet: indexSet)?.first {
                for type in types {
                    let data = self.data(forPasteboardType: type, inItemSet: indexSet)?.first

                    if type == kUTTypeGIF as String, ///TODO: it is one frame GIF?
                        let data = data {
                        mediaAssets.append(FLAnimatedImage(animatedGIFData: data))
                    } else if type == kUTTypePNG as String,
                        let data = data,
                        let image = UIImage(data: data) {
                        mediaAssets.append(image)
                    } else if hasImages,
                        let data = data,
                        let image = UIImage(data: data) {
                        mediaAssets.append(image)
                    }
                }
            }
        }
        return mediaAssets
    }

    @objc func setMediaAsset(_ image: MediaAsset?) {
        guard let image = image else { return }

        UIPasteboard.general.setData(image.data(), forPasteboardType: pasteboardType(forMediaAsset: image))
    }
}
