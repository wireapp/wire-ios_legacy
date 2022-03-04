//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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
import SnapshotTesting
import XCTest

@testable import Wire

class ToastViewTests: XCTestCase {
    let callRelayMessage = "Your calling relay is not reachable. This may affect your call experience."

    func createSut(configuration: ToastConfiguration) -> UIView {
        let view = ToastView(configuration: configuration)

        let width = XCTestCase.DeviceSizeIPhone5.width

        view.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            view.widthAnchor.constraint(equalToConstant: width)
        ])

        return view
    }

    func testView_Not_Dismissable() {
        let sut = createSut(configuration: ToastConfiguration(
            message: "You are not connected to internet",
            colorScheme: .utilityNeutral,
            variant: .light,
            dismissable: false,
            moreInfoAction: nil,
            accessibilityIdentifier: nil)
        )

        verify(matching: sut)
    }

    func testView_Dismissable() {
        let sut = createSut(configuration: ToastConfiguration(
            message: "Your app has been updated",
            colorScheme: .utilitySuccess,
            variant: .light,
            dismissable: true,
            moreInfoAction: nil,
            accessibilityIdentifier: nil)
        )

        verify(matching: sut)
    }

    func testView_Dismissable_With_MoreInfoButton() {
        let sut = createSut(configuration: ToastConfiguration(
            message: callRelayMessage,
            colorScheme: .utilityError,
            variant: .light,
            dismissable: true,
            moreInfoAction: {},
            accessibilityIdentifier: nil)
        )

        verify(matching: sut)
    }

    func testView_Dismissable_With_MoreInfoButton_DarkVariant() {
        let sut = createSut(configuration: ToastConfiguration(
            message: callRelayMessage,
            colorScheme: .utilityError,
            variant: .dark,
            dismissable: true,
            moreInfoAction: {},
            accessibilityIdentifier: nil)
        )

        verify(matching: sut)
    }
}
