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
import Photos

protocol AssetLibraryDelegate: class {
    func assetLibraryDidChange(_ library: AssetLibrary)
}

class AssetLibrary: NSObject, PHPhotoLibraryChangeObserver {
    weak var delegate: AssetLibraryDelegate?
    fileprivate var fetchingAssets = false
    public let synchronous: Bool
    let photoLibrary: PhotoLibraryProtocol

    var count: UInt {
        guard let fetch = self.fetch else {
            return 0
        }
        return UInt(fetch.count)
    }

    public enum AssetError: Error {
        case outOfRange, notLoadedError
    }

    func asset(atIndex index: UInt) throws -> PHAsset {
        guard let fetch = self.fetch else {
            throw AssetError.notLoadedError
        }

        if index >= count {
            throw AssetError.outOfRange
        }
        return fetch.object(at: Int(index))
    }

    func refetchAssets(synchronous: Bool = false) {
        guard !self.fetchingAssets else {
            return
        }

        self.fetchingAssets = true

        let syncOperation = {
            let options = PHFetchOptions()
            options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            self.fetch = PHAsset.fetchAssets(with: options)
            self.notifyChangeToDelegate()
        }

        if synchronous {
            syncOperation()
        }
        else {
            DispatchQueue(label: "WireAssetLibrary", qos: DispatchQoS.background, attributes: [], autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency.inherit, target: .none).async(execute: syncOperation)
        }
    }

    public func photoLibraryDidChange(_ changeInstance: PHChange) {

        guard let fetch = self.fetch else {
            return
        }

        guard let changeDetails = changeInstance.changeDetails(for: fetch) else {
            return
        }

        self.fetch = changeDetails.fetchResultAfterChanges
        self.notifyChangeToDelegate()

    }

    fileprivate var fetch: PHFetchResult<PHAsset>?

    fileprivate func notifyChangeToDelegate() {

        let completion = {
            self.delegate?.assetLibraryDidChange(self)
            self.fetchingAssets = false
        }

        if synchronous {
            completion()
        } else {
            DispatchQueue.main.async(execute: completion)
        }

    }

    init(synchronous: Bool = false, photoLibrary: PhotoLibraryProtocol = PHPhotoLibrary.shared()) {
        self.synchronous = synchronous
        self.photoLibrary = photoLibrary

        super.init()

        self.photoLibrary.register(self)
        self.refetchAssets(synchronous: synchronous)
    }

    deinit {
        photoLibrary.unregisterChangeObserver(self)
    }
}
