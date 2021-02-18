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
import LocalAuthentication
import WireDataModel

extension AppLockModule {

    final class Interactor: InteractorInterface {

        // MARK: - Properties

        weak var presenter: AppLockPresenterInteractorInterface!

        private let session: Session
        private let authenticationType: AuthenticationTypeProvider

        let dispatchGroup = DispatchGroup()

        /// The message to display on the OS authentication screen.

        private let deviceAuthenticationDescription = {
            "self.settings.privacy_security.lock_app.description".localized
        }()

        // MARK: - Life cycle

        init(session: Session, authenticationType: AuthenticationTypeProvider = AuthenticationTypeDetector()) {
            self.session = session
            self.authenticationType = authenticationType
        }

        // MARK: - Methods

        private var appLock: AppLockType {
            session.appLockController
        }

        private var passcodePreference: PasscodePreference? {
            guard let lock = session.lock else { return nil }

            switch lock {
            case .screen where appLock.requireCustomPasscode:
                return .customOnly
            case .screen:
                return .deviceThenCustom
            case .database:
                return .deviceOnly
            }
        }

        private var needsToNotifyUser: Bool {
            return appLock.needsToNotifyUser
        }

        private var needsToCreateCustomPasscode: Bool {
            guard !appLock.isCustomPasscodeSet else { return false }
            return appLock.requireCustomPasscode || authenticationType.current == .unavailable
        }

    }

}

// MARK: - Execute request

extension AppLockModule.Interactor: AppLockInteractorPresenterInterface {

    func executeRequest(_ request: AppLockModule.Request) {
        switch request {
        case .initiateAuthentication where needsToCreateCustomPasscode:
            presenter.handleResult(.customPasscodeCreationNeeded(shouldInform: needsToNotifyUser))

        case .initiateAuthentication:
            presenter.handleResult(.readyForAuthentication(shouldInform: needsToNotifyUser))

        case .evaluateAuthentication:
            guard let preference = passcodePreference else {
                handleAuthenticationResult(.granted, context: nil)
                return
            }

            appLock.evaluateAuthentication(
                passcodePreference: preference,
                description: deviceAuthenticationDescription,
                callback: handleAuthenticationResult
            )

        case .openAppLock:
            openAppLock()
        }
    }

    private func handleAuthenticationResult(_ result: AppLockModule.AuthenticationResult, context: LAContextProtocol?) {
        DispatchQueue.main.async(group: dispatchGroup) { [weak self] in
            guard let `self` = self else { return }

            switch result {
            case .granted:
                self.unlockDatabase(with: context)
                self.openAppLock()

            case .denied:
                self.presenter.handleResult(.authenticationDenied(self.authenticationType.current))

            case .needCustomPasscode:
                self.presenter.handleResult(.customPasscodeNeeded)

            case .unavailable:
                self.presenter.handleResult(.authenticationUnavailable)
            }
        }
    }

    private func unlockDatabase(with context: LAContextProtocol?) {
        guard let context = context as? LAContext else { return }
        try? session.unlockDatabase(with: context)
    }

    private func openAppLock() {
        try? appLock.open()
    }

}
