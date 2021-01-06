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

extension ZClientViewController {

    func setUpCustomPasscodeIfNeeded(then block: @escaping () -> Void) {
        guard
            let appLock = ZMUserSession.shared()?.appLockController,
            appLock.needsToSetUpCustomPasscode
        else {
            block()
            return
        }

        let callBack: ResultHandler = { _ in block() }
        let viewController = PasscodeSetupViewController.createKeyboardAvoidingFullScreenView(context: .createPasscode, callback: callBack)
        present(viewController, animated: true)
    }

}

private extension AppLockType {

    var needsToSetUpCustomPasscode: Bool {
        let isCustomPasscodeRequired = config.useBiometricsOrCustomPasscode
        return config.forceAppLock && isCustomPasscodeRequired && isCustomPasscodeNotSet
    }

}
