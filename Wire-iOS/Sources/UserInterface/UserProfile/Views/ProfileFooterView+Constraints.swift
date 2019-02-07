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

import Foundation

extension ProfileFooterView {

    @objc
    func setupConstraints() {
        [leftButton, rightButton].forEach(){ $0?.translatesAutoresizingMaskIntoConstraints = false}

        leftButton.fitInSuperview(
            with: EdgeInsets(top: 0, leading: 16, bottom: 12, trailing: .nan),
            exclude: [.trailing])

        rightButton.fitInSuperview(
            with: EdgeInsets(top: 0, leading: .nan, bottom: 12, trailing: 8),
            exclude: [.leading])

        NSLayoutConstraint.activate([
            leftButton.heightAnchor.constraint(equalToConstant: 32),
            rightButton.heightAnchor.constraint(equalToConstant: 32),
            rightButton.widthAnchor.constraint(equalTo: leftButton.widthAnchor)])
    }

}
