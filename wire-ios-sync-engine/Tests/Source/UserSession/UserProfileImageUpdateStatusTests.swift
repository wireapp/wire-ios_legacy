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

import XCTest
@testable import WireSyncEngine
import WireUtilities

var sampleUploadState: UserProfileImageUpdateStatus.ImageState {
    return UserProfileImageUpdateStatus.ImageState.upload(image: Data())
}
var sampleUploadedState: UserProfileImageUpdateStatus.ImageState {
    return UserProfileImageUpdateStatus.ImageState.uploaded(assetId: "foo")
}
var sampleFailedImageState: UserProfileImageUpdateStatus.ImageState {
    return UserProfileImageUpdateStatus.ImageState.failed(.preprocessingFailed)
}

var samplePreprocessState: UserProfileImageUpdateStatus.ProfileUpdateState {
    return UserProfileImageUpdateStatus.ProfileUpdateState.preprocess(image: Data())
}
var sampleUpdateState: UserProfileImageUpdateStatus.ProfileUpdateState {
    return UserProfileImageUpdateStatus.ProfileUpdateState.update(previewAssetId: "id1", completeAssetId: "id2")
}
var sampleFailedState: UserProfileImageUpdateStatus.ProfileUpdateState {
    return UserProfileImageUpdateStatus.ProfileUpdateState.failed(.preprocessingFailed)
}

class MockPreprocessor: NSObject, ZMAssetsPreprocessorProtocol {
    weak var delegate: ZMAssetsPreprocessorDelegate?
    var operations = [Operation]()

    var imageOwner: ZMImageOwner?
    var operationsCalled: Bool = false

    func operations(forPreprocessingImageOwner imageOwner: ZMImageOwner) -> [Operation]? {
        operationsCalled = true
        self.imageOwner = imageOwner
        return operations
    }
}

class MockOperation: NSObject, ZMImageDownsampleOperationProtocol {
    let downsampleImageData: Data
    let format: ZMImageFormat
    let properties: ZMIImageProperties

    init(downsampleImageData: Data = Data(), format: ZMImageFormat = .original, properties: ZMIImageProperties = ZMIImageProperties(size: .zero, length: 0, mimeType: "foo")) {
        self.downsampleImageData = downsampleImageData
        self.format = format
        self.properties = properties
    }
}

public typealias ProfileUpdateState = WireSyncEngine.UserProfileImageUpdateStatus.ProfileUpdateState
typealias ImageState = WireSyncEngine.UserProfileImageUpdateStatus.ImageState

class MockChangeDelegate: WireSyncEngine.UserProfileImageUploadStateChangeDelegate {
    var states = [ProfileUpdateState]()
    func didTransition(from oldState: ProfileUpdateState, to currentState: ProfileUpdateState) {
        states.append(currentState)
    }

    func check(lastStates: [ProfileUpdateState], file: StaticString = #file, line: UInt = #line) {
        XCTAssert(states.count >= lastStates.count, "Not enough transitions happened. States: \(states)", file: file, line: line)
        let suffix = Array(states.suffix(lastStates.count))
        XCTAssertEqual(suffix, lastStates, "Expected last transitions: \(lastStates) have \(suffix)", file: file, line: line)
    }

    var imageStates = [ProfileImageSize: [ImageState]]()

    func didTransition(from oldState: ImageState, to currentState: ImageState, for size: ProfileImageSize) {
        var states = imageStates[size] ?? [ImageState]()
        states.append(currentState)
        imageStates[size] = states
    }
}

enum MockUploadError: String, Error {
    case failed
}

class MockImageOwner: NSObject, ZMImageOwner {
    public func requiredImageFormats() -> NSOrderedSet { return NSOrderedSet() }
    public func imageData(for format: ZMImageFormat) -> Data? { return Data() }
    public func setImageData(_ imageData: Data, for format: ZMImageFormat, properties: ZMIImageProperties?) {}
    public func originalImageData() -> Data? { return Data() }
    public func originalImageSize() -> CGSize { return .zero }
    public func isInline(for format: ZMImageFormat) -> Bool { return false }
    public func isPublic(for format: ZMImageFormat) -> Bool { return false }
    public func isUsingNativePush(for format: ZMImageFormat) -> Bool { return false }
    public func processingDidFinish() {}
}

