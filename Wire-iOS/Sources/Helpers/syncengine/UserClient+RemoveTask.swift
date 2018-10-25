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

private let zmLog = ZMSLog(tag: "UI")

extension UIViewController {
    
    func displayError(_ message: String) {
        let alert = UIAlertController(title: "", message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: NSLocalizedString("general.ok", comment: ""), style: .default) { [unowned alert] (_) -> Void in
            alert.dismiss(animated: true, completion: .none)
        }
        alert.addAction(action)
        self.present(alert, animated: true, completion: .none)
    }
    
    func requestPassword(_ completion: @escaping (ZMEmailCredentials?)->()) {
        let passwordRequest = RequestPasswordViewController.requestPasswordController() { (result: Result<String>) -> () in
            switch result {
            case .success(let passwordString):
                if let email = ZMUser.selfUser()?.emailAddress {
                    let newCredentials = ZMEmailCredentials(email: email, password: passwordString)
                    completion(newCredentials)
                } else {
                    if DeveloperMenuState.developerMenuEnabled() {
                        DebugAlert.showGeneric(message: "No email set!")
                    }
                    completion(nil)
                }
            case .failure(let error):
                zmLog.error("Error: \(error)")
                completion(nil)
            }
        }
        self.present(passwordRequest, animated: true, completion: .none)
    }
}

enum ClientRemovalUIError: Error {
    case noPasswordProvided
}

private class ClientRemovalObserver: NSObject, ZMClientUpdateObserver {

    private var strongReference: ClientRemovalObserver? = nil
    let userClientToDelete: UserClient
    let controller: UIViewController
    let completion: ((Error?)->())?
    var credentials: ZMEmailCredentials?
    private var passwordIsNecessaryForDelete: Bool = false
    private var observerToken: Any?
    
    init(userClientToDelete: UserClient, controller: UIViewController, credentials: ZMEmailCredentials?, completion: ((Error?)->())? = nil) {
        self.userClientToDelete = userClientToDelete
        self.controller = controller
        self.credentials = credentials
        self.completion = completion
        super.init()
        observerToken = ZMUserSession.shared()?.add(self)
    }
    
    func startRemoval() {
        controller.showLoadingView = true
        ZMUserSession.shared()?.delete(userClientToDelete, with: credentials)
        strongReference = self
    }
    
    private func endRemoval(result: Error?) {
        completion?(result)
        strongReference = nil
    }
    
    func finishedFetching(_ userClients: [UserClient]) {
        // NO-OP
    }
    
    func failedToFetchClientsWithError(_ error: Error) {
        // NO-OP
    }
    
    func finishedDeleting(_ remainingClients: [UserClient]) {
        controller.showLoadingView = false
        endRemoval(result: nil)
    }
    
    func failedToDeleteClientsWithError(_ error: Error) {
        controller.showLoadingView = false

        if !passwordIsNecessaryForDelete {
            controller.requestPassword { newCredentials in
                guard let emailCredentials = newCredentials,
                    emailCredentials.password?.isEmpty == false else {
                    self.endRemoval(result: ClientRemovalUIError.noPasswordProvided)
                    return
                }
                self.credentials = emailCredentials
                ZMUserSession.shared()?.delete(self.userClientToDelete, with: self.credentials)
                self.controller.showLoadingView = true
            }
            passwordIsNecessaryForDelete = true
        }
        else {
            controller.displayError(NSLocalizedString("self.settings.account_details.remove_device.password.error", comment: ""))
            endRemoval(result: error)
        }
    }
}

extension UserClient {
    func remove(over controller: UIViewController, credentials: ZMEmailCredentials?, _ completion: ((Error?)->())? = nil) {
        let removalObserver = ClientRemovalObserver(userClientToDelete: self,
                                                    controller: controller,
                                                    credentials: credentials,
                                                    completion: completion)
        removalObserver.startRemoval()
    }
}
