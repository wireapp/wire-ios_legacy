//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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
import WireDataModel

internal enum UserProfileImageUpdateError: Error {
    case preprocessingFailed
    case uploadFailed(Error)
}

internal protocol UserProfileImageUpdateStateDelegate: AnyObject {
    func failed(withError: UserProfileImageUpdateError)
}

internal protocol UserProfileImageUploadStatusProtocol: AnyObject {
    func hasAssetToDelete() -> Bool
    func consumeAssetToDelete() -> String?
    func consumeImage(for size: ProfileImageSize) -> Data?
    func hasImageToUpload(for size: ProfileImageSize) -> Bool
    func uploadingDone(imageSize: ProfileImageSize, assetId: String)
    func uploadingFailed(imageSize: ProfileImageSize, error: Error)
}

@objc public protocol UserProfileImageUpdateProtocol: AnyObject {
    @objc(updateImageWithImageData:)
    func updateImage(imageData: Data)
}

internal protocol UserProfileImageUploadStateChangeDelegate: AnyObject {
    func didTransition(from oldState: UserProfileImageUpdateStatus.ProfileUpdateState, to currentState: UserProfileImageUpdateStatus.ProfileUpdateState)
    func didTransition(from oldState: UserProfileImageUpdateStatus.ImageState, to currentState: UserProfileImageUpdateStatus.ImageState, for size: ProfileImageSize)
}

public final class UserProfileImageUpdateStatus: NSObject {

    fileprivate var log = ZMSLog(tag: "UserProfileImageUpdateStatus")

    internal enum ImageState {
        case ready
        case preprocessing
        case upload(image: Data)
        case uploading
        case uploaded(assetId: String)
        case failed(UserProfileImageUpdateError)

        internal func canTransition(to newState: ImageState) -> Bool {
            switch (self, newState) {
            case (.ready, .preprocessing),
                 (.preprocessing, .upload),
                 (.upload, .uploading),
                 (.uploading, .uploaded),
                 (.ready, .upload): // When re-uploading a preprocessed v2 to v3
                return true
            case (.uploaded, .ready),
                 (.failed, .ready):
                return true
            case (.failed, .failed):
                return false
            case (_, .failed):
                return true
            default:
                return false
            }
        }
    }

    internal enum ProfileUpdateState {
        case ready
        case preprocess(image: Data)
        case update(previewAssetId: String, completeAssetId: String)
        case failed(UserProfileImageUpdateError)

        internal func canTransition(to newState: ProfileUpdateState) -> Bool {
            switch (self, newState) {
            case (.ready, .preprocess),
                 (.preprocess, .update),
                 (.ready, .update): // When re-uploading a preprocessed v2 to v3
                return true
            case (.update, .ready),
                 (.failed, .ready):
                return true
            case (.failed, .failed):
                return false
            case (_, .failed):
                return true
            default:
                return false
            }
        }
    }

    internal var preprocessor: ZMAssetsPreprocessorProtocol?
    internal let queue: OperationQueue
    internal weak var changeDelegate: UserProfileImageUploadStateChangeDelegate?

    fileprivate var changeDelegates: [UserProfileImageUpdateStateDelegate] = []
    fileprivate var imageOwner: ImageOwner?
    fileprivate let syncMOC: NSManagedObjectContext
    fileprivate let uiMOC: NSManagedObjectContext

    fileprivate var imageState = [ProfileImageSize: ImageState]()
    fileprivate var resizedImages = [ProfileImageSize: Data]()
    internal fileprivate(set) var state: ProfileUpdateState = .ready
    internal fileprivate(set) var assetsToDelete = Set<String>()

    public convenience init(managedObjectContext: NSManagedObjectContext) {
        self.init(managedObjectContext: managedObjectContext, preprocessor: ZMAssetsPreprocessor(delegate: nil), queue: ZMImagePreprocessor.createSuitableImagePreprocessingQueue(), delegate: nil)
    }

