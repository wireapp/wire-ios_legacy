//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

class MockOptionsViewModelConfiguration: ConversationOptionsViewModelConfiguration {
    typealias SetHandler = (Bool, (VoidResult) -> Void) -> Void
    var isTeamOnly: Bool
    var setTeamOnlyHandler: SetHandler?
    var teamOnlyChangedHandler: ((Bool) -> Void)?
    
    init(isTeamOnly: Bool, setTeamOnly: SetHandler? = nil) {
        self.isTeamOnly = isTeamOnly
        self.setTeamOnlyHandler = setTeamOnly
    }
    
    func setTeamOnly(_ teamOnly: Bool, completion: @escaping (VoidResult) -> Void) {
        setTeamOnlyHandler?(teamOnly, completion)
    }
    
}

final class ConversationOptionsViewControllerTests: ZMSnapshotTestCase {

    func testThatItRendersTeamOnly() {
        // Given
        let config = MockOptionsViewModelConfiguration(isTeamOnly: true)
        let viewModel = ConversationOptionsViewModel(configuration: config)
        let sut = ConversationOptionsViewController(viewModel: viewModel, variant: .light)
        
        // Then
        verify(view: sut.view)
    }
    
    func testThatItRendersTeamOnly_DarkTheme() {
        // Given
        let config = MockOptionsViewModelConfiguration(isTeamOnly: true)
        let viewModel = ConversationOptionsViewModel(configuration: config)
        let sut = ConversationOptionsViewController(viewModel: viewModel, variant: .dark)
        
        // Then
        verify(view: sut.view)
    }
    
    func testThatItRendersNotTeamOnly() {
        // Given
        let config = MockOptionsViewModelConfiguration(isTeamOnly: false)
        let viewModel = ConversationOptionsViewModel(configuration: config)
        let sut = ConversationOptionsViewController(viewModel: viewModel, variant: .light)
        
        // Then
        verify(view: sut.view)
    }
    
    func testThatItUpdatesWhenItReceivesAChange() {
        // Given
        let config = MockOptionsViewModelConfiguration(isTeamOnly: false)
        let viewModel = ConversationOptionsViewModel(configuration: config)
        let sut = ConversationOptionsViewController(viewModel: viewModel, variant: .light)
        
        XCTAssertNotNil(config.teamOnlyChangedHandler)
        config.isTeamOnly = true
        config.teamOnlyChangedHandler?(true)
        
        // Then
        verify(view: sut.view)
    }
    
    func testThatItRendersNotTeamOnly_DarkTheme() {
        // Given
        let config = MockOptionsViewModelConfiguration(isTeamOnly: false)
        let viewModel = ConversationOptionsViewModel(configuration: config)
        let sut = ConversationOptionsViewController(viewModel: viewModel, variant: .dark)
        
        // Then
        verify(view: sut.view)
    }
    
    func testThatItRendersLoading() {
        // Given
        let config = MockOptionsViewModelConfiguration(isTeamOnly: true)
        let viewModel = ConversationOptionsViewModel(configuration: config)
        let sut = ConversationOptionsViewController(viewModel: viewModel, variant: .light)
        
        sut.loadViewIfNeeded()
        sut.view.layer.speed = 0
        
        // When
        viewModel.setTeamOnly(false)
        
        // Then
        verify(view: sut.view)
    }
    
    func testThatItRendersLoading_DarkTheme() {
        // Given
        let config = MockOptionsViewModelConfiguration(isTeamOnly: true)
        let viewModel = ConversationOptionsViewModel(configuration: config)
        let sut = ConversationOptionsViewController(viewModel: viewModel, variant: .dark)
        
        sut.loadViewIfNeeded()
        sut.view.layer.speed = 0
        
        // When
        viewModel.setTeamOnly(false)
        
        // Then
        verify(view: sut.view)
    }
    
    func testThatItRendersRemoveGuestsConfirmationAlert() {
        // When & Then
        let sut = UIAlertController.confirmRemovingGuests { _ in }
        verifyAlertController(sut)
    }
    
    func testThatItRendersRevokeLinkConfirmationAlert() {
        // When & Then
        let sut = UIAlertController.confirmRevokingLink { _ in }
        verifyAlertController(sut)
    }
    
    private func verifyAlertController(_ controller: UIAlertController, file: StaticString = #file, line: UInt = #line) {
        // Given
        let window = UIWindow(frame: .init(x: 0, y: 0, width: 375, height: 667))
        let container = UIViewController()
        container.loadViewIfNeeded()
        window.rootViewController = container
        window.makeKeyAndVisible()
        controller.loadViewIfNeeded()
        controller.view.setNeedsLayout()
        controller.view.layoutIfNeeded()
        
        // When
        let presentationExpectation = expectation(description: "It should be presented")
        container.present(controller, animated: false) {
            presentationExpectation.fulfill()
        }
        
        // Then
        waitForExpectations(timeout: 2, handler: nil)
        verify(view: controller.view, file: file, line: line)
    }
    
}
