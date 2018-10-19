//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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


import UIKit

@objcMembers class ClientUnregisterFlowViewController: UIViewController, AuthenticationCoordinatedViewController {
    var popTransition: PopTransition?
    var pushTransition: PushTransition?
    var rootNavigationController: NavigationController?

    var authenticationCoordinator: AuthenticationCoordinator?

    let clients: Array<UserClient>
    let credentials: ZMEmailCredentials?
    
    required init(clientsList: Array<UserClient>!, credentials: ZMEmailCredentials?) {
        self.clients = clientsList
        self.credentials = credentials
        super.init(nibName: nil, bundle: nil)
    }
    
    required override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        fatalError("init(nibNameOrNil:nibBundleOrNil:) has not been implemented")
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.popTransition = PopTransition()
        self.pushTransition = PushTransition()
    
        UIView.performWithoutAnimation {            
            self.setupNavigationController()
            self.createConstraints()
            self.view?.isOpaque = false
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.dismiss(animated: animated, completion: nil)
    }

    override var prefersStatusBarHidden: Bool {
        return false
    }

    fileprivate func setupNavigationController() {
        let invitationController = ClientUnregisterInvitationViewController()
        invitationController.delegate = self
        invitationController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        let rootNavigationController = NavigationController(rootViewController: invitationController)
        rootNavigationController.delegate = self
        rootNavigationController.view.translatesAutoresizingMaskIntoConstraints = false
        rootNavigationController.setNavigationBarHidden(true, animated: false)
        rootNavigationController.navigationBar.barStyle = UIBarStyle.black
        rootNavigationController.navigationBar.isTranslucent = true
        rootNavigationController.navigationBar.tintColor = UIColor.accent()
        rootNavigationController.backButtonEnabled = false
        rootNavigationController.rightButtonEnabled = false
        self.addChild(rootNavigationController)
        self.view.addSubview(rootNavigationController.view)
        rootNavigationController.didMove(toParent: self)
        rootNavigationController.setNavigationBarHidden(true, animated: false)
        self.rootNavigationController = rootNavigationController
    }
    
    fileprivate func createConstraints() {
        guard let rootNavigationController = rootNavigationController else {
            return
        }

        rootNavigationController.view.translatesAutoresizingMaskIntoConstraints = true

        let constraints: [NSLayoutConstraint] = [
            rootNavigationController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            rootNavigationController.view.topAnchor.constraint(equalTo: view.topAnchor),
            rootNavigationController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            rootNavigationController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ]

        NSLayoutConstraint.activate(constraints)
    }

}

// MARK: - UINavigationControllerDelegate

extension ClientUnregisterFlowViewController: UINavigationControllerDelegate {

    func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        switch operation {
        case .pop:
            return self.popTransition
        case .push:
            return self.pushTransition
        default:
            return nil
        }
    }
    
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        if viewController is ClientListViewController {
            UIApplication.shared.wr_setStatusBarHidden(!UIScreen.hasNotch, with: animated ? .fade : .none)
            navigationController.setNavigationBarHidden(false, animated: animated)
        }
        else {
            UIApplication.shared.wr_setStatusBarHidden(true, with: animated ? .fade : .none)
            navigationController.setNavigationBarHidden(true, animated: animated)
        }
    }

}

// MARK: - ClientUnregisterInvitationViewControllerDelegate

extension ClientUnregisterFlowViewController: ClientUnregisterInvitationViewControllerDelegate {

    func userDidAcceptClientUnregisterInvitation() {
        let clientsListController = ClientListViewController(clientsList: self.clients,
                                                             credentials: self.credentials,
                                                             showTemporary: false,
                                                             variant: .dark)
        clientsListController.delegate = self

        if isIPadRegular() {
            let navigationController = UINavigationController(rootViewController: clientsListController)
            navigationController.modalPresentationStyle = UIModalPresentationStyle.formSheet
            self.present(navigationController, animated: true, completion: nil)
        } else {
            self.rootNavigationController?.pushViewController(clientsListController, animated: true)
        }
    }

}

// MARK: - ClientListViewControllerDelegate

extension ClientUnregisterFlowViewController: ClientListViewControllerDelegate {
    func finishedDeleting(_ clientListViewController: ClientListViewController) {

        let completion: (() -> Swift.Void)? = { [weak self] in
            self?.authenticationCoordinator?.executeAction(.showLoadingView)
        }

        if isIPadRegular() {
            clientListViewController.dismiss(animated: true, completion: completion)
        } else {
            rootNavigationController?.popViewController(animated: true, completion: completion)
        }
    }
}
