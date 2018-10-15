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

final class ContactsCellSnapshotTests: ZMSnapshotTestCase {

    var sut: ContactsCell!
    let buttonTitles = ["contacts_ui.action_button.open".localized,
                        "contacts_ui.action_button.invite".localized,
                        "connection_request.send_button_title".localized]

    override func setUp() {
        super.setUp()
        sut = ContactsCell()

        sut.allActionButtonTitles = buttonTitles
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testForInviteButton() {

        let user = MockUser.mockUsers()[0]
        sut.user = user

        sut.actionButton.setTitle(buttonTitles[1], for: .normal)

        verifyInAllColorSchemes(view: sut.prepareForSnapshots())
    }

    func testForOpenButton() {

        let user = MockUser.mockUsers()[0]
        sut.user = user

        sut.actionButton.setTitle(buttonTitles[0], for: .normal)

        verifyInAllColorSchemes(view: sut.prepareForSnapshots())
    }

    func testForOpenButtonWithALongUsername() {

        let user = MockUser.mockUsers()[0]
        user.name = "A very long username which should be clipped at tail"
        sut.user = user

        sut.actionButton.setTitle(buttonTitles[0], for: .normal)

        verifyInAllColorSchemes(view: sut.prepareForSnapshots())
    }

    func testForNoSubtitle() {

        let user = MockUser.mockUsers()[0]
        (user as Any as! MockUser).handle = nil
        sut.user = user

        sut.actionButton.setTitle(buttonTitles[0], for: .normal)

        verifyInAllColorSchemes(view: sut.prepareForSnapshots())
    }
}

extension UITableView: Themeable {
    private func getFirstThemeableCell() -> Themeable? {
        let indexPath = IndexPath(row: 0, section: 0)
        if let cell = self.cellForRow(at: indexPath) as? Themeable {
            return cell
        }

        return nil
    }

    public var colorSchemeVariant: ColorSchemeVariant {
        get {
            return getFirstThemeableCell()?.colorSchemeVariant ?? .light
        }
        set(newValue) {
            var cell = getFirstThemeableCell()
            cell?.colorSchemeVariant = newValue
        }
    }

    public func applyColorScheme(_ colorSchemeVariant: ColorSchemeVariant) {
    }


}
