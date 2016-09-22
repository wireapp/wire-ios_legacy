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
    @objc func cameraKeyboardViewController(_ controller: CameraKeyboardViewController, didSelectImageData: Data, metadata: ImageMetadata) {
        cameraKeyboardViewControllerDidSelectImageDataHitCount = cameraKeyboardViewControllerDidSelectImageDataHitCount + 1
    }
}


@objc class SplitLayoutObservableMock: NSObject, SplitLayoutObservable {
    @objc var layoutSize: SplitViewControllerLayoutSize = .compact
    @objc var leftViewControllerWidth: CGFloat = 0
}

private final class MockAssetLibrary: AssetLibrary {
    fileprivate override var count: UInt { return 5 }
    
    fileprivate override func refetchAssets(synchronous: Bool) {
        // no op
    }
}

final class CameraKeyboardViewControllerTests: ZMSnapshotTestCase {
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
    
    func prepareForSnapshot(_ size: CGSize = CGSize(width: 320, height: 216)) -> UIView {
        self.sut.beginAppearanceTransition(true, animated: false)
        self.sut.endAppearanceTransition()
        
        let container = UIView()
        container.addSubview(self.sut.view)
        container.backgroundColor = ColorScheme.default().color(withName: ColorSchemeColorTextForeground, variant: .light)
        
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
    
    func testThatFirstSectionContainsCameraCellOnly() {
        // given
        self.sut = CameraKeyboardViewController(splitLayoutObservable: self.splitView, assetLibrary: assetLibrary)
        self.sut.delegate = self.delegateMock
        self.prepareForSnapshot()
        
        // when
        let cameraCell = self.sut.collectionView.cellForItem(at: IndexPath(item: 0, section: 0))
        
        // then
        XCTAssertTrue(cameraCell is CameraCell)
        XCTAssertEqual(self.sut.collectionView.numberOfSections, 2)
        XCTAssertEqual(self.sut.collectionView.numberOfItems(inSection: 0), 1)
    }

    func testThatSecondSectionContainsCameraRollElements() {
        // given
        self.sut = CameraKeyboardViewController(splitLayoutObservable: self.splitView, assetLibrary: assetLibrary)
        self.sut.delegate = self.delegateMock
        self.prepareForSnapshot()
        
        // when
        let itemCell = self.sut.collectionView.cellForItem(at: IndexPath(item: 0, section: 1))
        
        // then
        XCTAssertTrue(itemCell is AssetCell)
        XCTAssertEqual(self.sut.collectionView.numberOfSections, 2)
    }

    func testInitialStateLayoutSizeCompact() {
        // given
        self.splitView?.layoutSize = .compact
        // when
        self.sut = CameraKeyboardViewController(splitLayoutObservable: self.splitView, assetLibrary: assetLibrary)
        // then
        self.verify(view: self.prepareForSnapshot())
    }
    
    func testInitialStateLayoutSizeRegularPortrait() {
        // given
        self.splitView?.layoutSize = .regularPortrait
        self.splitView?.leftViewControllerWidth = 216
        // when
        self.sut = CameraKeyboardViewController(splitLayoutObservable: self.splitView, assetLibrary: assetLibrary)
        // then
        self.verify(view: self.prepareForSnapshot(CGSize(width: 768, height: 264)))
    }
    
    func testInitialStateLayoutSizeRegularLandscape() {
        // given
        self.splitView?.layoutSize = .regularLandscape
        self.splitView?.leftViewControllerWidth = 216
        // when
        self.sut = CameraKeyboardViewController(splitLayoutObservable: self.splitView, assetLibrary: assetLibrary)
        // then
        self.verify(view: self.prepareForSnapshot(CGSize(width: 1024, height: 352)))
    }
    
    func testCameraScrolledHorisontallySomePercent() {
        // given
        self.splitView?.layoutSize = .compact
        self.sut = CameraKeyboardViewController(splitLayoutObservable: self.splitView, assetLibrary: assetLibrary)
        self.prepareForSnapshot()
        // when
        self.sut.collectionView.scrollRectToVisible(CGRect(x: 300, y: 0, width: 160, height: 10), animated: false)
        // then
        self.verify(view: self.prepareForSnapshot())
    }
    
    func testCameraScrolledHorisontallyAwayPercent() {
        // given
        self.splitView?.layoutSize = .compact
        self.sut = CameraKeyboardViewController(splitLayoutObservable: self.splitView, assetLibrary: assetLibrary)
        self.prepareForSnapshot()
        // when
        self.sut.collectionView.scrollRectToVisible(CGRect(x: 320, y: 0, width: 160, height: 10), animated: false)
        // then
        self.verify(view: self.prepareForSnapshot())
    }
    
    func testThatItCallsDelegateCameraRollWhenCameraRollButtonPressed() {
        // given
        self.sut = CameraKeyboardViewController(splitLayoutObservable: self.splitView, assetLibrary: assetLibrary)
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
        self.sut = CameraKeyboardViewController(splitLayoutObservable: self.splitView, assetLibrary: assetLibrary)
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

