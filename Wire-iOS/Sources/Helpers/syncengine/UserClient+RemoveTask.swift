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

    @discardableResult
    func requestPassword(_ completion: @escaping (ZMEmailCredentials?)->()) -> RequestPasswordController {
        let passwordRequest = RequestPasswordController(context: .removeDevice) { (result: Result<String?>) -> () in
            switch result {
            case .success(let passwordString):
                if let email = ZMUser.selfUser()?.emailAddress {

                    if let passwordString = passwordString {
                        let newCredentials = ZMEmailCredentials(email: email, password: passwordString)
                        completion(newCredentials)
                    }
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

        present(passwordRequest.alertController, animated: true)

        return passwordRequest
    }
}

enum ClientRemovalUIError: Error {
    case noPasswordProvided
}

final class ClientRemovalObserver: NSObject, ZMClientUpdateObserver {
    var userClientToDelete: UserClient
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
                ZMUserSession.shared()?.delete(self.userClientToDelete,
                                               with: self.credentials)
                self.controller.showLoadingView = true
            }
            passwordIsNecessaryForDelete = true
        } else {
            controller.presentAlertWithOKButton(title: "", message: "self.settings.account_details.remove_device.password.error".localized)
            endRemoval(result: error)
            
            passwordIsNecessaryForDelete = false
        }
    }
}

///TODO: remove
extension UserClient {
    func remove(over controller: UIViewController, credentials: ZMEmailCredentials?, _ completion: ((Error?)->())? = nil) -> ClientRemovalObserver {
        let removalObserver = ClientRemovalObserver(userClientToDelete: self,
                                                    controller: controller,
                                                    credentials: credentials,
                                                    completion: completion)
        removalObserver.startRemoval()
        
        return removalObserver
    }
}