protocol StateTransition: Equatable {
    func canTransition(to: Self) -> Bool
    static var allStates: [Self] { get }
}

extension StateTransition {
    func checkThatTransition(to newState: Self, isValid: Bool, file: StaticString = #file, line: UInt = #line) {
        let result = self.canTransition(to: newState)
        if isValid {
            XCTAssertTrue(result, "Should transition: [\(self)] -> [\(newState)]", file: file, line: line)
        } else {
            XCTAssertFalse(result, "Should not transition: [\(self)] -> [\(newState)]", file: file, line: line)
        }
    }

    static func canTransition(from oldState: Self, onlyTo newStates: [Self], file: StaticString = #file, line: UInt = #line) {
        for state in Self.allStates {
            let isValid = newStates.contains(state)
            oldState.checkThatTransition(to: state, isValid: isValid, file: file, line: line)
        }
    }
}

public typealias UserProfileImageUpdateStatus = WireSyncEngine.UserProfileImageUpdateStatus

extension UserProfileImageUpdateStatus.ImageState: Equatable {
    public static func == (lhs: UserProfileImageUpdateStatus.ImageState, rhs: UserProfileImageUpdateStatus.ImageState) -> Bool {
        return String(describing: lhs) == String(describing: rhs)
    }
}

extension UserProfileImageUpdateStatus.ImageState: StateTransition {
    static var allStates: [ImageState] {
        return [.ready, .preprocessing, sampleUploadState, .uploading, sampleUploadedState, sampleFailedImageState]
    }
}

extension ProfileUpdateState: Equatable {
    public static func == (lhs: ProfileUpdateState, rhs: ProfileUpdateState) -> Bool {
        return String(describing: lhs) == String(describing: rhs)
    }
}

extension ProfileUpdateState: StateTransition {
    static var allStates: [ProfileUpdateState] {
        return [.ready, samplePreprocessState, sampleUpdateState, sampleFailedState]
    }
}

class UserProfileImageUpdateStatusTests: MessagingTest {
    var sut: UserProfileImageUpdateStatus!
    var preprocessor: MockPreprocessor!
    var tinyImage: Data!
    var imageOwner: ZMImageOwner!
    var changeDelegate: MockChangeDelegate!

    override func setUp() {
        super.setUp()
        preprocessor = MockPreprocessor()
        preprocessor.operations = [Operation()]
        sut = UserProfileImageUpdateStatus(managedObjectContext: syncMOC, preprocessor: preprocessor, queue: ZMImagePreprocessor.createSuitableImagePreprocessingQueue(), delegate: nil)
        tinyImage = data(forResource: "tiny", extension: "jpg")
        imageOwner = UserProfileImageOwner(imageData: tinyImage)
        changeDelegate = MockChangeDelegate()
        self.sut.changeDelegate = changeDelegate
    }

    override func tearDown() {
        preprocessor = nil
        sut = nil
        tinyImage = nil
        imageOwner = nil
        changeDelegate = nil
        super.tearDown()
    }

    func operationWithExpectation(description: String) -> Operation {
        let expectation = self.expectation(description: description)
        return BlockOperation {
            expectation.fulfill()
        }
    }
}

// MARK: Image state transitions
extension UserProfileImageUpdateStatusTests {
    func testThatImageStateStartsWithReadyState() {
        syncMOC.performGroupedBlockAndWait {
            XCTAssertEqual(self.sut.imageState(for: .preview), .ready)
            XCTAssertEqual(self.sut.imageState(for: .complete), .ready)
        }
    }

