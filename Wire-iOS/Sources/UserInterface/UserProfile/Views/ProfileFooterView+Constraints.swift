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
        let buttonHeight: CGFloat = 32

        [leftButton, rightButton].forEach(){ $0.translatesAutoresizingMaskIntoConstraints = false}

        leftButton.fitInSuperview(
            with: EdgeInsets(top: 0,
                             leading: 16,
                             bottom: 12),
            exclude: [.trailing])
        
        rightButton.fitInSuperview(
            with: EdgeInsets(top: 0,
                             bottom: 12,
                             trailing: 8),
            exclude: [.leading])
        
        rightButton.setDimensions(length: buttonHeight)
        
        NSLayoutConstraint.activate([
            leftButton.heightAnchor.constraint(equalToConstant: buttonHeight)])
    }
}
