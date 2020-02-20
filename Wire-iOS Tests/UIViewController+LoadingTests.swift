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
@testable import Wire
import SnapshotTesting

final class MockLoadingSpinnerViewController: UIViewController, LoadingSpinner {
    lazy var loadingSpinnerView: UIView = {
       let view = UIView()
        view.isHidden = true
        view.backgroundColor = UIColor(white: 0.0, alpha: 0.5)
        view.addSubview(spinnerSubtitleView)
        
        self.view.addSubview(view)

        createConstraints(container: view)

        return view
    }()
    
    lazy var spinnerSubtitleView: SpinnerSubtitleView = SpinnerSubtitleView()
    
    var showSpinner: Bool {
        get {
            return !loadingSpinnerView.isHidden
        }
        
        set(shouldShow) {
            loadingSpinnerView.isHidden = !shouldShow
            spinnerSubtitleView.isHidden = !shouldShow
            view.isUserInteractionEnabled = !shouldShow

            if shouldShow {
                UIAccessibility.post(notification: .announcement, argument: "general.loading".localized)
                spinnerSubtitleView.spinner.startAnimation()
            } else {
                spinnerSubtitleView.spinner.stopAnimation()
            }
        }
    }
    
    func createConstraints(container: UIView) {
        container.translatesAutoresizingMaskIntoConstraints = false
        spinnerSubtitleView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // loadingView
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            container.topAnchor.constraint(equalTo: view.topAnchor),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            container.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // spinnerView
            spinnerSubtitleView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinnerSubtitleView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            ])
    }
}


final class LoadingViewControllerTests: XCTestCase {
    var sut: (UIViewController & LoadingSpinner)!
    
    override func setUp() {
        super.setUp()
        sut = MockLoadingSpinnerViewController()
        sut.view.backgroundColor = .white
        sut.view.layer.speed = 0
        sut.view.frame = CGRect(x: 0, y: 0, width: 375, height: 667)
        sut.beginAppearanceTransition(true, animated: false)
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testThatItShowsLoadingIndicator() {
        // Given
        
        // when
        sut.showSpinner = true
        
        // then
        verifyInAllDeviceSizes(matching: sut)
    }
    
    func testThatItShowsLoadingIndicatorWithSubtitle() {
        // Given
        
        // when
        sut.spinnerSubtitleView.subtitle = "RESTORING…"
        sut.showSpinner = true
        
        // then
        verifyInAllDeviceSizes(matching: sut)
    }
    
}
