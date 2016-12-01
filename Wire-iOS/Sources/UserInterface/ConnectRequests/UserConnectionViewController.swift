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


import Foundation

@objc public enum UserConnectionAction: UInt {
    case ignore, accept, cancelConnection, block
}

final public class UserConnectionViewController: UIViewController {
    fileprivate var userConnectionView: UserConnectionView!
    fileprivate var recentSearchToken: ZMCommonContactsSearchToken!


    public let userSession: ZMUserSession
    public let user: ZMUser
    public var onAction: ((UserConnectionAction)->())?
    public var showUserName: Bool = false {
        didSet {
            guard let userConnectionView = self.userConnectionView else {
                return
            }
            
            userConnectionView.showUserName = self.showUserName
        }
    }
    
    public init(userSession: ZMUserSession, user: ZMUser) {
        self.userSession = userSession
        self.user = user
        super.init(nibName: .none, bundle: .none)
        
        if self.user.totalCommonConnections == 0  && !self.user.isConnected {
            self.recentSearchToken = self.user.searchCommonContacts(in: self.userSession, with: self)
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func loadView() {
        self.userConnectionView = UserConnectionView(user: self.user)
        self.userConnectionView.showUserName = self.showUserName
        self.userConnectionView.commonConnectionsCount = self.user.totalCommonConnections
        self.userConnectionView.onAccept = { [weak self] user in
            
            guard let `self` = self else {
                return
            }
            
            self.userSession.performChanges {
                self.user.accept()
            }
            self.onAction?(.accept)
        }
        self.userConnectionView.onIgnore = { [weak self] user in
            guard let `self` = self else {
                return
            }
            
            self.userSession.performChanges {
                self.user.ignore()
            }
            
            self.onAction?(.ignore)
        }
        self.userConnectionView.onBlock = { [weak self] user in
            guard let `self` = self else {
                return
            }
            
            self.userSession.performChanges {
                self.user.block()
            }
            self.onAction?(.block)
        }
        self.userConnectionView.onCancelConnection = { [weak self] user in
            guard let `self` = self else {
                return
            }
            
            self.userSession.performChanges {
                self.user.cancelConnectionRequest()
            }
            self.onAction?(.cancelConnection)
        }
        
        self.view = self.userConnectionView
    }
}

extension UserConnectionViewController: ZMCommonContactsSearchDelegate {
    
    public func didReceiveCommonContactsUsers(_ users: NSOrderedSet!, for searchToken: ZMCommonContactsSearchToken!) {
        self.userConnectionView.commonConnectionsCount = UInt(users.count)
    }
}
