//
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

import Photos
import UIKit

protocol ImageManagerProtocol {
    func cancelImageRequest(_ requestID: PHImageRequestID)

    @discardableResult
    func requestImage(for asset: PHAsset, targetSize: CGSize, contentMode: PHImageContentMode, options: PHImageRequestOptions?, resultHandler: @escaping (UIImage?, [AnyHashable: Any]?) -> Void) -> PHImageRequestID

    @discardableResult
    func requestImageData(for asset: PHAsset, options: PHImageRequestOptions?, resultHandler: @escaping (Data?, String?, UIImage.Orientation, [AnyHashable: Any]?) -> Void) -> PHImageRequestID

    @discardableResult
    func requestExportSession(forVideo asset: PHAsset, options: PHVideoRequestOptions?, exportPreset: String, resultHandler: @escaping (AVAssetExportSession?, [AnyHashable: Any]?) -> Void) -> PHImageRequestID

    static var defaultInstance: ImageManagerProtocol { get }
}

extension PHImageManager: ImageManagerProtocol {
    static var defaultInstance: ImageManagerProtocol {
        return PHImageManager.default()
    }
}
