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
import Cartography

@objc protocol ClientUnregisterViewControllerDelegate: NSObjectProtocol {
    func clientDeletionSucceeded()
}


class ClientUnregisterFlowViewController: FormFlowViewController, FormStepDelegate, ZMAuthenticationObserver {
    var popTransition: PopTransition?
    var pushTransition: PushTransition?
    var rootNavigationController: NavigationController?
    var backgroundImageView: UIImageView?
    weak var delegate: ClientUnregisterViewControllerDelegate?
    var authToken: ZMAuthenticationObserverToken?
    
    let clients: Array<UserClient>
    let credentials: ZMEmailCredentials?
    
    required init(clientsList: Array<UserClient>!, delegate: ClientUnregisterViewControllerDelegate, credentials: ZMEmailCredentials?) {
        self.clients = clientsList
        self.credentials = credentials
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
        self.authToken = ZMUserSessionAuthenticationNotification.addObserver(self)
    }
    
    required override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        fatalError("init(nibNameOrNil:nibBundleOrNil:) has not been implemented")
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        if let token = self.authToken {
            ZMUserSessionAuthenticationNotification.removeObserver(for: token)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.popTransition = PopTransition()
        self.pushTransition = PushTransition()
    
        UIView.performWithoutAnimation {            
            self.setupBackgroundImageView()
            
            self.setupNavigationController()
            
            self.createConstraints()
            
            self.view?.isOpaque = false
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.dismiss(animated: animated, completion: nil)
    }
    
    fileprivate func setupBackgroundImageView() {
        let backgroundImageView = UIImageView(image: UIImage(named: "LaunchImage"))
        self.backgroundImageView = backgroundImageView
        self.view?.addSubview(backgroundImageView)
    }
    
    fileprivate func setupNavigationController() {
        let invitationController = ClientUnregisterInvitationViewController()
        invitationController.formStepDelegate = self
        invitationController.view.autoresizingMask = [UIViewAutoresizing.flexibleWidth, UIViewAutoresizing.flexibleHeight]
        
        let rootNavigationController = NavigationController(rootViewController: invitationController)
        rootNavigationController.delegate = self
        rootNavigationController.view.translatesAutoresizingMaskIntoConstraints = false
        rootNavigationController.setNavigationBarHidden(true, animated: false)
        rootNavigationController.navigationBar.barStyle = UIBarStyle.default
        rootNavigationController.navigationBar.tintColor = UIColor.accent()
        rootNavigationController.backButtonEnabled = false
        rootNavigationController.rightButtonEnabled = false
        self.addChildViewController(rootNavigationController)
        self.view.addSubview(rootNavigationController.view)
        rootNavigationController.didMove(toParentViewController: self)
        rootNavigationController.setNavigationBarHidden(true, animated: false)
        self.rootNavigationController = rootNavigationController
    }
    
    fileprivate func createConstraints() {
        if let rootNavigationController = self.rootNavigationController {
            constrain(self.view, rootNavigationController.view) { selfView, navigationControllerView in
                navigationControllerView.edges == selfView.edges
            }
        }
        
        if let backgroundImageView = self.backgroundImageView {
            constrain(self.view, backgroundImageView) { selfView, backgroundImageView in
                backgroundImageView.edges == selfView.edges
            }
        }
    }

    // MARK: - ZMAuthenticationObserver
    
    func authenticationDidSucceed() {
        self.delegate?.clientDeletionSucceeded()
    }
    
    // MARK: - FormStepDelegate
    
    func didCompleteFormStep(_ viewController: UIViewController!) {
        let clientsListController = ClientListViewController(clientsList: self.clients, credentials: self.credentials, showTemporary: false)
        clientsListController.view.backgroundColor = UIColor.black
        if self.traitCollection.userInterfaceIdiom == .pad {
            let navigationController = UINavigationController(rootViewController: clientsListController)
            navigationController.modalPresentationStyle = UIModalPresentationStyle.formSheet
            self.present(navigationController, animated: true, completion: nil)
        } else {
            self.rootNavigationController?.pushViewController(clientsListController, animated: true)
        }
    }
    
    // MARK: - UINavigationControllerDelegate
    
    override func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationControllerOperation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        switch operation {
        case .pop:
            return self.popTransition
        case .push:
            return self.pushTransition
        default:
            return nil
        }
    }
    
    override func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        if viewController is ClientListViewController {
            navigationController.setNavigationBarHidden(false, animated: false)
        }
        else {
            navigationController.setNavigationBarHidden(true, animated: animated)
        }
    }
    

}
