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
            case .screen where appLock.requiresBiometrics:
                return .customOnly
            case .screen:
                return .deviceThenCustom
            case .database:
                return .deviceOnly
            }
        }

    }

}

// MARK: - API for presenter

extension AppLockModule.Interactor: AppLockInteractorPresenterInterface {

    var needsToWarnUserOfConfigurationChange: Bool {
        return appLock.needsToNotifyUser
    }

    // FIXME: This could be more clearly expressed.

    var needsToCreateCustomPasscode: Bool {
        guard appLock.isCustomPasscodeNotSet else { return false }
        return appLock.requiresBiometrics || currentAuthenticationType == .unavailable
    }

    var currentAuthenticationType: AuthenticationType {
        return authenticationType.current
    }

    func evaluateAuthentication() {
        guard let preference = passcodePreference else {
            handleAuthenticationResult(.granted, context: nil)
            return
        }

        appLock.evaluateAuthentication(passcodePreference: preference,
                                       description: deviceAuthenticationDescription,
                                       callback: handleAuthenticationResult)
    }

    private func handleAuthenticationResult(_ result: AppLockModule.AuthenticationResult, context: LAContextProtocol?) {
        if case .granted = result, let context = context as? LAContext {
            try? session.unlockDatabase(with: context)
        }

        presenter.authenticationEvaluated(with: result)
    }

    func openAppLock() {
        try? appLock.open()
    }

}
