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

extension BottomOverlayViewController {
    @objc
    func setupBottomOverlay() {
        bottomOverlayView = UIView()
        bottomOverlayView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bottomOverlayView)

        var height: CGFloat
        ///TODO: response to size class update
        if traitCollection.horizontalSizeClass == .regular {
            height = 104
        } else {
            height = 88
        }

        bottomOverlayView.fitInSuperview(exclude: [.top])
        bottomOverlayView.heightAnchor.constraint(equalToConstant: height + UIScreen.safeArea.bottom)

        bottomOverlayView.backgroundColor = UIColor.black.withAlphaComponent(0.8)
    }

    @objc
    func setupTopView() {
        topView = UIView()
        topView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(topView)

        topView.bottomAnchor.constraint(equalTo: bottomOverlayView.topAnchor).isActive = true
        bottomOverlayView.fitInSuperview(exclude: [.bottom])

        topView.backgroundColor = .clear
    }
}

