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

extension PermissionDeniedViewController {
    @objc
    func createConstraints() {
        backgroundBlurView.translatesAutoresizingMaskIntoConstraints = false
        backgroundBlurView.fitInSuperview()
    }

    override open func updateViewConstraints() {
        super.updateViewConstraints()

        guard !initialConstraintsCreated else { return }

        initialConstraintsCreated = true

        [heroLabel, settingsButton, laterButton].forEach() {
            $0?.translatesAutoresizingMaskIntoConstraints = false
        }

        var constraints = heroLabel.fitInSuperview(with: EdgeInsets(margin: 28), exclude: [.top, .bottom], activate: false).map{$0.value}

        constraints += [settingsButton.topAnchor.constraint(equalTo: heroLabel.bottomAnchor, constant: 28),
                        settingsButton.heightAnchor.constraint(equalToConstant: 40)]

        constraints += settingsButton.fitInSuperview(with: EdgeInsets(margin: 28), exclude: [.top, .bottom], activate: false).map{$0.value}

        constraints += [laterButton.topAnchor.constraint(equalTo: settingsButton.bottomAnchor, constant: 28),
                        laterButton.pinToSuperview(anchor: .bottom, inset: 28, activate: false),
                        laterButton.pinToSuperview(axisAnchor: .centerX, activate: false)]

        NSLayoutConstraint.activate(constraints)

    }
}