    func testImageStateTransitions() {
        ImageState.canTransition(from: .ready, onlyTo: [sampleFailedImageState, .preprocessing, sampleUploadState])
        ImageState.canTransition(from: .preprocessing, onlyTo: [sampleFailedImageState, sampleUploadState])
        ImageState.canTransition(from: sampleUploadState, onlyTo: [sampleFailedImageState, .uploading])
        ImageState.canTransition(from: .uploading, onlyTo: [sampleFailedImageState, sampleUploadedState])
        ImageState.canTransition(from: sampleUploadedState, onlyTo: [sampleFailedImageState, .ready])
        ImageState.canTransition(from: sampleFailedImageState, onlyTo: [.ready])
    }

    func testThatImageStateCanTransitionToValidState() {
        syncMOC.performGroupedBlockAndWait {
            // WHEN
            self.sut.setState(state: .preprocessing, for: .complete)

            // THEN
            XCTAssertEqual(self.sut.imageState(for: .complete), .preprocessing)
            XCTAssertEqual(self.sut.imageState(for: .preview), .ready)
        }
    }

    func testThatImageStateDoesntTransitionToInvalidState() {
        syncMOC.performGroupedBlockAndWait {
            // WHEN
            self.sut.setState(state: .uploading, for: .preview)

            // THEN
            XCTAssertEqual(self.sut.imageState(for: .preview), .ready)
            XCTAssertEqual(self.sut.imageState(for: .complete), .ready)
        }
    }

    func testThatImageStateMaintainsSeparateStatesForDifferentSizes() {
        syncMOC.performGroupedBlockAndWait {
            // WHEN
            self.sut.setState(state: .preprocessing, for: .preview)

            // THEN
            XCTAssertEqual(self.sut.imageState(for: .preview), .preprocessing)
            XCTAssertEqual(self.sut.imageState(for: .complete), .ready)
        }
    }

    func testThatProfileUpdateStateIsSetToUpdateAfterAllImageStatesAreUploaded() {
        syncMOC.performGroupedBlockAndWait {
            // GIVEN
            self.sut.setState(state: samplePreprocessState)
            self.sut.setState(state: .preprocessing, for: .preview)
            self.sut.setState(state: .preprocessing, for: .complete)
            self.sut.setState(state: sampleUploadState, for: .preview)
            self.sut.setState(state: sampleUploadState, for: .complete)
            self.sut.setState(state: .uploading, for: .preview)
            self.sut.setState(state: .uploading, for: .complete)

            XCTAssertEqual(self.sut.imageState(for: .preview), .uploading)
            XCTAssertEqual(self.sut.imageState(for: .complete), .uploading)

            // WHEN
            let previewAssetId = "asset_preview"
            let completeAssetId = "asset_complete"

            self.sut.setState(state: .uploaded(assetId: previewAssetId), for: .preview)
            self.sut.setState(state: .uploaded(assetId: completeAssetId), for: .complete)

            // THEN
            self.changeDelegate.check(lastStates: [.update(previewAssetId: previewAssetId, completeAssetId: completeAssetId), .ready])
            XCTAssertEqual(self.sut.imageState(for: .preview), .ready)
            XCTAssertEqual(self.sut.imageState(for: .complete), .ready)
        }
    }

    func testThatProfileUpdateStateIsSetToFailedAfterAnyImageStatesIsFailed() {
        syncMOC.performGroupedBlockAndWait {
            // WHEN
            self.sut.setState(state: .preprocessing, for: .preview)
            self.sut.setState(state: sampleUploadState, for: .preview)
            self.sut.setState(state: sampleFailedImageState, for: .preview)

            // THEN
            self.changeDelegate.check(lastStates: [.failed(.preprocessingFailed), .ready])
        }
    }

}

// MARK: Main state transitions
extension UserProfileImageUpdateStatusTests {
    func testThatProfileUpdateStateStartsWithReadyState() {
        syncMOC.performGroupedBlockAndWait {
            XCTAssertEqual(self.sut.state, .ready)
        }
    }

