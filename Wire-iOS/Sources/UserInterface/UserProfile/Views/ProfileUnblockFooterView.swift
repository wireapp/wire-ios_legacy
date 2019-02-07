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

@objcMembers
final class ProfileUnblockFooterView: UIView {

    let unblockButton = Button(style: .full)

    init() {
        super.init(frame: CGRect.zero)

        unblockButton.translatesAutoresizingMaskIntoConstraints = false

        addSubview(unblockButton)

        unblockButton.fitInSuperview(with: EdgeInsets(margin: 24), exclude: [.top])
        NSLayoutConstraint.activate([unblockButton.heightAnchor.constraint(equalToConstant: 40)])

        unblockButton.setTitle("profile.unblock_button_title".localized(uppercased: true), for: .normal)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

