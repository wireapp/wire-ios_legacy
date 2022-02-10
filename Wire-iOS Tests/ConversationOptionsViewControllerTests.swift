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
import SnapshotTesting

final class MockOptionsViewModelConfiguration: ConversationGuestOptionsViewModelConfiguration {

    typealias SetHandler = (Bool, (VoidResult) -> Void) -> Void
    var allowGuests: Bool
    var allowGuestLinks: Bool
    var setAllowGuests: SetHandler?
    var allowGuestsChangedHandler: ((Bool) -> Void)?
    var title: String
    var linkResult: Result<String?>?
    var deleteResult: VoidResult = .success
    var createResult: Result<String>?
    var isCodeEnabled = true
    var areGuestPresent = true

    init(allowGuests: Bool, allowGuestLinks: Bool = true, title: String = "", setAllowGuests: SetHandler? = nil) {
        self.allowGuests = allowGuests
        self.allowGuestLinks = allowGuestLinks
        self.setAllowGuests = setAllowGuests
        self.title = title
    }

    func setAllowGuests(_ allowGuests: Bool, completion: @escaping (VoidResult) -> Void) {
        setAllowGuests?(allowGuests, completion)
    }

    func createConversationLink(completion: @escaping (Result<String>) -> Void) {
        createResult.apply(completion)
    }

    func fetchConversationLink(completion: @escaping (Result<String?>) -> Void) {
        linkResult.apply(completion)
    }

    func deleteLink(completion: @escaping (VoidResult) -> Void) {
        completion(deleteResult)
    }
}

final class ConversationOptionsViewControllerTests: XCTestCase {

    // MARK: Renders Guests Screen when AllowGuests is either enabled or disabled

    func testThatItRendersGuestsScreenWhenAllowGuestsIsEnabled() {
        // Given
        let config = MockOptionsViewModelConfiguration(allowGuests: true)
        let viewModel = ConversationGuestOptionsViewModel(configuration: config)
        let sut = ConversationGuestOptionsViewController(viewModel: viewModel, variant: .light)

        // Then
        verify(matching: sut)
    }

    func testThatItRendersGuestsScreenWhenAllowGuestsIsEnabled_DarkTheme() {
        // Given
        let config = MockOptionsViewModelConfiguration(allowGuests: true)
        let viewModel = ConversationGuestOptionsViewModel(configuration: config)
        let sut = ConversationGuestOptionsViewController(viewModel: viewModel, variant: .dark)

        // Then
        verify(matching: sut)
    }

    func testThatItRendersGuestsScreenWhenAllowGuestsIsDisabled() {
        // Given
        let config = MockOptionsViewModelConfiguration(allowGuests: false)
        let viewModel = ConversationGuestOptionsViewModel(configuration: config)
        let sut = ConversationGuestOptionsViewController(viewModel: viewModel, variant: .light)

        // Then
        verify(matching: sut)
    }

    func testThatItRendersGuestsScreenWhenAllowGuestsIsDisabled_DarkTheme() {
        // Given
        let config = MockOptionsViewModelConfiguration(allowGuests: false)
        let viewModel = ConversationGuestOptionsViewModel(configuration: config)
        let sut = ConversationGuestOptionsViewController(viewModel: viewModel, variant: .dark)

        // Then
        verify(matching: sut)
    }

    // MARK: Renders Guests Screen when Guests link is enabled/disabled etc

    func testThatItRendersAllowGuests_WithLink() {
        // Given
        let config = MockOptionsViewModelConfiguration(allowGuests: true)
        config.linkResult = .success("https://app.wire.com/772bfh1bbcssjs982637 3nbbdsn9917nbbdaehkej827648-72bns9")
        let viewModel = ConversationGuestOptionsViewModel(configuration: config)
        let sut = ConversationGuestOptionsViewController(viewModel: viewModel, variant: .light)

        // Then
        verify(matching: sut)
    }

    func testThatItRendersAllowGuests_WithLink_DarkTheme() {
        // Given
        let config = MockOptionsViewModelConfiguration(allowGuests: true)
        config.linkResult = .success("https://app.wire.com/772bfh1bbcssjs982637 3nbbdsn9917nbbdaehkej827648-72bns9")
        let viewModel = ConversationGuestOptionsViewModel(configuration: config)
        let sut = ConversationGuestOptionsViewController(viewModel: viewModel, variant: .dark)

        // Then
        verify(matching: sut)
    }

    func testThatItRendersAllowGuests_WithLink_Copying() {
        // Given
        let config = MockOptionsViewModelConfiguration(allowGuests: true)
        config.linkResult = .success("https://app.wire.com/772bfh1bbcssjs982637 3nbbdsn9917nbbdaehkej827648-72bns9")
        let viewModel = ConversationGuestOptionsViewModel(configuration: config)
        let sut = ConversationGuestOptionsViewController(viewModel: viewModel, variant: .light)
        viewModel.copyInProgress = true

        // Then
        verify(matching: sut)
    }

    func testThatItRendersAllowGuests_WithLink_DarkTheme_Copying() {
        // Given
        let config = MockOptionsViewModelConfiguration(allowGuests: true)
        config.linkResult = .success("https://app.wire.com/772bfh1bbcssjs982637 3nbbdsn9917nbbdaehkej827648-72bns9")
        let viewModel = ConversationGuestOptionsViewModel(configuration: config)
        let sut = ConversationGuestOptionsViewController(viewModel: viewModel, variant: .dark)
        viewModel.copyInProgress = true

        // Then
        verify(matching: sut)
    }

