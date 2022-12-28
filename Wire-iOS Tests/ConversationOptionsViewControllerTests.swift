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
    var guestLinkFeatureStatus: GuestLinkFeatureStatus
    var setAllowGuests: SetHandler?
    var allowGuestsChangedHandler: ((Bool) -> Void)?
    var guestLinkFeatureStatusChangedHandler: ((GuestLinkFeatureStatus) -> Void)?
    var linkResult: Result<String?>?
    var deleteResult: VoidResult = .success
    var createResult: Result<String>?
    var isCodeEnabled = true
    var areGuestPresent = true
    var isConversationFromSelfTeam = true

    init(allowGuests: Bool, guestLinkFeatureStatus: GuestLinkFeatureStatus = .enabled, setAllowGuests: SetHandler? = nil) {
        self.allowGuests = allowGuests
        self.guestLinkFeatureStatus = guestLinkFeatureStatus
        self.setAllowGuests = setAllowGuests
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

final class ConversationOptionsViewControllerTests: ZMSnapshotTestCase {

    // MARK: Renders Guests Screen when AllowGuests is either enabled or disabled

    func testThatItRendersGuestsScreenWhenAllowGuestsIsEnabled() {
        // GIVEN
        let config = MockOptionsViewModelConfiguration(allowGuests: true)
        let viewModel = ConversationGuestOptionsViewModel(configuration: config)
        let sut = ConversationGuestOptionsViewController(viewModel: viewModel, variant: .light)
        // THEN
        verify(matching: sut)
    }

    func testThatItRendersGuestsScreenWhenAllowGuestsIsEnabled_DarkTheme() {
        // GIVEN
        let config = MockOptionsViewModelConfiguration(allowGuests: true)
        let viewModel = ConversationGuestOptionsViewModel(configuration: config)
        let sut = ConversationGuestOptionsViewController(viewModel: viewModel, variant: .dark)
        sut.overrideUserInterfaceStyle = .dark

        // THEN
        verify(matching: sut)
    }

    func testThatItRendersGuestsScreenWhenAllowGuestsIsDisabled() {
        // GIVEN
        let config = MockOptionsViewModelConfiguration(allowGuests: false)
        let viewModel = ConversationGuestOptionsViewModel(configuration: config)
        let sut = ConversationGuestOptionsViewController(viewModel: viewModel, variant: .light)
        // THEN
        verify(matching: sut)
    }

    func testThatItRendersGuestsScreenWhenAllowGuestsIsDisabled_DarkTheme() {
        // GIVEN
        let config = MockOptionsViewModelConfiguration(allowGuests: false)
        let viewModel = ConversationGuestOptionsViewModel(configuration: config)
        let sut = ConversationGuestOptionsViewController(viewModel: viewModel, variant: .dark)
        sut.overrideUserInterfaceStyle = .dark

        // THEN
        verify(matching: sut)
    }

    // MARK: Renders Guests Screen when Guests link is enabled/disabled etc

    func testThatItRendersAllowGuests_WithLink() {
        // GIVEN
        let config = MockOptionsViewModelConfiguration(allowGuests: true)
        config.linkResult = .success("https://app.wire.com/772bfh1bbcssjs982637 3nbbdsn9917nbbdaehkej827648-72bns9")
        let viewModel = ConversationGuestOptionsViewModel(configuration: config)
        let sut = ConversationGuestOptionsViewController(viewModel: viewModel, variant: .light)
        // THEN
        verify(matching: sut)
    }

    func testThatItRendersAllowGuests_WithLink_DarkTheme() {
        // GIVEN
        let config = MockOptionsViewModelConfiguration(allowGuests: true)
        config.linkResult = .success("https://app.wire.com/772bfh1bbcssjs982637 3nbbdsn9917nbbdaehkej827648-72bns9")
        let viewModel = ConversationGuestOptionsViewModel(configuration: config)
        let sut = ConversationGuestOptionsViewController(viewModel: viewModel, variant: .dark)
        sut.overrideUserInterfaceStyle = .dark

        // THEN
        verify(matching: sut)
    }

    func testThatItRendersAllowGuests_WithLink_Copying() {
        // GIVEN
        let config = MockOptionsViewModelConfiguration(allowGuests: true)
        config.linkResult = .success("https://app.wire.com/772bfh1bbcssjs982637 3nbbdsn9917nbbdaehkej827648-72bns9")
        let viewModel = ConversationGuestOptionsViewModel(configuration: config)
        let sut = ConversationGuestOptionsViewController(viewModel: viewModel, variant: .light)
        viewModel.copyInProgress = true
        // THEN
        verify(matching: sut)
    }

    func testThatItRendersAllowGuests_WithLink_DarkTheme_Copying() {
        // GIVEN
        let config = MockOptionsViewModelConfiguration(allowGuests: true)
        config.linkResult = .success("https://app.wire.com/772bfh1bbcssjs982637 3nbbdsn9917nbbdaehkej827648-72bns9")
        let viewModel = ConversationGuestOptionsViewModel(configuration: config)
        let sut = ConversationGuestOptionsViewController(viewModel: viewModel, variant: .dark)
        viewModel.copyInProgress = true
        sut.overrideUserInterfaceStyle = .dark

        // THEN
        verify(matching: sut)
    }

    func testThatItRendersAllowGuests_WithoutLink() {
        // GIVEN
        let config = MockOptionsViewModelConfiguration(allowGuests: true)
        config.linkResult = .success(nil)
        let viewModel = ConversationGuestOptionsViewModel(configuration: config)
        let sut = ConversationGuestOptionsViewController(viewModel: viewModel, variant: .light)
        // THEN
        verify(matching: sut)
    }

    func testThatItRendersAllowGuests_WithoutLink_DarkTheme() {
        // GIVEN
        let config = MockOptionsViewModelConfiguration(allowGuests: true)
        config.linkResult = .success(nil)
        let viewModel = ConversationGuestOptionsViewModel(configuration: config)
        let sut = ConversationGuestOptionsViewController(viewModel: viewModel, variant: .dark)
        sut.overrideUserInterfaceStyle = .dark

        // THEN
        verify(matching: sut)
    }

    func testThatItRendersAllowGuests_WhenGuestsLinksAreDisabled_IsSelfTeamConversation() {
        // GIVEN
        let config = MockOptionsViewModelConfiguration(allowGuests: true, guestLinkFeatureStatus: .disabled)
        config.isConversationFromSelfTeam = true
        config.linkResult = .success(nil)
        let viewModel = ConversationGuestOptionsViewModel(configuration: config)
        let sut = ConversationGuestOptionsViewController(viewModel: viewModel, variant: .light)
        // THEN
        verify(matching: sut)
    }

    func testThatItRendersAllowGuests_WhenGuestsLinksAreDisabled_IsSelfTeamConversation_DarkTheme() {
        // GIVEN
        let config = MockOptionsViewModelConfiguration(allowGuests: true, guestLinkFeatureStatus: .disabled)
        config.isConversationFromSelfTeam = true
        config.linkResult = .success(nil)
        let viewModel = ConversationGuestOptionsViewModel(configuration: config)
        let sut = ConversationGuestOptionsViewController(viewModel: viewModel, variant: .dark)
        sut.overrideUserInterfaceStyle = .dark

        // THEN
        verify(matching: sut)
    }

    func testThatItRendersAllowGuests_WhenGuestsLinksAreDisabled_IsOtherTeamConversation() {
        // GIVEN
        let config = MockOptionsViewModelConfiguration(allowGuests: true, guestLinkFeatureStatus: .disabled)
        config.isConversationFromSelfTeam = false
        config.linkResult = .success(nil)
        let viewModel = ConversationGuestOptionsViewModel(configuration: config)
        let sut = ConversationGuestOptionsViewController(viewModel: viewModel, variant: .light)
        // THEN
        verify(matching: sut)
    }

    func testThatItRendersAllowGuests_WhenGuestsLinksAreDisabled_IsOtherTeamConversation_DarkTheme() {
        // GIVEN
        let config = MockOptionsViewModelConfiguration(allowGuests: true, guestLinkFeatureStatus: .disabled)
        config.isConversationFromSelfTeam = false
        config.linkResult = .success(nil)
        let viewModel = ConversationGuestOptionsViewModel(configuration: config)
        let sut = ConversationGuestOptionsViewController(viewModel: viewModel, variant: .dark)
        sut.overrideUserInterfaceStyle = .dark

        // THEN
        verify(matching: sut)
    }

    func testThatItRendersAllowGuests_WhenGuestsLinksAreEnabled_IsOtherTeamConversation() {
        // GIVEN
        let config = MockOptionsViewModelConfiguration(allowGuests: true, guestLinkFeatureStatus: .enabled)
        config.isConversationFromSelfTeam = false
        config.linkResult = .success(nil)
        let viewModel = ConversationGuestOptionsViewModel(configuration: config)
        let sut = ConversationGuestOptionsViewController(viewModel: viewModel, variant: .light)
        // THEN
        verify(matching: sut)
    }

    func testThatItRendersAllowGuests_WhenGuestsLinksAreEnabled_IsOtherTeamConversation_DarkTheme() {
        // GIVEN
        let config = MockOptionsViewModelConfiguration(allowGuests: true, guestLinkFeatureStatus: .enabled)
        config.isConversationFromSelfTeam = false
        config.linkResult = .success(nil)
        let viewModel = ConversationGuestOptionsViewModel(configuration: config)
        let sut = ConversationGuestOptionsViewController(viewModel: viewModel, variant: .dark)
        sut.overrideUserInterfaceStyle = .dark

        // THEN
        verify(matching: sut)
    }

    func testThatItRendersAllowGuests_WhenGuestLinkFeatureStatusIsUnknown() {
        // GIVEN
        let config = MockOptionsViewModelConfiguration(allowGuests: true, guestLinkFeatureStatus: .unknown)
        let viewModel = ConversationGuestOptionsViewModel(configuration: config)
        let sut = ConversationGuestOptionsViewController(viewModel: viewModel, variant: .light)
        // THEN
        verify(matching: sut)
    }

    func testThatItRendersAllowGuests_WhenGuestLinkFeatureStatusIsUnknown_DarkTheme() {
        // GIVEN
        let config = MockOptionsViewModelConfiguration(allowGuests: true, guestLinkFeatureStatus: .unknown)
        let viewModel = ConversationGuestOptionsViewModel(configuration: config)
        let sut = ConversationGuestOptionsViewController(viewModel: viewModel, variant: .dark)
        sut.overrideUserInterfaceStyle = .dark

        // THEN
        verify(matching: sut)
    }

    // MARK: Renders Group's Title in Guests Screen

    func testThatItRendersItsTitle() {
        // GIVEN
        let config = MockOptionsViewModelConfiguration(allowGuests: true)
        let viewModel = ConversationGuestOptionsViewModel(configuration: config)
        let sut = ConversationGuestOptionsViewController(viewModel: viewModel, variant: .light)
        // THEN
        verify(matching: sut.wrapInNavigationController())
    }

    // MARK: Renders Guests Screen when a change is occured

    func testThatItUpdatesWhenItReceivesAChange() {
        // GIVEN
        let config = MockOptionsViewModelConfiguration(allowGuests: false)
        config.linkResult = .success(nil)
        let viewModel = ConversationGuestOptionsViewModel(configuration: config)
        let sut = ConversationGuestOptionsViewController(viewModel: viewModel, variant: .light)
        XCTAssertNotNil(config.allowGuestsChangedHandler)
        config.allowGuests = true
        config.allowGuestsChangedHandler?(true)
        // THEN
        verify(matching: sut)
    }

    func testThatItUpdatesWhenItReceivesAChange_Loading() {
        // GIVEN
        let config = MockOptionsViewModelConfiguration(allowGuests: false)
        let viewModel = ConversationGuestOptionsViewModel(configuration: config)
        let sut = ConversationGuestOptionsViewController(viewModel: viewModel, variant: .light)
        XCTAssertNotNil(config.allowGuestsChangedHandler)
        config.allowGuests = true
        config.allowGuestsChangedHandler?(true)
        // THEN
        verify(matching: sut)
    }

    func testThatItRendersLoading() {
        // GIVEN
        let config = MockOptionsViewModelConfiguration(allowGuests: false)
        let viewModel = ConversationGuestOptionsViewModel(configuration: config)
        let sut = ConversationGuestOptionsViewController(viewModel: viewModel, variant: .light)
        let navigationController = sut.wrapInNavigationController()
        // WHEN
        viewModel.setAllowGuests(true)
        // THEN
        verify(matching: navigationController)
    }

    func testThatItRendersLoading_DarkTheme() {
        // GIVEN
        let config = MockOptionsViewModelConfiguration(allowGuests: false)
        let viewModel = ConversationGuestOptionsViewModel(configuration: config)
        let sut = ConversationGuestOptionsViewController(viewModel: viewModel, variant: .dark)
        sut.overrideUserInterfaceStyle = .dark
        let navigationController = sut.wrapInNavigationController()
        sut.overrideUserInterfaceStyle = .dark
        // WHEN
        viewModel.setAllowGuests(true)
        // THEN
        verify(matching: navigationController)
    }

    // MARK: Renders different kind of alerts

    func testThatItRendersRemoveGuestsConfirmationAlert() {
        // WHEN & THEN
        let sut = UIAlertController.confirmRemovingGuests { _ in }
        verify(matching: sut)
    }

    func testThatItRendersRevokeLinkConfirmationAlert() {
        // WHEN & THEN
        let sut = UIAlertController.confirmRevokingLink { _ in }
        verify(matching: sut)
    }

    func testThatNoAlertIsShowIfNoGuestIsPresent() {
        // GIVEN
        let config = MockOptionsViewModelConfiguration(allowGuests: true)
        config.areGuestPresent = false
        let viewModel = ConversationGuestOptionsViewModel(configuration: config)
        // Show the alert
        let sut = viewModel.setAllowGuests(false)
        // THEN
        XCTAssertNil(sut)
    }

    func testThatItRendersRemoveGuestsWarning() {
        // GIVEN
        let config = MockOptionsViewModelConfiguration(allowGuests: true)
        let viewModel = ConversationGuestOptionsViewModel(configuration: config)
        // for ConversationOptionsViewModel's delegate
        _ = ConversationGuestOptionsViewController(viewModel: viewModel, variant: .light)
        // Show the alert
        let sut = viewModel.setAllowGuests(false)!
        // THEN
        verify(matching: sut)
    }
}
