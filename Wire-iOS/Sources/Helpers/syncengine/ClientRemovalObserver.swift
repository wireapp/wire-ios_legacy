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
import WireSyncEngine

enum ClientRemovalUIError: Error {
    case noPasswordProvided
}

protocol ClientRemovalObserverDelegate: class {
    func present(_ clientRemovalObserver: ClientRemovalObserver,
                 viewControllerToPresent: UIViewController)
    func setIsLoadingViewVisible(_ clientRemovalObserver: ClientRemovalObserver, isVisible: Bool)
}

final class ClientRemovalObserver: NSObject, ClientUpdateObserver {
    var userClientToDelete: UserClient
    private weak var delegate: ClientRemovalObserverDelegate?
    private let completion: ((Error?) -> Void)?
    private var credentials: ZMEmailCredentials?
    private lazy var requestPasswordController: RequestPasswordController = {
        return RequestPasswordController(context: .removeDevice,
                                         callback: {[weak self] password in
            guard let password = password,
                !password.isEmpty else {
                self?.endRemoval(result: ClientRemovalUIError.noPasswordProvided)
                return
            }

            self?.credentials = ZMEmailCredentials(email: "", password: password)
            self?.startRemoval()
            self?.passwordIsNecessaryForDelete = true
        })
    }()
    private var passwordIsNecessaryForDelete: Bool = false
    private var observerToken: Any?

    init(userClientToDelete: UserClient,
         delegate: ClientRemovalObserverDelegate,
         credentials: ZMEmailCredentials?,
         completion: ((Error?) -> Void)? = nil) {
        self.userClientToDelete = userClientToDelete
        self.delegate = delegate
        self.credentials = credentials
        self.completion = completion

        super.init()

        observerToken = ZMUserSession.shared()?.addClientUpdateObserver(self)
    }

    func startRemoval() {
        delegate?.setIsLoadingViewVisible(self, isVisible: true)
        ZMUserSession.shared()?.deleteClient(userClientToDelete, credentials: credentials)
    }

    private func endRemoval(result: Error?) {
        completion?(result)

        /// allow password input alert can be show next time
        passwordIsNecessaryForDelete = false
    }

    func finishedFetching(_ userClients: [UserClient]) {
        // NO-OP
    }

    func failedToFetchClients(_ error: Error) {
        // NO-OP
    }

    func finishedDeleting(_ remainingClients: [UserClient]) {
        delegate?.setIsLoadingViewVisible(self, isVisible: false)
        endRemoval(result: nil)
    }

    func failedToDeleteClients(_ error: Error) {
        delegate?.setIsLoadingViewVisible(self, isVisible: false)

        if passwordIsNecessaryForDelete {
            let alert = UIAlertController.alertWithOKButton(title: nil,
                                                            message: "self.settings.account_details.remove_device.password.error".localized)

            delegate?.present(self, viewControllerToPresent: alert)
            endRemoval(result: error)
        } else {
            delegate?.present(self, viewControllerToPresent: requestPasswordController.alertController)
        }
    }
}
