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

import Foundation
import UIKit

/// A window used to obfuscate the main content window when the app is inactive.

final class ScreenCurtain: UIWindow {

    // MARK: - Properties

    weak var delegate: ScreenCurtainDelegate?

    // MARK: - Life cycle

    override init(frame: CGRect = UIScreen.main.bounds) {
        super.init(frame: frame)
        rootViewController = RootViewController()
        backgroundColor = .clear
        isOpaque = false
        windowLevel = .statusBar - 1
        accessibilityIdentifier = "screen_curtain_window"
        accessibilityViewIsModal = true

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Events

    @objc
    func applicationDidBecomeActive() {
        isHidden = true
    }

    @objc
    func applicationWillResignActive() {
        let shouldShow = delegate?.shouldShowScreenCurtain ?? false
        isHidden = !shouldShow
    }

}