    internal init(managedObjectContext: NSManagedObjectContext, preprocessor: ZMAssetsPreprocessorProtocol, queue: OperationQueue, delegate: UserProfileImageUploadStateChangeDelegate?) {
        log.debug("Created")
        self.queue = queue
        self.preprocessor = preprocessor
        self.syncMOC = managedObjectContext
        self.uiMOC = managedObjectContext.zm_userInterface
        self.changeDelegate = delegate
        super.init()
        self.preprocessor?.delegate = self
    }

}

// MARK: Main state transitions
extension UserProfileImageUpdateStatus {
    internal func setState(state newState: ProfileUpdateState) {
        let currentState = self.state
        guard currentState.canTransition(to: newState) else {
            log.debug("Invalid transition: [\(currentState)] -> [\(newState)], ignoring")
            // Trying to transition to invalid state - ignore
            return
        }
        self.state = newState
        self.didTransition(from: currentState, to: newState)
    }

    private func didTransition(from oldState: ProfileUpdateState, to currentState: ProfileUpdateState) {
        log.debug("Transition: [\(oldState)] -> [\(currentState)]")
        changeDelegate?.didTransition(from: oldState, to: currentState)
        switch (oldState, currentState) {
        case (_, .ready):
            resetImageState()
        case let (_, .preprocess(image: data)):
            startPreprocessing(imageData: data)
        case let (_, .update(previewAssetId: previewAssetId, completeAssetId: completeAssetId)):
            updateUserProfile(with: previewAssetId, completeAssetId: completeAssetId)
        case (_, .failed):
            resetImageState()
            setState(state: .ready)
        }
    }

    private func updateUserProfile(with previewAssetId: String, completeAssetId: String) {
        let selfUser = ZMUser.selfUser(in: self.syncMOC)
        assetsToDelete.formUnion([selfUser.previewProfileAssetIdentifier, selfUser.completeProfileAssetIdentifier].compactMap { $0 })
        selfUser.updateAndSyncProfileAssetIdentifiers(previewIdentifier: previewAssetId, completeIdentifier: completeAssetId)
        selfUser.setImage(data: resizedImages[.preview], size: .preview)
        selfUser.setImage(data: resizedImages[.complete], size: .complete)
        self.resetImageState()
        self.syncMOC.saveOrRollback()
        self.setState(state: .ready)
    }

    private func startPreprocessing(imageData: Data) {
        ProfileImageSize.allSizes.forEach {
            setState(state: .preprocessing, for: $0)
        }

        let imageOwner = UserProfileImageOwner(imageData: imageData)
        guard let operations = preprocessor?.operations(forPreprocessingImageOwner: imageOwner), !operations.isEmpty else {
            resetImageState()
            setState(state: .failed(.preprocessingFailed))
            return
        }

        queue.addOperations(operations, waitUntilFinished: false)
    }
}

// MARK: Image state transitions
extension UserProfileImageUpdateStatus {
    internal func imageState(for imageSize: ProfileImageSize) -> ImageState {
        return imageState[imageSize] ?? .ready
    }

    internal func setState(state newState: ImageState, for imageSize: ProfileImageSize) {
        let currentState = self.imageState(for: imageSize)
        guard currentState.canTransition(to: newState) else {
            // Trying to transition to invalid state - ignore
            return
        }

        self.imageState[imageSize] = newState
        self.didTransition(from: currentState, to: newState, for: imageSize)
    }

    internal func resetImageState() {
        imageState.removeAll()
        resizedImages.removeAll()
    }

    private func didTransition(from oldState: ImageState, to currentState: ImageState, for size: ProfileImageSize) {
        log.debug("Transition [\(size)]: [\(oldState)] -> [\(currentState)]")
        changeDelegate?.didTransition(from: oldState, to: currentState, for: size)
        switch (oldState, currentState) {
        case let (_, .upload(image)):
            resizedImages[size] = image
            RequestAvailableNotification.notifyNewRequestsAvailable(self)
        case (_, .uploaded):
            // When one image is uploaded we check state of all other images
            let previewState = imageState(for: .preview)
            let completeState = imageState(for: .complete)

            switch (previewState, completeState) {
            case let (.uploaded(assetId: previewAssetId), .uploaded(assetId: completeAssetId)):
                // If both images are uploaded we can update profile
                setState(state: .update(previewAssetId: previewAssetId, completeAssetId: completeAssetId))
            default:
                break // Need to wait until both images are uploaded
            }
        case let (_, .failed(error)):
            setState(state: .failed(error))
        default:
            break
        }
    }
}