    func testThatItRendersAllowGuests_WithoutLink() {
        // Given
        let config = MockOptionsViewModelConfiguration(allowGuests: true)
        config.linkResult = .success(nil)
        let viewModel = ConversationGuestOptionsViewModel(configuration: config)
        let sut = ConversationGuestOptionsViewController(viewModel: viewModel, variant: .light)

        // Then
        verify(matching: sut)
    }

    func testThatItRendersAllowGuests_WithoutLink_DarkTheme() {
        // Given
        let config = MockOptionsViewModelConfiguration(allowGuests: true)
        config.linkResult = .success(nil)
        let viewModel = ConversationGuestOptionsViewModel(configuration: config)
        let sut = ConversationGuestOptionsViewController(viewModel: viewModel, variant: .dark)

        // Then
        verify(matching: sut)
    }

    func testThatItRendersAllowGuests_WhenGuestsLinksAreDisabled() {
        // Given
        let config = MockOptionsViewModelConfiguration(allowGuests: true, allowGuestLinks: false)
        config.linkResult = .success(nil)
        let viewModel = ConversationGuestOptionsViewModel(configuration: config)
        let sut = ConversationGuestOptionsViewController(viewModel: viewModel, variant: .light)

        // Then
        verify(matching: sut)
    }

    func testThatItRendersAllowGuests_WhenGuestsLinksAreDisabled_DarkTheme() {
        // Given
        let config = MockOptionsViewModelConfiguration(allowGuests: true, allowGuestLinks: false)
        config.linkResult = .success(nil)
        let viewModel = ConversationGuestOptionsViewModel(configuration: config)
        let sut = ConversationGuestOptionsViewController(viewModel: viewModel, variant: .dark)

        // Then
        verify(matching: sut)
    }

    // MARK: Renders Group's Title in Guests Screen

    func testThatItRendersItsTitle() {
        // Given
        let config = MockOptionsViewModelConfiguration(allowGuests: true, title: "Italy Trip")
        let viewModel = ConversationGuestOptionsViewModel(configuration: config)
        let sut = ConversationGuestOptionsViewController(viewModel: viewModel, variant: .light)

        // Then
        verify(matching: sut.wrapInNavigationController())
    }

    // MARK: Renders Guests Screen when a change is occured

    func testThatItUpdatesWhenItReceivesAChange() {
        // Given
        let config = MockOptionsViewModelConfiguration(allowGuests: false)
        config.linkResult = .success(nil)
        let viewModel = ConversationGuestOptionsViewModel(configuration: config)
        let sut = ConversationGuestOptionsViewController(viewModel: viewModel, variant: .light)

        XCTAssertNotNil(config.allowGuestsChangedHandler)
        config.allowGuests = true
        config.allowGuestsChangedHandler?(true)

        // Then
        verify(matching: sut)
    }

    func testThatItUpdatesWhenItReceivesAChange_Loading() {
        // Given
        let config = MockOptionsViewModelConfiguration(allowGuests: false)
        let viewModel = ConversationGuestOptionsViewModel(configuration: config)
        let sut = ConversationGuestOptionsViewController(viewModel: viewModel, variant: .light)

        XCTAssertNotNil(config.allowGuestsChangedHandler)
        config.allowGuests = true
        config.allowGuestsChangedHandler?(true)

        // Then
        verify(matching: sut)
    }

    func testThatItRendersLoading() {
        // Given
        let config = MockOptionsViewModelConfiguration(allowGuests: false)
        let viewModel = ConversationGuestOptionsViewModel(configuration: config)
        let sut = ConversationGuestOptionsViewController(viewModel: viewModel, variant: .light)
        let navigationController = sut.wrapInNavigationController()

        // When
        viewModel.setAllowGuests(true)

        // Then
        verify(matching: navigationController)
    }

    func testThatItRendersLoading_DarkTheme() {
        // Given
        let config = MockOptionsViewModelConfiguration(allowGuests: false)
        let viewModel = ConversationGuestOptionsViewModel(configuration: config)
        let sut = ConversationGuestOptionsViewController(viewModel: viewModel, variant: .dark)
        let navigationController = sut.wrapInNavigationController()

        // When
        viewModel.setAllowGuests(true)

        // Then
        verify(matching: navigationController)
    }

    // MARK: Renders different kind of alerts

    func testThatItRendersRemoveGuestsConfirmationAlert() {
        // When & Then
        let sut = UIAlertController.confirmRemovingGuests { _ in }
        verify(matching: sut)
    }

    func testThatItRendersRevokeLinkConfirmationAlert() {
        // When & Then
        let sut = UIAlertController.confirmRevokingLink { _ in }
        verify(matching: sut)
    }

    func testThatNoAlertIsShowIfNoGuestIsPresent() {
        // Given
        let config = MockOptionsViewModelConfiguration(allowGuests: true)
        config.areGuestPresent = false

        let viewModel = ConversationGuestOptionsViewModel(configuration: config)

        /// Show the alert
        let sut = viewModel.setAllowGuests(false)

        // Then
        XCTAssertNil(sut)
    }

    func testThatItRendersRemoveGuestsWarning() {
        // Given
        let config = MockOptionsViewModelConfiguration(allowGuests: true)
        let viewModel = ConversationGuestOptionsViewModel(configuration: config)

        /// for ConversationOptionsViewModel's delegate
        _ = ConversationGuestOptionsViewController(viewModel: viewModel, variant: .light)

        /// Show the alert
        let sut = viewModel.setAllowGuests(false)!

        // Then
        verify(matching: sut)
    }
}
