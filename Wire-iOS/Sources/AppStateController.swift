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
import WireSyncEngine

private let zmLog = ZMSLog(tag: "AppState")

extension AppStateController {
    static let appStateDidTransition = Notification.Name(rawValue: "AppStateDidTransitionNotification")
    static let appStateKey = "AppState"
}

protocol AppStateControllerDelegate: class {
    func appStateController(transitionedTo appState: AppState,
                            transitionCompleted: @escaping () -> Void)
}

final class AppStateController : NSObject {
    
    // MARK - Public Property
    weak var delegate: AppStateControllerDelegate?
    let appStateCalculator = AppStateCalculator()
    
    // MARK - Private Set Property
    private(set) var previousAppState: AppState = .headless
    private(set) var appState: AppState = .headless {
        willSet {
            previousAppState = appState
        }
    }
    
    // MARK - Init
    override init() {
        super.init()
        appStateCalculator.delegate = self
    }
}

// MARK - AppStateCalculatorDelegate
extension AppStateController: AppStateCalculatorDelegate {
    func appStateCalculator(_: AppStateCalculator,
                            didCalculate appState: AppState,
                            completion: (() -> Void)?) {
        transition(to: appState, completion: completion)
    }
    
    // MARK - Private Helpers
    private func transition(to appState: AppState,
                            completion: (() -> Void)? = nil) {
        self.appState = appState
        if previousAppState != appState {
            zmLog.debug("transitioning to app state: \(appState)")
            delegate?.appStateController(transitionedTo: appState) {
                completion?()
            }
            notifyTransition()
        } else {
            completion?()
        }
    }
    
    private func notifyTransition() {
        NotificationCenter.default.post(name: AppStateController.appStateDidTransition,
                                        object: nil,
                                        userInfo: [AppStateController.appStateKey: appState])
    }
}
