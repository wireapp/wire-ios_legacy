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

extension AudioTrackViewController {
    @objc
    func createInitialConstraints() {
        [backgroundView, blurEffectView, audioHeaderView, audioTrackView, subtitleLabel].forEach{$0.translatesAutoresizingMaskIntoConstraints = false}

        backgroundView.fitInSuperview()
        blurEffectView.fitInSuperview()

        audioHeaderView.fitInSuperview(exclude: [.bottom])
        NSLayoutConstraint.activate([
            audioHeaderView.heightAnchor.constraint(equalToConstant: 64)
        ])

        audioTrackView.centerInSuperview()
        audioTrackView.fitInSuperview(with: EdgeInsets(margin: 64),
                                      exclude: [.leading, .trailing])

        NSLayoutConstraint.activate([
            audioTrackView.heightAnchor.constraint(equalTo: audioTrackView.widthAnchor)
            ])

        subtitleLabel.fitInSuperview(exclude: [.top])
        let sizeConstraint = view.heightAnchor.constraint(equalTo: view.widthAnchor)
        sizeConstraint.priority = .defaultHigh

        NSLayoutConstraint.activate([
            subtitleLabel.topAnchor.constraint(equalTo: audioTrackView.bottomAnchor),

            view.heightAnchor.constraint(lessThanOrEqualToConstant: 375),
            sizeConstraint
            ])
    }
}
