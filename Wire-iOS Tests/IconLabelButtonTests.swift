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

class IconLabelButtonTests: ZMSnapshotTestCase {
    
    fileprivate var button: IconLabelButton!
    
    override func setUp() {
        super.setUp()
        snapshotBackgroundColor = .darkGray
        button = IconLabelButton.video()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setNeedsLayout()
        button.layoutIfNeeded()
    }
    
    override func tearDown() {
        button = nil
        super.tearDown()
    }

    func testIconLabelButton_Dark_Unselected_Enabled() {
        // When
        button.appearance = .dark(blurred: false)
        
        // Then
        verify(view: button)
    }
    
    func testIconLabelButton_Dark_Unselected_Disabled() {
        // When
        button.isEnabled = false
        button.appearance = .dark(blurred: false)
        
        // Then
        verify(view: button)
    }
    
    func testIconLabelButton_Dark_Selected_Enabled() {
        // When
        button.isSelected = true
        button.appearance = .dark(blurred: false)
        
        // Then
        verify(view: button)
    }
    
    func testIconLabelButton_Dark_Selected_Disabled() {
        // When
        button.isSelected = true
        button.isEnabled = false
        button.appearance = .dark(blurred: false)
        
        // Then
        verify(view: button)
    }
    
    func testIconLabelButton_Dark_Unselected_Enabled_Blurred() {
        // When
        button.appearance = .dark(blurred: true)
        
        // Then
        verify(view: button)
    }
    
    func testIconLabelButton_Dark_Unselected_Disabled_Blurred() {
        // When
        button.isEnabled = false
        button.appearance = .dark(blurred: true)
        
        // Then
        verify(view: button)
    }
    
    func testIconLabelButton_Dark_Selected_Enabled_Blurred() {
        // When
        button.isSelected = true
        button.appearance = .dark(blurred: true)
        
        // Then
        verify(view: button)
    }
    
    func testIconLabelButton_Dark_Selected_Disabled_Blurred() {
        // When
        button.isSelected = true
        button.isEnabled = false
        button.appearance = .dark(blurred: true)
        
        // Then
        verify(view: button)
    }
    
    func testIconLabelButton_Light_Unselected_Enabled() {
        // Given
        snapshotBackgroundColor = .white

        // When
        button.appearance = .light
        
        // Then
        verify(view: button)
    }
    
    func testIconLabelButton_Light_Unselected_Disabled() {
        // Given
        snapshotBackgroundColor = .white
        
        // When
        button.isEnabled = false
        button.appearance = .light
        
        // Then
        verify(view: button)
    }
    
    func testIconLabelButton_Light_Selected_Enabled() {
        // Given
        snapshotBackgroundColor = .white
        
        // When
        button.isSelected = true
        button.appearance = .light
        
        // Then
        verify(view: button)
    }
    
    func testIconLabelButton_Light_Selected_Disabled() {
        // Given
        snapshotBackgroundColor = .white
        
        // When
        button.isSelected = true
        button.isEnabled = false
        button.appearance = .light
        
        // Then
        verify(view: button)
    }
    
}
