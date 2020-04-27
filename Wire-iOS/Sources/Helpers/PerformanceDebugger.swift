//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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
import WireSystem
import UIKit

/**
 * An object that tracks performance issues in the application for debugging purposes.
 */

final class PerformanceDebugger {

    /// The shared debugger.
    static let shared = PerformanceDebugger()

    private let log = ZMSLog(tag: "Performance")
    private var displayLink: CADisplayLink!

    init() {
        displayLink = CADisplayLink(target: self, selector: #selector(handleDisplayLink))
    }

    deinit {
        displayLink.remove(from: .main, forMode: .default)
    }

    /// Starts tracking performance issues.
    func start() {
        guard Bundle.developerModeEnabled else {
            return
        }

        displayLink.add(to: .main, forMode: .default)
        NotificationCenter.default.addObserver(self, selector: #selector(handleMemoryWarning), name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
    }

    @objc
    private func handleDisplayLink() {
        let elapsedTime = displayLink.duration * 100

        if elapsedTime > 16.7 {
            log.warn("Frame dropped after \(elapsedTime)s")
        }
    }

    @objc
    private func handleMemoryWarning() {
        log.warn("Application did receive memory warning.")
    }

}
