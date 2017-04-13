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


import UIKit
import Cartography


class InviteButtonView: UIView {

    typealias ButtonTapHandler = (Button) -> Void
    private let inviteButton = Button(style: .fullMonochrome)
    private let onTap: ButtonTapHandler

    init(onTap: @escaping ButtonTapHandler) {
        self.onTap = onTap
        super.init(frame: .zero)
        setupViews()
        createConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        addSubview(inviteButton)
        inviteButton.setTitle("self.settings.invite_friends.title".localized, for: .normal)
        inviteButton.addTarget(self, action: #selector(inviteButtonTapped), for: .touchUpInside)
    }

    private func createConstraints() {
        constrain(self, inviteButton) { view, button in
            button.edges == inset(view.edges, 24)
            button.height == 32
        }
    }

    func inviteButtonTapped(_ sender: Button) {
        onTap(sender)
    }

}
