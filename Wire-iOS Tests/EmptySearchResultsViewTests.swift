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

struct EmptySearchResultsViewTestState: Copyable {
    init(instance: EmptySearchResultsViewTestState) {
        self.colorSchemeVariant = instance.colorSchemeVariant
        self.isSelfUserAdmin = instance.isSelfUserAdmin
        self.searchingForServices = instance.searchingForServices
        self.hasFilter = instance.hasFilter
    }

    init(colorSchemeVariant: ColorSchemeVariant, isSelfUserAdmin: Bool, searchingForServices: Bool, hasFilter: Bool) {
        self.colorSchemeVariant = colorSchemeVariant
        self.isSelfUserAdmin = isSelfUserAdmin
        self.searchingForServices = searchingForServices
        self.hasFilter = hasFilter
    }

    var colorSchemeVariant: ColorSchemeVariant
    var isSelfUserAdmin: Bool
    var searchingForServices: Bool
    var hasFilter: Bool

    func createView() -> EmptySearchResultsView {
        let view = EmptySearchResultsView(variant: colorSchemeVariant, isSelfUserAdmin: isSelfUserAdmin)
        view.updateStatus(searchingForServices: searchingForServices, hasFilter: hasFilter)
        return view
    }
}

extension ColorSchemeVariant: CustomStringConvertible {
    public var description: String {
        switch self {
        case .dark:
            return "ColorSchemeVariant.dark"
        case .light:
            return "ColorSchemeVariant.light"
        }
    }
}

extension EmptySearchResultsViewTestState: CustomStringConvertible {
    var description: String {
        return "colorSchemeVariant: \(colorSchemeVariant) isSelfUserAdmin: \(isSelfUserAdmin) searchingForServices: \(searchingForServices) hasFilter: \(hasFilter)"
    }
}

extension ColorSchemeVariant: CaseIterable {
    public static var allCases: [ColorSchemeVariant] {
        return [.light, .dark]
    }
}

final class EmptySearchResultsViewTests: XCTestCase {

    func testNoResultsForUsers() {
        // given
        let sut = EmptySearchResultsView(variant: .dark, isSelfUserAdmin: false)
        sut.updateStatus(searchingForServices: false, hasFilter: true)
        configureBounds(for: sut)

        // then
        verify(matching: sut)

    }

    func testNoResultsForUsers_WhenEveryoneHaveBeenAdded() {
        // given
        let sut = EmptySearchResultsView(variant: .dark, isSelfUserAdmin: false)
        sut.updateStatus(searchingForServices: false, hasFilter: false)
        configureBounds(for: sut)

        // then
        verify(matching: sut)
    }

    func testNoResultsForServices() {
        // given
        let sut = EmptySearchResultsView(variant: .dark, isSelfUserAdmin: false)
        sut.updateStatus(searchingForServices: true, hasFilter: true)
        configureBounds(for: sut)

        // then
        verify(matching: sut)
    }

    func testNoResultsForServices_WhenAdmin() {
        // given
        let sut = EmptySearchResultsView(variant: .dark, isSelfUserAdmin: true)
        sut.updateStatus(searchingForServices: true, hasFilter: false)
        configureBounds(for: sut)

        // then
        verify(matching: sut)
    }

    // MARK: - Helpers

    func configureBounds(for view: UIView) {
        view.bounds.size = view.systemLayoutSizeFitting(
            CGSize(width: 375, height: 600),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
    }

}
