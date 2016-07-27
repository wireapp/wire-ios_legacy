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
    @objc func cameraKeyboardViewControllerWantsToOpenCameraRoll(controller: CameraKeyboardViewController) {
        cameraKeyboardWantsToOpenCameraRollHitCount = cameraKeyboardWantsToOpenCameraRollHitCount + 1
    }
    
    var cameraKeyboardWantsToOpenFullScreenCameraHitCount: UInt = 0
    @objc func cameraKeyboardViewControllerWantsToOpenFullScreenCamera(controller: CameraKeyboardViewController) {
        cameraKeyboardWantsToOpenFullScreenCameraHitCount = cameraKeyboardWantsToOpenFullScreenCameraHitCount + 1
    }
    
    var cameraKeyboardDidSelectVideoHitCount: UInt = 0
    @objc func cameraKeyboardViewController(controller: CameraKeyboardViewController, didSelectVideo: AVURLAsset) {
        cameraKeyboardDidSelectVideoHitCount = cameraKeyboardDidSelectVideoHitCount + 1
    }
    
    var cameraKeyboardViewControllerDidSelectImageDataHitCount: UInt = 0
    @objc func cameraKeyboardViewController(controller: CameraKeyboardViewController, didSelectImageData: NSData, source: UIImagePickerControllerSourceType) {
        cameraKeyboardViewControllerDidSelectImageDataHitCount = cameraKeyboardViewControllerDidSelectImageDataHitCount + 1
    }
}


@objc class SplitLayoutObservableMock: NSObject, SplitLayoutObservable {
    @objc var layoutSize: SplitViewControllerLayoutSize = .Compact
    @objc var leftViewControllerWidth: CGFloat = 0
}

final class CameraKeyboardViewControllerTests: ZMSnapshotTestCase {
    var sut: CameraKeyboardViewController!
    var splitView: SplitLayoutObservableMock!
    var delegateMock: CameraKeyboardViewControllerDelegateMock!
    let assetLibrary = AssetLibrary(synchronous: true)
    
    override func setUp() {
        super.setUp()
        self.splitView = SplitLayoutObservableMock()
        self.delegateMock = CameraKeyboardViewControllerDelegateMock()
    }
    
    func prepareForSnapshot(size: CGSize = CGSizeMake(320, 216)) -> UIView {
        self.sut.beginAppearanceTransition(true, animated: false)
        self.sut.endAppearanceTransition()
        
        let container = UIView()
        container.addSubview(self.sut.view)
        container.backgroundColor = ColorScheme.defaultColorScheme().colorWithName(ColorSchemeColorTextForeground, variant: .Light)
        
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
        let cameraCell = self.sut.collectionView.cellForItemAtIndexPath(NSIndexPath(forItem: 0, inSection: 0))
        
        // then
        XCTAssertTrue(cameraCell is CameraCell)
        XCTAssertEqual(self.sut.collectionView.numberOfSections(), 2)
        XCTAssertEqual(self.sut.collectionView.numberOfItemsInSection(0), 1)
    }
    
    func testThatSecondSectionContainsCameraRollElements() {
        // given
        self.sut = CameraKeyboardViewController(splitLayoutObservable: self.splitView, assetLibrary: assetLibrary)
        self.sut.delegate = self.delegateMock
        self.prepareForSnapshot()
        
        // when
        let itemCell = self.sut.collectionView.cellForItemAtIndexPath(NSIndexPath(forItem: 0, inSection: 1))
        
        // then
        XCTAssertTrue(itemCell is AssetCell)
        XCTAssertEqual(self.sut.collectionView.numberOfSections(), 2)
    }
    
    func testInitialStateLayoutSizeCompact() {
        // given
        self.splitView?.layoutSize = .Compact
        // when
        self.sut = CameraKeyboardViewController(splitLayoutObservable: self.splitView, assetLibrary: assetLibrary)
        // then
        self.verify(view: self.prepareForSnapshot())
    }
    
    func testInitialStateLayoutSizeRegularPortrait() {
        // given
        self.splitView?.layoutSize = .RegularPortrait
        // when
        self.sut = CameraKeyboardViewController(splitLayoutObservable: self.splitView, assetLibrary: assetLibrary)
        // then
        self.verify(view: self.prepareForSnapshot(CGSizeMake(768, 264)))
    }
    
    func testInitialStateLayoutSizeRegularLandscape() {
        // given
        self.splitView?.layoutSize = .RegularLandscape
        // when
        self.sut = CameraKeyboardViewController(splitLayoutObservable: self.splitView, assetLibrary: assetLibrary)
        // then
        self.verify(view: self.prepareForSnapshot(CGSizeMake(1024, 352)))
    }
    
    func testCameraScrolledHorisontallyHalfPercent() {
        // given
        self.splitView?.layoutSize = .Compact
        self.sut = CameraKeyboardViewController(splitLayoutObservable: self.splitView, assetLibrary: assetLibrary)
        self.prepareForSnapshot()
        // when
        self.sut.collectionView.scrollRectToVisible(CGRectMake(160, 0, 160, 10), animated: false)
        // then
        self.verify(view: self.prepareForSnapshot())
    }
    
    func testCameraScrolledHorisontallyAwayPercent() {
        // given
        self.splitView?.layoutSize = .Compact
        self.sut = CameraKeyboardViewController(splitLayoutObservable: self.splitView, assetLibrary: assetLibrary)
        self.prepareForSnapshot()
        // when
        self.sut.collectionView.scrollRectToVisible(CGRectMake(320, 0, 160, 10), animated: false)
        // then
        self.verify(view: self.prepareForSnapshot())
    }
    
    func testThatItCallsDelegateCameraRollWhenCameraRollButtonPressed() {
        // given
        self.sut = CameraKeyboardViewController(splitLayoutObservable: self.splitView, assetLibrary: assetLibrary)
        self.sut.delegate = self.delegateMock
        self.prepareForSnapshot()
        
        // when
        self.sut.cameraRollButton.sendActionsForControlEvents(.TouchUpInside)
        
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
        let cameraCell = self.sut.collectionView.cellForItemAtIndexPath(NSIndexPath(forItem: 0, inSection: 0)) as! CameraCell
        cameraCell.expandButton.sendActionsForControlEvents(.TouchUpInside)
        
        // then
        XCTAssertEqual(self.delegateMock.cameraKeyboardWantsToOpenCameraRollHitCount, 0)
        XCTAssertEqual(self.delegateMock.cameraKeyboardWantsToOpenFullScreenCameraHitCount, 1)
        XCTAssertEqual(self.delegateMock.cameraKeyboardDidSelectVideoHitCount, 0)
        XCTAssertEqual(self.delegateMock.cameraKeyboardViewControllerDidSelectImageDataHitCount, 0)
    }
}

