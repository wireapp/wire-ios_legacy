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

import XCTest
import AVFoundation
import Photos
@testable import Wire

final class CameraKeyboardViewControllerDelegateMock: CameraKeyboardViewControllerDelegate {

    var cameraKeyboardWantsToOpenCameraRollHitCount: UInt = 0
    @objc func cameraKeyboardViewControllerWantsToOpenCameraRoll(_ controller: CameraKeyboardViewController) {
        cameraKeyboardWantsToOpenCameraRollHitCount += 1
    }

    var cameraKeyboardWantsToOpenFullScreenCameraHitCount: UInt = 0
    @objc func cameraKeyboardViewControllerWantsToOpenFullScreenCamera(_ controller: CameraKeyboardViewController) {
        cameraKeyboardWantsToOpenFullScreenCameraHitCount += 1
    }

    var cameraKeyboardDidSelectVideoHitCount: UInt = 0
    @objc func cameraKeyboardViewController(_ controller: CameraKeyboardViewController, didSelectVideo: URL, duration: TimeInterval) {
        cameraKeyboardDidSelectVideoHitCount += 1
    }

    var cameraKeyboardViewControllerDidSelectImageDataHitCount: UInt = 0
    func cameraKeyboardViewController(_ controller: CameraKeyboardViewController, didSelectImageData: Data, isFromCamera: Bool, uti: String?) {
        cameraKeyboardViewControllerDidSelectImageDataHitCount += 1
    }
}

final class SplitLayoutObservableMock: NSObject, SplitLayoutObservable {
    var layoutSize: SplitViewControllerLayoutSize = .compact
    var leftViewControllerWidth: CGFloat = 0
}

private final class MockAssetLibrary: AssetLibrary {
    fileprivate override var count: UInt { return 5 }

    fileprivate override func refetchAssets(synchronous: Bool) {
        // no op
    }
}

private final class MockImageManager: ImageManagerProtocol {

    func cancelImageRequest(_ requestID: PHImageRequestID) {
        // no op
    }

    func requestImage(for asset: PHAsset, targetSize: CGSize, contentMode: PHImageContentMode, options: PHImageRequestOptions?, resultHandler: @escaping (UIImage?, [AnyHashable: Any]?) -> Void) -> PHImageRequestID {
        return 0
    }

    func requestImageData(for asset: PHAsset, options: PHImageRequestOptions?, resultHandler: @escaping (Data?, String?, UIImage.Orientation, [AnyHashable: Any]?) -> Void) -> PHImageRequestID {
        return 0
    }

    func requestExportSession(forVideo asset: PHAsset, options: PHVideoRequestOptions?, exportPreset: String, resultHandler: @escaping (AVAssetExportSession?, [AnyHashable: Any]?) -> Void) -> PHImageRequestID {
        return 0
    }

    static var defaultInstance: ImageManagerProtocol = MockImageManager()
}

private final class CallingMockCameraKeyboardViewController: CameraKeyboardViewController {
    override var shouldBlockCallingRelatedActions: Bool {
        return true
    }
}

final class CameraKeyboardViewControllerTests: XCTestCase {
    var sut: CameraKeyboardViewController!
    var splitView: SplitLayoutObservableMock!
    var delegateMock: CameraKeyboardViewControllerDelegateMock!
    fileprivate var mockAssetLibrary: MockAssetLibrary!
    fileprivate var mockImageManager: MockImageManager!

    override func setUp() {
        super.setUp()

        mockAssetLibrary = MockAssetLibrary(photoLibrary: MockPhotoLibrary())
        mockImageManager = MockImageManager()
        splitView = SplitLayoutObservableMock()
        delegateMock = CameraKeyboardViewControllerDelegateMock()
    }

    override func tearDown() {
        sut = nil

        splitView = nil
        delegateMock = nil
        mockAssetLibrary = nil
        mockImageManager = nil

        super.tearDown()
    }