    func testProfileUpdateStateTransitions() {
        ProfileUpdateState.canTransition(from: .ready, onlyTo: [sampleFailedState, samplePreprocessState, sampleUpdateState])
        ProfileUpdateState.canTransition(from: samplePreprocessState, onlyTo: [sampleFailedState, sampleUpdateState])
        ProfileUpdateState.canTransition(from: sampleUpdateState, onlyTo: [sampleFailedState, .ready])
        ProfileUpdateState.canTransition(from: sampleFailedState, onlyTo: [.ready])
    }

    func testThatProfileUpdateStateCanTransitionToValidState() {
        syncMOC.performGroupedBlockAndWait {
            // WHEN
            self.sut.setState(state: samplePreprocessState)

            // THEN
            XCTAssertEqual(self.sut.state, samplePreprocessState)
        }
    }

    func testThatProfileUpdateStateDoesntTransitionToInvalidState() {
        syncMOC.performGroupedBlockAndWait {
            // WHEN
            self.sut.setState(state: .ready)

            // THEN
            XCTAssertEqual(self.changeDelegate.states, [])
        }
    }

    func testThatWhenProfileUpdateStateIsFailedImageStatesAreBackToReady() {
        syncMOC.performGroupedBlockAndWait {
            // GIVEN
            self.sut.setState(state: .preprocessing, for: .preview)
            self.sut.setState(state: .preprocessing, for: .complete)

            // WHEN
            self.sut.setState(state: .failed(.preprocessingFailed))

            // THEN
            self.changeDelegate.check(lastStates: [.failed(.preprocessingFailed), .ready])
            XCTAssertEqual(self.sut.imageState(for: .preview), .ready)
            XCTAssertEqual(self.sut.imageState(for: .complete), .ready)
        }
    }
}

// MARK: Preprocessing
extension UserProfileImageUpdateStatusTests {
    func testThatItSetsPreprocessorDelegateWhenProcessing() {
        // WHEN
        self.sut.updateImage(imageData: tinyImage)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        XCTAssertNotNil(preprocessor.delegate)
    }

    func testThatItAsksPreprocessorForOperationsWithCorrectImageOwner() {
        // WHEN
        self.sut.updateImage(imageData: tinyImage)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        XCTAssertTrue(preprocessor.operationsCalled)
        let imageOwner = preprocessor.imageOwner
        XCTAssertNotNil(imageOwner)
        XCTAssertEqual(imageOwner?.originalImageData(), tinyImage)
    }

    func testThatPreprocessingFailsWhenNoOperationsAreReturned() {
        // GIVEN
        preprocessor.operations = []

        // WHEN
        self.sut.updateImage(imageData: tinyImage)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        self.changeDelegate.check(lastStates: [.failed(.preprocessingFailed), .ready])
        XCTAssertEqual(self.sut.imageState(for: .preview), .ready)
        XCTAssertEqual(self.sut.imageState(for: .complete), .ready)
    }

