//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

class IncomingRequestFooterTests: ZMSnapshotTestCase {

    override func setUp() {
        super.setUp()
    }

    func testIncomingRequestFooter_Light() {
        let footer = IncomingRequestFooterView()
        footer.overrideUserInterfaceStyle = .light
        let view = footer.prepareForSnapshots()

        verify(view: view)
    }

    func testIncomingRequestFooter_Dark() {
        let footer = IncomingRequestFooterView()
        footer.overrideUserInterfaceStyle = .dark
        let view = footer.prepareForSnapshots()

        verify(view: view)
    }

}

fileprivate extension IncomingRequestFooterView {

    func prepareForSnapshots() -> UIView {
        let container = UIView()
        container.addSubview(self)
        translatesAutoresizingMaskIntoConstraints = false
        container.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            container.widthAnchor.constraint(equalToConstant: 375),
            container.topAnchor.constraint(equalTo: topAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor),
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])

        container.setNeedsLayout()
        container.layoutIfNeeded()
        return container
    }

}