    @discardableResult
    private func prepareForSnapshot(_ size: CGSize = CGSize(width: 320, height: 216)) -> UIView {
        self.sut.beginAppearanceTransition(true, animated: false)
        self.sut.endAppearanceTransition()

        let container = UIView()
        container.addSubview(self.sut.view)
        container.backgroundColor = UIColor.from(scheme: .textForeground, variant: .light)
        container.translatesAutoresizingMaskIntoConstraints = false
        sut.view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: size.height),
            container.widthAnchor.constraint(equalToConstant: size.width),
            sut.view.topAnchor.constraint(equalTo: container.topAnchor),
            sut.view.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            sut.view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            sut.view.trailingAnchor.constraint(equalTo: container.trailingAnchor)
        ])

        container.layoutIfNeeded()
        return container
    }

    private func setupSut(permissions: PhotoPermissionsController) {
        sut = CameraKeyboardViewController(splitLayoutObservable: splitView,
                                           permissions: permissions)
    }

    func testWithCallingOverlay() {
        let permissions = MockPhotoPermissionsController(camera: true, library: true)
        sut = CallingMockCameraKeyboardViewController(splitLayoutObservable: splitView,
                                                      permissions: permissions)

        verify(matching: prepareForSnapshot())
    }

    func testThatFirstSectionContainsCameraCellOnly() {
        // given
        let permissions = MockPhotoPermissionsController(camera: true, library: true)
        setupSut(permissions: permissions)

        self.sut.delegate = self.delegateMock
        self.prepareForSnapshot()

        // when
        let cameraCell = self.sut.collectionView.cellForItem(at: IndexPath(item: 0, section: 0))

        // then
        XCTAssertTrue(cameraCell is CameraCell)
        XCTAssertEqual(self.sut.collectionView.numberOfSections, 2)
        XCTAssertEqual(self.sut.collectionView.numberOfItems(inSection: 0), 1)
    }

    func testThatTableViewContainsPermissionsCellOnly_CameraAndLibraryAccessNotGranted() {
        let permissions = MockPhotoPermissionsController(camera: false, library: false)
        setupSut(permissions: permissions)
        self.sut.delegate = self.delegateMock
        self.prepareForSnapshot()

        // when
        let cameraCell = self.sut.collectionView.cellForItem(at: IndexPath(item: 0, section: 0))

        // then
        XCTAssertTrue(cameraCell is CameraKeyboardPermissionsCell)
        XCTAssertEqual(self.sut.collectionView.numberOfSections, 1)
        XCTAssertEqual(self.sut.collectionView.numberOfItems(inSection: 0), 1)
    }

    private func initialStateLayoutSizeCompact(with permissions: PhotoPermissionsController,
                                               file: StaticString = #file,
                                               testName: String = #function,
                                               line: UInt = #line) {
        // given
        splitView?.layoutSize = .compact
        // when
        setupSut(permissions: permissions)
        // then
        verify(matching: prepareForSnapshot(),
               file: file,
               testName: testName,
               line: line)
    }

    func testInitialStateLayoutSizeCompact() {
        let permissions = MockPhotoPermissionsController(camera: true, library: true)
        initialStateLayoutSizeCompact(with: permissions)
    }

    func testInitialStateLayoutSizeCompact_CameraAndLibraryAccessNotGranted() {
        let permissions = MockPhotoPermissionsController(camera: false, library: false)
        initialStateLayoutSizeCompact(with: permissions)
    }

    func testInitialStateLayoutSizeCompact_CameraAccessGranted() {
        let permissions = MockPhotoPermissionsController(camera: true, library: false)
        initialStateLayoutSizeCompact(with: permissions)
    }

    func testInitialStateLayoutSizeCompact_LibraryAccessGranted() {
        let permissions = MockPhotoPermissionsController(camera: false, library: true)
        initialStateLayoutSizeCompact(with: permissions)
    }

    private func initialStateLayoutSizeRegularPortrait(with permissions: PhotoPermissionsController,
                                                       file: StaticString = #file,
                                                       testName: String = #function,
                                                       line: UInt = #line) {
        // given
        splitView?.layoutSize = .regularPortrait
        splitView?.leftViewControllerWidth = 216
        // when
        setupSut(permissions: permissions)
        // then
        verify(matching: prepareForSnapshot(CGSize(width: 768, height: 264)),
               file: file,
               testName: testName,
               line: line)
    }

    func testInitialStateLayoutSizeRegularPortrait() {
        let permissions = MockPhotoPermissionsController(camera: true, library: true)
        initialStateLayoutSizeRegularPortrait(with: permissions)
    }

    func testInitialStateLayoutSizeRegularPortrait_CameraAndLibraryAccessNotGranted() {
        let permissions = MockPhotoPermissionsController(camera: false, library: false)
        initialStateLayoutSizeRegularPortrait(with: permissions)
    }

    func testInitialStateLayoutSizeRegularPortrait_CameraAccessGranted() {
        let permissions = MockPhotoPermissionsController(camera: true, library: false)
        initialStateLayoutSizeRegularPortrait(with: permissions)
    }

    func testInitialStateLayoutSizeRegularPortrait_LibraryAccessGranted() {
        let permissions = MockPhotoPermissionsController(camera: false, library: true)
        initialStateLayoutSizeRegularPortrait(with: permissions)
    }

    func initialStateLayoutSizeRegularLandscape(with permissions: PhotoPermissionsController,
                                                file: StaticString = #file,
                                                testName: String = #function,
                                                line: UInt = #line) {
        // given
        splitView?.layoutSize = .regularLandscape
        splitView?.leftViewControllerWidth = 216
        // when
        setupSut(permissions: permissions)
        // then
        verify(matching: prepareForSnapshot(CGSize(width: 1024, height: 352)), file: file, testName: testName, line: line)
    }

    func testInitialStateLayoutSizeRegularLandscape() {
        let permissions = MockPhotoPermissionsController(camera: true, library: true)
        initialStateLayoutSizeRegularLandscape(with: permissions)
    }

    func testInitialStateLayoutSizeRegularLandscape_CameraAndLibraryAccessNotGranted() {
        let permissions = MockPhotoPermissionsController(camera: false, library: false)
        initialStateLayoutSizeRegularLandscape(with: permissions)
    }

    func testInitialStateLayoutSizeRegularLandscape_CameraAccessGranted() {
        let permissions = MockPhotoPermissionsController(camera: true, library: false)
        initialStateLayoutSizeRegularLandscape(with: permissions)
    }

    func testInitialStateLayoutSizeRegularLandscape_LibraryAccessGranted() {
        let permissions = MockPhotoPermissionsController(camera: false, library: true)
        initialStateLayoutSizeRegularLandscape(with: permissions)
    }

    private func cameraScrolledHorizontallySomePercent(with permissions: PhotoPermissionsController,
                                                       file: StaticString = #file,
                                                       testName: String = #function,
                                                       line: UInt = #line) {
        // given
        self.splitView?.layoutSize = .compact
        setupSut(permissions: permissions)
        self.prepareForSnapshot()
        // when
        self.sut.collectionView.scrollRectToVisible(CGRect(x: 300, y: 0, width: 160, height: 10), animated: false)
        // then
        verify(matching: prepareForSnapshot(),
               file: file,
               testName: testName,
               line: line)
    }

    func testCameraScrolledHorizontallySomePercent() {
        let permissions = MockPhotoPermissionsController(camera: true, library: true)
        cameraScrolledHorizontallySomePercent(with: permissions)
    }

    func testCameraScrolledHorizontallySomePercent_CameraAndLibraryAccessNotGranted() {
        let permissions = MockPhotoPermissionsController(camera: false, library: false)
        cameraScrolledHorizontallySomePercent(with: permissions)
    }

    func testCameraScrolledHorizontallySomePercent_CameraAccessGranted() {
        let permissions = MockPhotoPermissionsController(camera: true, library: false)
        cameraScrolledHorizontallySomePercent(with: permissions)
    }

    func testCameraScrolledHorizontallySomePercent_LibraryAccessGranted() {
        let permissions = MockPhotoPermissionsController(camera: false, library: true)
        cameraScrolledHorizontallySomePercent(with: permissions)
    }

    private func cameraScrolledHorizontallyAwayPercent(with permissions: PhotoPermissionsController,
                                                       file: StaticString = #file,
                                                       testName: String = #function,
                                                       line: UInt = #line) {
        // given
        splitView?.layoutSize = .compact
        setupSut(permissions: permissions)
        prepareForSnapshot()
        // when
        sut.collectionView.scrollRectToVisible(CGRect(x: 320, y: 0, width: 160, height: 10), animated: false)
        // then
        verify(matching: prepareForSnapshot(),
               file: file,
               testName: testName,
               line: line)
    }

    func testCameraScrolledHorizontallyAwayPercent() {
        let permissions = MockPhotoPermissionsController(camera: true, library: true)
        cameraScrolledHorizontallyAwayPercent(with: permissions)
    }

    func testCameraScrolledHorizontallyAwayPercent_CameraAndLibraryAccessNotGranted() {
        let permissions = MockPhotoPermissionsController(camera: false, library: false)
        cameraScrolledHorizontallyAwayPercent(with: permissions)
    }

    func testCameraScrolledHorizontallyAwayPercent_CameraAccessGranted() {
        let permissions = MockPhotoPermissionsController(camera: true, library: false)
        cameraScrolledHorizontallyAwayPercent(with: permissions)
    }

    func testCameraScrolledHorizontallyAwayPercent_LibraryAccessGranted() {
        let permissions = MockPhotoPermissionsController(camera: false, library: true)
        cameraScrolledHorizontallyAwayPercent(with: permissions)
    }

    func testThatItCallsDelegateCameraRollWhenCameraRollButtonPressed() {
        // given
        let permissions = MockPhotoPermissionsController(camera: true, library: true)
        setupSut(permissions: permissions)
        self.sut.delegate = self.delegateMock
        self.prepareForSnapshot()

        // when
        self.sut.cameraRollButton.sendActions(for: .touchUpInside)

        // then
        XCTAssertEqual(self.delegateMock.cameraKeyboardWantsToOpenCameraRollHitCount, 1)
        XCTAssertEqual(self.delegateMock.cameraKeyboardWantsToOpenFullScreenCameraHitCount, 0)
        XCTAssertEqual(self.delegateMock.cameraKeyboardDidSelectVideoHitCount, 0)
        XCTAssertEqual(self.delegateMock.cameraKeyboardViewControllerDidSelectImageDataHitCount, 0)
    }

    func testThatItCallsDelegateWhenWantsToOpenFullScreenCamera() {
        // given
        let permissions = MockPhotoPermissionsController(camera: true, library: true)
        setupSut(permissions: permissions)
        self.sut.delegate = self.delegateMock
        self.prepareForSnapshot()

        // when
        let cameraCell = self.sut.collectionView.cellForItem(at: IndexPath(item: 0, section: 0)) as! CameraCell
        cameraCell.expandButton.sendActions(for: .touchUpInside)

        // then
        XCTAssertEqual(self.delegateMock.cameraKeyboardWantsToOpenCameraRollHitCount, 0)
        XCTAssertEqual(self.delegateMock.cameraKeyboardWantsToOpenFullScreenCameraHitCount, 1)
        XCTAssertEqual(self.delegateMock.cameraKeyboardDidSelectVideoHitCount, 0)
        XCTAssertEqual(self.delegateMock.cameraKeyboardViewControllerDidSelectImageDataHitCount, 0)
    }
}
