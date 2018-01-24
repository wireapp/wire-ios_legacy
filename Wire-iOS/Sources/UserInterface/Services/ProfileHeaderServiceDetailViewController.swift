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

import UIKit
import Cartography

final class ProfileHeaderServiceDetailViewController: UIViewController {

    public weak var navigationControllerDelegate: ProfileNavigationControllerDelegate?
//    public weak var profileViewControllerDelegate: ProfileViewControllerDelegate? ///FIXME: better name

    var headerView: ProfileHeaderView!
    var serviceDetailViewController: ServiceDetailViewController!

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(serviceUser: ServiceUser) {
        super.init(nibName: nil, bundle: nil)

        setupHeader()
        setupServiceDetailViewController(serviceUser: serviceUser)

        self.navigationController?.delegate = self.navigationControllerDelegate
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        createConstraints()
    }

    private func createConstraints() {
        constrain(view) { view in
            ///TODO: create view constraints
        }
    }

    func setupHeader() {
        var headerStyle: ProfileHeaderStyle = .cancelButton
        if UIDevice.current.userInterfaceIdiom == .pad {
            if navigationController?.viewControllers.count > 1 {
                headerStyle = .backButton
            }
        }
        headerView = ProfileHeaderView(with: headerStyle)

        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.dismissButton.addTarget(self, action: #selector(self.dismissButtonClicked), for: .touchUpInside)
        view.addSubview(headerView)
    }

    func dismissButtonClicked() {
        ///FIXME: need dismissal? back is enough for first release
//        requestDismissal(withCompletion: nil)
    }

//    func requestDismissal(withCompletion completion: (() -> ())?) {
//        if (profileViewControllerDelegate?.responds(to: #selector(ProfileViewControllerDelegate.profileViewControllerWants(toBeDismissed:completion:))))! {
//            profileViewControllerDelegate?.profileViewControllerWants(toBeDismissed: self, completion: completion)
//        }
//    }

    func setupServiceDetailViewController(serviceUser: ServiceUser) {
        let confirmButton = Button(style: .full)
        confirmButton.setTitle("participants.services.remove_integration.button".localized, for: .normal)
        confirmButton.setBackgroundImageColor(.red, for: .normal)

        let serviceDetail = ServiceDetailViewController(serviceUser: serviceUser,
                                                        backgroundColor: self.view.backgroundColor,
                                                        textColor: .black, ///FIXME: ask for design
            confirmButton: confirmButton)

        self.add(serviceDetailViewController, to: self.view)

        serviceDetailViewController = serviceDetail

        ///TODO: inject a remove block
        //            public var completion: ((ZMConversation?)->())? = nil // TODO: not wired up yet
        //            serviceDetail.completion = {(_ conversation: ZMConversation) -> () in
        ///TODO: remove from conversation
        //            }

        //            serviceDetail.navigationControllerDelegate = navigationControllerDelegate
    }
}

// MARK: - iPad size class switchin
/*
extension ProfileHeaderServiceDetailViewController {

    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        ///TODO: change the UI config, constraints, font size and etc here if this VC has different UI design pattern on iPad compact/regular mode
    }

    ///Notice: this method is called if this VC is a root VC. it is not called after iPad orientation changes
    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        ///TODO: handle UI update related to view size changes
    }

}
*/
// MARK: - Status Bar / Supported Orientations

extension ProfileHeaderServiceDetailViewController {

//    override var shouldAutorotate: Bool {
//        switch UIDevice.current.userInterfaceIdiom {
//        case .pad:
//
//        switch (self.traitCollection.horizontalSizeClass) {
//        case .compact:
//            ///TODO: if this should auto rotate, return true
//            return false
//        default:
//            return true
//        }
//        default:
//            ///TODO: if this should auto rotate, return true
//            return false
//        }
//    }

//    override var prefersStatusBarHidden: Bool {
//        ///TODO: if this VC does not show status bar, return false
//        return true
//    }
}