    func testThatResizeOperationsAreEnqueued() {
        // GIVEN
        let e1 = self.operationWithExpectation(description: "#1 Image processing done")
        let e2 = self.operationWithExpectation(description: "#2 Image processing done")
        preprocessor.operations = [e1, e2]

        // WHEN
        self.sut.updateImage(imageData: tinyImage)

        // THEN 
        XCTAssertTrue(self.waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatAfterDownsamplingImageItSetsCorrectState() {
        // GIVEN
        syncMOC.performGroupedBlockAndWait {
            self.sut.setState(state: .preprocessing, for: .complete)
            self.sut.setState(state: .preprocessing, for: .preview)
        }

        let previewOperation = MockOperation(downsampleImageData: "preview".data(using: .utf8)!, format: ProfileImageSize.preview.imageFormat)
        let completeOperation = MockOperation(downsampleImageData: "complete".data(using: .utf8)!, format: ProfileImageSize.complete.imageFormat)

        // WHEN
        self.sut.completedDownsampleOperation(previewOperation, imageOwner: self.imageOwner)
        XCTAssert(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        XCTAssertEqual(self.sut.imageState(for: .preview), .upload(image: previewOperation.downsampleImageData))
        XCTAssertEqual(self.sut.imageState(for: .complete), .preprocessing)

        // WHEN
        self.sut.completedDownsampleOperation(completeOperation, imageOwner: self.imageOwner)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        XCTAssertEqual(self.sut.imageState(for: .preview), .upload(image: previewOperation.downsampleImageData))
        XCTAssertEqual(self.sut.imageState(for: .complete), .upload(image: completeOperation.downsampleImageData))
    }

    func testThatIfDownsamplingFailsStateForAllSizesIsSetToFail() {
        // GIVEN
        syncMOC.performGroupedBlockAndWait {
            self.sut.setState(state: .preprocessing, for: .complete)
            self.sut.setState(state: .preprocessing, for: .preview)
        }

        // WHEN
        self.sut.failedPreprocessingImageOwner(imageOwner)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        self.changeDelegate.check(lastStates: [.failed(.preprocessingFailed), .ready])
        XCTAssertEqual(self.sut.imageState(for: .preview), .ready)
        XCTAssertEqual(self.sut.imageState(for: .complete), .ready)
    }

    func testThatItIsPossibleToStartPreprocessingAgainIfProfileUpdateFails() {
        // GIVEN
        self.sut.updateImage(imageData: Data())
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(self.sut.state, .preprocess(image: Data()))
        XCTAssertEqual(self.sut.imageState(for: .preview), .preprocessing)
        XCTAssertEqual(self.sut.imageState(for: .complete), .preprocessing)
        syncMOC.performGroupedBlockAndWait {
            self.sut.setState(state: .failed(.preprocessingFailed))
        }

        // WHEN
        preprocessor.operations = [Operation()]
        let imageData = "some".data(using: .utf8)!
        self.sut.updateImage(imageData: imageData)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        self.changeDelegate.check(lastStates: [.failed(.preprocessingFailed), .ready, .preprocess(image: imageData)])
        XCTAssertEqual(self.sut.imageState(for: .preview), .preprocessing)
        XCTAssertEqual(self.sut.imageState(for: .complete), .preprocessing)
    }
}

// MARK: - Image upload status
extension UserProfileImageUpdateStatusTests {

    func testThatItReturnsImageToUploadOnlyWhenInUploadState() {
        syncMOC.performGroupedBlockAndWait {
            // GIVEN
            XCTAssertFalse(self.sut.hasImageToUpload(for: .preview))
            self.sut.setState(state: .preprocessing, for: .preview)
            self.sut.setState(state: .upload(image: Data()), for: .preview)

            // THEN
            XCTAssertTrue(self.sut.hasImageToUpload(for: .preview))
            XCTAssertFalse(self.sut.hasImageToUpload(for: .complete))
        }
    }

    func testThatItAdvancesStateAfterConsumingImage() {
        syncMOC.performGroupedBlockAndWait {
            // GIVEN
            let data = "some".data(using: .utf8)!
            self.sut.setState(state: .preprocessing, for: .preview)
            self.sut.setState(state: .upload(image: data), for: .preview)

            // WHEN
            let dataToUpload = self.sut.consumeImage(for: .preview)
            XCTAssertNil(self.sut.consumeImage(for: .complete))

            // THEN
            XCTAssertEqual(data, dataToUpload)
            XCTAssertEqual(self.sut.imageState(for: .preview), .uploading)
        }
    }

    func testThatItAdvancesStateAfterUploadIsDone() {
        syncMOC.performGroupedBlockAndWait {
            // GIVEN
            self.sut.setState(state: .preprocessing, for: .preview)
            self.sut.setState(state: .upload(image: Data()), for: .preview)
            self.sut.setState(state: .uploading, for: .preview)

            // WHEN
            let assetId = "1234"
            self.sut.uploadingDone(imageSize: .preview, assetId: assetId)

            // THEN
            XCTAssertEqual(self.sut.imageState(for: .preview), .uploaded(assetId: assetId))
        }
    }

    func testThatItAdvancesStateAndPropogatesErrorWhenUploadFails() {
        syncMOC.performGroupedBlockAndWait {
            // GIVEN
            self.sut.setState(state: .preprocessing, for: .preview)
            self.sut.setState(state: .upload(image: Data()), for: .preview)
            self.sut.setState(state: .uploading, for: .preview)

            // WHEN
            self.sut.uploadingFailed(imageSize: .preview, error: MockUploadError.failed)

            // THEN
            XCTAssertEqual(self.sut.imageState(for: .preview), .ready)
            self.changeDelegate.check(lastStates: [.failed(.uploadFailed(MockUploadError.failed)), .ready])
        }
    }

    func testThatItSignalsThereIsRequestAvailableAfterPreprocessingCompletes() {
        expectation(forNotification: NSNotification.Name(rawValue: "RequestAvailableNotification"), object: nil)

        syncMOC.performGroupedBlock {
            // GIVEN
            self.sut.setState(state: .preprocessing, for: .preview)

            // WHEN
            self.sut.setState(state: .upload(image: Data()), for: .preview)
        }

        // THEN
        XCTAssert(waitForCustomExpectations(withTimeout: 0.1))
    }

}

// MARK: - User profile update
extension UserProfileImageUpdateStatusTests {
    func testThatItUpdatesUserProfileAndMarksPropertiesToBeUploaded() {
        syncMOC.performGroupedBlockAndWait {
            // GIVEN
            self.preprocessor.operations = [Operation()]
            let previewId = "foo"
            let completeId = "bar"
            self.sut.setState(state: .preprocess(image: Data()))

            // WHEN
            self.sut.setState(state: .update(previewAssetId: previewId, completeAssetId: completeId))

            // THEN
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            XCTAssertEqual(selfUser.previewProfileAssetIdentifier, previewId)
            XCTAssertEqual(selfUser.completeProfileAssetIdentifier, completeId)
            XCTAssert(selfUser.hasLocalModifications(forKey: #keyPath(ZMUser.previewProfileAssetIdentifier)))
            XCTAssert(selfUser.hasLocalModifications(forKey: #keyPath(ZMUser.completeProfileAssetIdentifier)))
        }
    }

    func testThatItSetsResizedImagesToSelfUserAfterCompletion() {
        // GIVEN
        let previewData = "small".data(using: .utf8)!
        let completeData = "laaaarge".data(using: .utf8)!
        let previewId = "foo"
        let completeId = "bar"

        let selfUser = ZMUser.selfUser(in: uiMOC)
        selfUser.remoteIdentifier = UUID()
        uiMOC.saveOrRollback()

        // WHEN
        self.sut.setState(state: .upload(image: previewData), for: .preview)
        self.sut.setState(state: .upload(image: completeData), for: .complete)
        syncMOC.performGroupedBlockAndWait {
            _ = self.self.sut.consumeImage(for: .preview)
            _ = self.self.sut.consumeImage(for: .complete)
            self.self.sut.uploadingDone(imageSize: .preview, assetId: previewId)
            self.self.sut.uploadingDone(imageSize: .complete, assetId: completeId)

            // THEN
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            XCTAssertEqual(selfUser.imageSmallProfileData, previewData)
            XCTAssertEqual(selfUser.imageMediumData, completeData)
            XCTAssertEqual(selfUser.previewProfileAssetIdentifier, previewId)
            XCTAssertEqual(selfUser.completeProfileAssetIdentifier, completeId)
            XCTAssertEqual(self.sut.imageState(for: .preview), .ready)
            XCTAssertEqual(self.sut.imageState(for: .complete), .ready)
            XCTAssertEqual(self.sut.state, .ready)
        }
    }
}
