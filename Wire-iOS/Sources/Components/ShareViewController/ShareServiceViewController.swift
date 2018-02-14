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
import WireExtensionComponents

class ShareServiceViewController: ShareViewController<ServiceConversation,Service> {
    
    @objc(backButtonTapped:)
    public func backButtonTapped(_ sender: AnyObject!) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc(dismissButtonTapped:)
    public func dismissButtonTapped(_ sender: AnyObject!) {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.title = self.shareable.serviceUser.name
        
        if (self.navigationController?.viewControllers.count ?? 0) > 1 {
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(icon: .backArrow,
                                                                    target: self,
                                                                    action: #selector(ShareServiceViewController.backButtonTapped(_:)))
        }
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(icon: .X,
                                                                 target: self,
                                                                 action: #selector(ShareServiceViewController.dismissButtonTapped(_:)))
        self.navigationItem.rightBarButtonItem?.accessibilityIdentifier = "close"
    }
    
    // MARK: - Actions
    
    public var onServiceDismiss: ((ShareServiceViewController, Bool, AddBotResult?)->())?
    
    override public func onCloseButtonPressed(sender: AnyObject?) {
        self.onServiceDismiss?(self, false, nil)
    }
    
    override public func onSendButtonPressed(sender: AnyObject?) {
        if self.selectedDestinations.count > 0 {
            self.shareable.share(to: Array(self.selectedDestinations), completion: { (result) in
                self.onServiceDismiss?(self, true, result)
            })
        }
    }
}
