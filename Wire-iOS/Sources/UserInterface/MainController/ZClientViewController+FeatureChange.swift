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
    
    var appLock: AppLockType? {
        return _userSession?.appLockController
    }
    
    var changeWarningViewController: AppLockChangeWarningViewController? {
        guard let appLock = appLock else {
            return nil
        }
        
        return AppLockChangeWarningViewController(isAppLockActive: appLock.isActive) {
            try? appLock.deletePasscode()
        }
    }
    
    func notifyUserOfDisabledAppLockIfNeeded() {
        guard 
            let appLock = appLock,
            appLock.needsToNotifyUser,
            !appLock.isActive,
            let warningVC = changeWarningViewController else {
                return
        }
        
        warningVC.modalPresentationStyle = .fullScreen
        present(warningVC, animated: false)
    }
    
}