// Called from the UI to update a v3 image
extension UserProfileImageUpdateStatus: UserProfileImageUpdateProtocol {

    /// Starts the process of updating profile picture. 
    ///
    /// - Important: Expected to be run from UI thread
    ///
    /// - Parameter imageData: image data of the new profile picture
    public func updateImage(imageData: Data) {
        syncMOC.performGroupedBlock {
            self.setState(state: .preprocess(image: imageData))
        }
    }
}

extension UserProfileImageUpdateStatus: ZMAssetsPreprocessorDelegate {

    public func completedDownsampleOperation(_ operation: ZMImageDownsampleOperationProtocol, imageOwner: ZMImageOwner) {
        syncMOC.performGroupedBlock {
            ProfileImageSize.allSizes.forEach {
                if operation.format == $0.imageFormat,
                   let downsampleImageData = operation.downsampleImageData {
                    self.setState(state: .upload(image: downsampleImageData), for: $0)
                }
            }
        }
    }

    public func failedPreprocessingImageOwner(_ imageOwner: ZMImageOwner) {
        syncMOC.performGroupedBlock {
            self.setState(state: .failed(.preprocessingFailed))
        }
    }

    public func didCompleteProcessingImageOwner(_ imageOwner: ZMImageOwner) {}

    public func preprocessingCompleteOperation(for imageOwner: ZMImageOwner) -> Operation? {
        let dispatchGroup = syncMOC.dispatchGroup
        dispatchGroup?.enter()
        return BlockOperation {
            dispatchGroup?.leave()
        }
    }
}

extension UserProfileImageUpdateStatus: UserProfileImageUploadStatusProtocol {

    /// Checks if there are assets that needs to be deleted
    ///
    /// - Returns: true if there are assets that needs to be deleted
    func hasAssetToDelete() -> Bool {
        return !assetsToDelete.isEmpty
    }

    /// Takes an asset ID that needs to be deleted and removes from the internal list
    ///
    /// - Returns: Asset ID or nil if nothing needs to be deleted
    internal func consumeAssetToDelete() -> String? {
        return assetsToDelete.removeFirst()
    }

    /// Checks if there is an image to upload
    ///
    /// - Important: should be called from sync thread
    /// - Parameter size: which image size to check
    /// - Returns: true if there is an image of this size ready for upload
    internal func hasImageToUpload(for size: ProfileImageSize) -> Bool {
        switch imageState(for: size) {
        case .upload:
            return true
        default:
            return false
        }
    }

    /// Takes an image that is ready for upload and marks it internally
    /// as currently being uploaded.
    ///
    /// - Parameter size: size of the image
    /// - Returns: Image data if there is image of this size ready for upload
    internal func consumeImage(for size: ProfileImageSize) -> Data? {
        switch imageState(for: size) {
        case .upload(image: let image):
            setState(state: .uploading, for: size)
            return image
        default:
            return nil
        }
    }

    /// Marks the image as uploaded successfully
    ///
    /// - Parameters:
    ///   - imageSize: size of the image
    ///   - assetId: resulting asset identifier after uploading it to the store
    internal func uploadingDone(imageSize: ProfileImageSize, assetId: String) {
        setState(state: .uploaded(assetId: assetId), for: imageSize)
    }

    /// Marks the image as failed to upload
    ///
    /// - Parameters:
    ///   - imageSize: size of the image
    ///   - error: transport error
    internal func uploadingFailed(imageSize: ProfileImageSize, error: Error) {
        setState(state: .failed(.uploadFailed(error)), for: imageSize)
    }
}
