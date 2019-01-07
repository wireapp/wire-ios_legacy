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

protocol ClientUnregisterInvitationViewControllerDelegate: class {
    /// Called when the user tapped the button to unregister clients.
    func userDidAcceptClientUnregisterInvitation()
}

class ClientUnregisterInvitationViewController: UIViewController {
    var heroLabel : UILabel?
    var subtitleLabel : UILabel?
    var manageDevicesButton : UIButton?
    var signOutButton : UIButton?
    var containerView : UIView?

    weak var delegate: ClientUnregisterInvitationViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        self.createContainerView()
        self.createHeroLabel()
        self.createSubtitleLabel()
        self.createDeleteDevicesButton()
        self.createSignOutButton()
        self.createConstraints()
        
        // Layout first to avoid the initial layout animation during the presentation.
        self.view.layoutIfNeeded()
    }
    
    fileprivate func createContainerView() {
        let view = UIView()
        self.containerView = view
        self.view?.addSubview(view)
    }
  
    fileprivate func createHeroLabel() {
        let heroLabel = UILabel()
        heroLabel.translatesAutoresizingMaskIntoConstraints = false
        heroLabel.font = FontSpec(.large, .semibold).font!
        heroLabel.textColor = UIColor.from(scheme: .textForeground, variant: .dark)
        heroLabel.numberOfLines = 0
        heroLabel.text = String(format:NSLocalizedString("registration.signin.too_many_devices.title", comment:""), ZMUser.selfUser().displayName)
        
        self.heroLabel = heroLabel
        self.containerView?.addSubview(heroLabel)
    }
    
    fileprivate func createSubtitleLabel() {
        let subtitleLabel = UILabel()
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.font = FontSpec(.large, .light).font!
        subtitleLabel.textColor = UIColor.from(scheme: .textForeground, variant: .dark)
        subtitleLabel.numberOfLines = 0
        subtitleLabel.text = NSLocalizedString("registration.signin.too_many_devices.subtitle", comment:"")
        
        self.subtitleLabel = subtitleLabel
        self.containerView?.addSubview(subtitleLabel)
    }
    
    fileprivate func createDeleteDevicesButton() {
        let manageDevicesButton = Button(style: .fullMonochrome)
        manageDevicesButton.setTitle(NSLocalizedString("registration.signin.too_many_devices.manage_button.title", comment:""), for: [])
        manageDevicesButton.addTarget(self, action: #selector(ClientUnregisterInvitationViewController.openManageDevices(_:)), for: .touchUpInside)
        self.manageDevicesButton = manageDevicesButton
        self.containerView?.addSubview(manageDevicesButton)
    }
    
    fileprivate func createSignOutButton() {
        
        let signOutButton = Button(style: .emptyMonochrome)
        signOutButton.setTitle(NSLocalizedString("registration.signin.too_many_devices.sign_out_button.title", comment:""), for: [])
        signOutButton.addTarget(self, action: #selector(ClientUnregisterInvitationViewController.signOut(_:)), for: .touchUpInside)
        signOutButton.isHidden = true // for the moment not supported
        self.signOutButton = signOutButton
        self.containerView?.addSubview(signOutButton)
    }
    
    fileprivate func createConstraints() {
        if let containerView = self.containerView,
            let subtitleLabel = self.subtitleLabel,
            let heroLabel = self.heroLabel,
            let manageDevicesButton = self.manageDevicesButton,
            let signOutButton = self.signOutButton {
            
            constrain(self.view, containerView) { selfView, containerView in
                containerView.edges == selfView.edges ~ 900
                containerView.width <= 414
                containerView.height <= 736
                containerView.center == selfView.center
            }
            
            constrain(containerView, subtitleLabel, heroLabel) { containerView, subtitleLabel, heroLabel in
                heroLabel.left == containerView.left + 28
                heroLabel.right == containerView.right - 28
                subtitleLabel.left == containerView.left + 28
                subtitleLabel.right == containerView.right - 28
                subtitleLabel.top == heroLabel.bottom
            }
            
            constrain(subtitleLabel, manageDevicesButton) { subtitleLabel, manageDevicesButton in
                manageDevicesButton.top == subtitleLabel.bottom + 24
            }
            
            constrain(containerView, manageDevicesButton, signOutButton) { containerView, manageDevicesButton, signOutButton in
                manageDevicesButton.left == containerView.left + 24
                manageDevicesButton.right == containerView.right - 24
                manageDevicesButton.bottom == signOutButton.top - 24
                manageDevicesButton.height == 40
                
                signOutButton.left == containerView.left + 24
                signOutButton.right == containerView.right - 24
                signOutButton.bottom == containerView.bottom
                signOutButton.height == 0
            }
        }
    }
    
    // MARK: - Actions
    
    @objc func openManageDevices(_ sender : UIButton!) {
        delegate?.userDidAcceptClientUnregisterInvitation()
    }
    
    @objc func signOut(_ sender : UIButton!) {
        // for the moment not supported
    }
}
