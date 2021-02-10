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

import UIKit
import WireSyncEngine

protocol AuthenticatedRouterProtocol: class {
    func updateActiveCallPresentationState()
    func minimizeCallOverlay(animated: Bool, withCompletion completion: Completion?)
}

class AuthenticatedRouter: NSObject {
    
    // MARK: - Private Property
    
    private let builder: AuthenticatedWireFrame
    private let rootViewController: RootViewController
    private let activeCallRouter: ActiveCallRouter
    private weak var _viewController: ZClientViewController?
    
    // MARK: - Public Property

    var viewController: UIViewController {
        let viewController = _viewController ?? builder.build(router: self)
        _viewController = viewController
        return viewController
    }
    
    // MARK: - Init
    
    init(rootViewController: RootViewController,
         account: Account,
         selfUser: SelfUserType,
         isComingFromRegistration: Bool,
         needToShowDataUsagePermissionDialog: Bool) {
        
        self.rootViewController = rootViewController
        activeCallRouter = ActiveCallRouter(rootviewController: rootViewController)
        
        builder = AuthenticatedWireFrame(account: account,
                                         selfUser: selfUser,
                                         isComingFromRegistration: needToShowDataUsagePermissionDialog,
                                         needToShowDataUsagePermissionDialog: needToShowDataUsagePermissionDialog)
    }
}

// MARK: - AuthenticatedRouterProtocol
extension AuthenticatedRouter: AuthenticatedRouterProtocol {
    func updateActiveCallPresentationState() {
        activeCallRouter.updateActiveCallPresentationState()
    }
    
    func minimizeCallOverlay(animated: Bool,
                             withCompletion completion: Completion?) {
        activeCallRouter.minimizeCall(animated: animated, completion: completion)
    }
}

// MARK: - AuthenticatedWireFrame
struct AuthenticatedWireFrame {
    private var account: Account
    private var selfUser: SelfUserType
    private var isComingFromRegistration: Bool
    private var needToShowDataUsagePermissionDialog: Bool
    
    init(account: Account,
         selfUser: SelfUserType,
         isComingFromRegistration: Bool,
         needToShowDataUsagePermissionDialog: Bool) {
        self.account = account
        self.selfUser = selfUser
        self.isComingFromRegistration = isComingFromRegistration
        self.needToShowDataUsagePermissionDialog = needToShowDataUsagePermissionDialog
    }
    
    func build(router: AuthenticatedRouterProtocol) -> ZClientViewController {
        let viewController = ZClientViewController(account: account, selfUser: selfUser)
        viewController.isComingFromRegistration = isComingFromRegistration
        viewController.needToShowDataUsagePermissionDialog = needToShowDataUsagePermissionDialog
        viewController.router =  router
        return viewController
    }
}
