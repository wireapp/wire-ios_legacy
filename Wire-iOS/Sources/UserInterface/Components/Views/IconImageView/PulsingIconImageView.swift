//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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
import WireCommonComponents

protocol PulsingIconImageStyle {
    var shouldPulse: Bool { get }
}

class PulsingIconImageView: IconImageView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func applicationDidBecomeActive() {
        refreshPulsing()
    }

    func set(style: (IconImageStyle & PulsingIconImageStyle)? = nil,
             size: StyleKitIcon.Size? = nil,
             color: UIColor? = nil) {
        super.set(style: style, size: size, color: color)
        refreshPulsing()
    }

    func startPulsing() {
        alpha = 1
        UIView.animate(
            withDuration: 0.7,
            delay: 0,
            options: [.repeat, .autoreverse, .curveEaseInOut],
            animations: {
                self.alpha = 0.2
        })
    }

    func stopPulsing() {
        UIView.animate(withDuration: 0, animations: {
            self.alpha = 1
        })
    }

    private func refreshPulsing() {
        guard let style = style as? PulsingIconImageStyle else { return }
        style.shouldPulse ? startPulsing() : stopPulsing()
    }
}
