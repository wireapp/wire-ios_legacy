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

enum ClientRemovalUIError: Error {
    case noPasswordProvided
}

final class ClientRemovalObserver: NSObject, ZMClientUpdateObserver {
    var userClientToDelete: UserClient
    private weak var controller: UIViewController?
    let completion: ((Error?)->())?
    var credentials: ZMEmailCredentials?
    private var requestPasswordController: RequestPasswordController?
    private var passwordIsNecessaryForDelete: Bool = false
    private var observerToken: Any?
    
    init(userClientToDelete: UserClient, controller: UIViewController, credentials: ZMEmailCredentials?, completion: ((Error?)->())? = nil) {
        self.userClientToDelete = userClientToDelete
        self.controller = controller
        self.credentials = credentials
        self.completion = completion
        
        super.init()
        
        observerToken = ZMUserSession.shared()?.add(self)
        
        requestPasswordController = RequestPasswordController(context: .removeDevice, callback: {[weak self] (password) in
            guard let password = password, !password.isEmpty else {
                self?.endRemoval(result: ClientRemovalUIError.noPasswordProvided)
                return
            }
            
            self?.credentials = ZMEmailCredentials(email: "", password: password)
            self?.startRemoval()
            self?.passwordIsNecessaryForDelete = true
        })
    }

    func startRemoval() {
        controller?.showLoadingView = true
        ZMUserSession.shared()?.delete(userClientToDelete, with: credentials)
    }
    
    private func endRemoval(result: Error?) {
        completion?(result)
    }
    
    func finishedFetching(_ userClients: [UserClient]) {
        // NO-OP
    }
    
    func failedToFetchClientsWithError(_ error: Error) {
        // NO-OP
    }
    
    func finishedDeleting(_ remainingClients: [UserClient]) {
        controller?.showLoadingView = false
        endRemoval(result: nil)
    }
    
    func failedToDeleteClientsWithError(_ error: Error) {
        controller?.showLoadingView = false

        if !passwordIsNecessaryForDelete {
            guard let requestPasswordController = requestPasswordController else { return }
            controller?.present(requestPasswordController.alertController, animated: true)
        } else {
            controller?.presentAlertWithOKButton(message: "self.settings.account_details.remove_device.password.error".localized)
            endRemoval(result: error)

            /// allow password input alert can be show next time
            passwordIsNecessaryForDelete = false
        }
    }
}
