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
import XCTest
import Photos
import Cartography
import AVFoundation
@testable import Wire


class CameraKeyboardViewControllerDelegateMock: CameraKeyboardViewControllerDelegate {
    
    var cameraKeyboardWantsToOpenCameraRollHitCount: UInt = 0
    @objc func cameraKeyboardViewControllerWantsToOpenCameraRoll(_ controller: CameraKeyboardViewController) {
        cameraKeyboardWantsToOpenCameraRollHitCount = cameraKeyboardWantsToOpenCameraRollHitCount + 1
    }
    
    var cameraKeyboardWantsToOpenFullScreenCameraHitCount: UInt = 0
    @objc func cameraKeyboardViewControllerWantsToOpenFullScreenCamera(_ controller: CameraKeyboardViewController) {
        cameraKeyboardWantsToOpenFullScreenCameraHitCount = cameraKeyboardWantsToOpenFullScreenCameraHitCount + 1
    }
    
    var cameraKeyboardDidSelectVideoHitCount: UInt = 0
    @objc func cameraKeyboardViewController(_ controller: CameraKeyboardViewController, didSelectVideo: URL, duration: TimeInterval) {
        cameraKeyboardDidSelectVideoHitCount = cameraKeyboardDidSelectVideoHitCount + 1
    }
    
    var cameraKeyboardViewControllerDidSelectImageDataHitCount: UInt = 0
    @objc func cameraKeyboardViewController(_ controller: CameraKeyboardViewController, didSelectImageData: Data, isFromCamera: Bool) {
        cameraKeyboardViewControllerDidSelectImageDataHitCount = cameraKeyboardViewControllerDidSelectImageDataHitCount + 1
    }
}


@objcMembers class SplitLayoutObservableMock: NSObject, SplitLayoutObservable {
    @objc var layoutSize: SplitViewControllerLayoutSize = .compact
    @objc var leftViewControllerWidth: CGFloat = 0
}

private final class MockAssetLibrary: AssetLibrary {
    fileprivate override var count: UInt { return 5 }
    
    fileprivate override func refetchAssets(synchronous: Bool) {
        // no op
    }
}

fileprivate final class CallingMockCameraKeyboardViewController: CameraKeyboardViewController {
    @objc override var shouldBlockCallingRelatedActions: Bool {
        return true
    }
}

final class CameraKeyboardViewControllerTests: CoreDataSnapshotTestCase {
    var sut: CameraKeyboardViewController!
    var splitView: SplitLayoutObservableMock!
    var delegateMock: CameraKeyboardViewControllerDelegateMock!
    var assetLibrary: AssetLibrary!
    
    override func setUp() {
        super.setUp()
        self.assetLibrary = MockAssetLibrary()
        self.splitView = SplitLayoutObservableMock()
        self.delegateMock = CameraKeyboardViewControllerDelegateMock()
    }

    override func tearDown() {
        sut = nil
        splitView = nil
        delegateMock = nil
        assetLibrary = nil
        super.tearDown()
    }
    
    @discardableResult func prepareForSnapshot(_ size: CGSize = CGSize(width: 320, height: 216)) -> UIView {
        self.sut.beginAppearanceTransition(true, animated: false)
        self.sut.endAppearanceTransition()
        
        let container = UIView()
        container.addSubview(self.sut.view)
        container.backgroundColor = UIColor.from(scheme: .textForeground, variant: .light)
        
        constrain(self.sut.view, container) { view, container in
            container.height == size.height
            container.width == size.width
            view.top == container.top
            view.bottom == container.bottom
            view.left == container.left
            view.right == container.right
        }
        container.setNeedsLayout()
        container.layoutIfNeeded()
        return container
    }
    
    func testWithCallingOverlay() {
        let permissions = MockPhotoPermissionsController(camera: true, library: true)
        self.sut = CallingMockCameraKeyboardViewController(splitLayoutObservable: self.splitView, assetLibrary: assetLibrary, permissions: permissions)
        self.verify(view: self.prepareForSnapshot())
    }
    
