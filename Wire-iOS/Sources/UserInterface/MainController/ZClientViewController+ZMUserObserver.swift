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

extension ZClientViewController: ZMUserObserver {
    public func userDidChange(_ changeInfo: UserChangeInfo) {
        guard let userSession = ZMUserSession.shared() else { return }

        if changeInfo.legalHoldStatusChanged,
            ZMUser.selfUser().hasLegalHoldRequest {
            presentLegalHoldActivatedAlert(){ password in
                userSession.acceptLegalHold(password: password){ [weak self] error in
                    if error != nil {
                        self?.presentAlertWithOKButton(title: "legalhold_request.alert.title".localized,
                                                       message: "legalhold_request.alert.error".localized)
                    }
                }
            }

        } else if !ZMUser.selfUser().isUnderLegalHold {
            // presentLegalHoldDeactivatedAlert()
        }

        if changeInfo.accentColorValueChanged {
            UIApplication.shared.keyWindow?.tintColor = UIColor.accent()
        }
    }

    @objc
    func setupUserChangeInfoObserver() {
        guard let userSession = ZMUserSession.shared() else { return }
        userObserverToken = UserChangeInfo.add(userObserver:self, for: ZMUser.selfUser(), userSession: userSession)
    }
}
