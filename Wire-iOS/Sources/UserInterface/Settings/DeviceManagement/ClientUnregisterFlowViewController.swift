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
        self.authToken = ZMUserSession.sharedSession().addAuthenticationObserver(self)
    }
    
    required override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        fatalError("init(nibNameOrNil:nibBundleOrNil:) has not been implemented")
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        if let token = self.authToken {
            ZMUserSession.sharedSession().removeAuthenticationObserverForToken(token)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.popTransition = PopTransition()
        self.pushTransition = PushTransition()
    
        self.setupBackgroundImageView()
        
        self.setupNavigationController()
        
        self.createConstraints()
    
        self.view?.opaque = false
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.dismissViewControllerAnimated(animated, completion: nil)
    }
    
    private func setupBackgroundImageView() {
        let backgroundImageView = UIImageView(image: UIImage(named: "LaunchImage"))
        self.backgroundImageView = backgroundImageView
        self.view?.addSubview(backgroundImageView)
    }
    
    private func setupNavigationController() {
        let invitationController = ClientUnregisterInvitationViewController()
        invitationController.formStepDelegate = self
        invitationController.view.autoresizingMask = [UIViewAutoresizing.FlexibleWidth, UIViewAutoresizing.FlexibleHeight]
        
        let rootNavigationController = NavigationController(rootViewController: invitationController)
        rootNavigationController.delegate = self
        rootNavigationController.view.translatesAutoresizingMaskIntoConstraints = false
        rootNavigationController.setNavigationBarHidden(true, animated: false)
        rootNavigationController.navigationBar.barStyle = UIBarStyle.Default
        rootNavigationController.navigationBar.tintColor = UIColor.accentColor()
        rootNavigationController.backButtonEnabled = false
        rootNavigationController.rightButtonEnabled = false
        self.addChildViewController(rootNavigationController)
        self.view.addSubview(rootNavigationController.view)
        rootNavigationController.didMoveToParentViewController(self)
        rootNavigationController.setNavigationBarHidden(true, animated: false)
        self.rootNavigationController = rootNavigationController
    }
    
    private func createConstraints() {
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
    
    func didCompleteFormStep(viewController: UIViewController!) {
        let clientsListController = ClientListViewController(clientsList: self.clients, credentials: self.credentials)
        clientsListController.view.backgroundColor = UIColor.blackColor()
        if self.traitCollection.userInterfaceIdiom == .Pad {
            let navigationController = UINavigationController(rootViewController: clientsListController)
            navigationController.modalPresentationStyle = UIModalPresentationStyle.FormSheet
            self.presentViewController(navigationController, animated: true, completion: nil)
        } else {
            self.rootNavigationController?.pushViewController(clientsListController, animated: true)
        }
    }
    
    // MARK: - UINavigationControllerDelegate
    
    override func navigationController(navigationController: UINavigationController, animationControllerForOperation operation: UINavigationControllerOperation, fromViewController fromVC: UIViewController, toViewController toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        switch operation {
        case .Pop:
            return self.popTransition
        case .Push:
            return self.pushTransition
        default:
            return nil
        }
    }
    
    override func navigationController(navigationController: UINavigationController, willShowViewController viewController: UIViewController, animated: Bool) {
        if viewController is ClientListViewController {
            navigationController.setNavigationBarHidden(false, animated: false)
        }
        else {
            navigationController.setNavigationBarHidden(true, animated: animated)
        }
    }
    

}