    func testThatFirstSectionContainsCameraCellOnly() {
        // given
        let permissions = MockPhotoPermissionsController(camera: true, library: true)
        self.sut = CameraKeyboardViewController(splitLayoutObservable: self.splitView, assetLibrary: assetLibrary, permissions: permissions)
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
        self.sut = CameraKeyboardViewController(splitLayoutObservable: self.splitView, assetLibrary: assetLibrary, permissions: permissions)
        self.sut.delegate = self.delegateMock
        self.prepareForSnapshot()
        
        // when
        let cameraCell = self.sut.collectionView.cellForItem(at: IndexPath(item: 0, section: 0))
        
        // then
        XCTAssertTrue(cameraCell is CameraKeyboardPermissionsCell)
        XCTAssertEqual(self.sut.collectionView.numberOfSections, 1)
        XCTAssertEqual(self.sut.collectionView.numberOfItems(inSection: 0), 1)
    }

    func testThatSecondSectionContainsCameraRollElements() {
        // given
        let permissions = MockPhotoPermissionsController(camera: true, library: true)
        self.sut = CameraKeyboardViewController(splitLayoutObservable: self.splitView, assetLibrary: assetLibrary, permissions: permissions)
        self.sut.delegate = self.delegateMock
        self.prepareForSnapshot()
        
        // when
        let itemCell = self.sut.collectionView.cellForItem(at: IndexPath(item: 0, section: 1))
        
        // then
        XCTAssertTrue(itemCell is AssetCell)
        XCTAssertEqual(self.sut.collectionView.numberOfSections, 2)
    }
    
    func initialStateLayoutSizeCompact(with permissions: PhotoPermissionsController) {
        // given
        self.splitView?.layoutSize = .compact
        // when
        self.sut = CameraKeyboardViewController(splitLayoutObservable: self.splitView, assetLibrary: assetLibrary, permissions: permissions)
        // then
        self.verify(view: self.prepareForSnapshot())
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
    
    func initialStateLayoutSizeRegularPortrait(with permissions: PhotoPermissionsController) {
        // given
        self.splitView?.layoutSize = .regularPortrait
        self.splitView?.leftViewControllerWidth = 216
        // when
        self.sut = CameraKeyboardViewController(splitLayoutObservable: self.splitView, assetLibrary: assetLibrary, permissions: permissions)
        // then
        self.verify(view: self.prepareForSnapshot(CGSize(width: 768, height: 264)))
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
    
    func initialStateLayoutSizeRegularLandscape(with permissions: PhotoPermissionsController) {
        // given
        self.splitView?.layoutSize = .regularLandscape
        self.splitView?.leftViewControllerWidth = 216
        // when
        self.sut = CameraKeyboardViewController(splitLayoutObservable: self.splitView, assetLibrary: assetLibrary, permissions: permissions)
        // then
        self.verify(view: self.prepareForSnapshot(CGSize(width: 1024, height: 352)))
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
    
    func cameraScrolledHorizontallySomePercent(with permissions: PhotoPermissionsController) {
        // given
        self.splitView?.layoutSize = .compact
        self.sut = CameraKeyboardViewController(splitLayoutObservable: self.splitView, assetLibrary: assetLibrary, permissions: permissions)
        self.prepareForSnapshot()
        // when
        self.sut.collectionView.scrollRectToVisible(CGRect(x: 300, y: 0, width: 160, height: 10), animated: false)
        // then
        self.verify(view: self.prepareForSnapshot())
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
    func cameraScrolledHorizontallyAwayPercent(with permissions: PhotoPermissionsController) {
        // given
        self.splitView?.layoutSize = .compact
        self.sut = CameraKeyboardViewController(splitLayoutObservable: self.splitView, assetLibrary: assetLibrary, permissions: permissions)
        self.prepareForSnapshot()
        // when
        self.sut.collectionView.scrollRectToVisible(CGRect(x: 320, y: 0, width: 160, height: 10), animated: false)
        // then
        self.verify(view: self.prepareForSnapshot())
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
        self.sut = CameraKeyboardViewController(splitLayoutObservable: self.splitView, assetLibrary: assetLibrary, permissions: permissions)
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
        self.sut = CameraKeyboardViewController(splitLayoutObservable: self.splitView, assetLibrary: assetLibrary, permissions: permissions)
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

