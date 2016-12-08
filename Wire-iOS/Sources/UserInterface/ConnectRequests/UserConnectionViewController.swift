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

@objc public enum IncomingConnectionAction: UInt {
    case ignore, accept
}

final public class IncomingConnectionViewController: UIViewController, ZMCommonContactsSearchDelegate {

    fileprivate var connectionView: IncomingConnectionView!
    fileprivate var recentSearchToken: ZMCommonContactsSearchToken!

    public let userSession: ZMUserSession
    public let user: ZMUser
    public var onAction: ((IncomingConnectionAction) -> ())?

    public init(userSession: ZMUserSession, user: ZMUser) {
        self.userSession = userSession
        self.user = user
        super.init(nibName: .none, bundle: .none)

        guard !self.user.isConnected else { return }
        user.refreshData()
        guard self.user.totalCommonConnections == 0 else { return }
        self.recentSearchToken = self.user.searchCommonContacts(in: self.userSession, with: self)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func loadView() {
        self.connectionView = IncomingConnectionView(user: user)
        self.connectionView.commonConnectionsCount = user.totalCommonConnections
        self.connectionView.onAccept = { [weak self] user in
            guard let `self` = self else { return }
            self.userSession.performChanges {
                self.user.accept()
            }
            self.onAction?(.accept)
        }
        self.connectionView.onIgnore = { [weak self] user in
            guard let `self` = self else { return }
            self.userSession.performChanges {
                self.user.ignore()
            }

            self.onAction?(.ignore)
        }

        view = connectionView
    }

    public func didReceiveCommonContactsUsers(_ users: NSOrderedSet!, for searchToken: ZMCommonContactsSearchToken!) {
        connectionView.commonConnectionsCount = UInt(users.count)
    }

}


final public class UserConnectionViewController: UIViewController, ZMCommonContactsSearchDelegate {

    fileprivate var userConnectionView: UserConnectionView!
    fileprivate var recentSearchToken: ZMCommonContactsSearchToken!

    public let userSession: ZMUserSession
    public let user: ZMUser

    
    public init(userSession: ZMUserSession, user: ZMUser) {
        self.userSession = userSession
        self.user = user
        super.init(nibName: .none, bundle: .none)
        
        guard !self.user.isConnected else { return }
        user.refreshData()
        guard self.user.totalCommonConnections == 0 else { return }
        self.recentSearchToken = self.user.searchCommonContacts(in: self.userSession, with: self)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func loadView() {
        self.userConnectionView = UserConnectionView(user: self.user)
        self.userConnectionView.commonConnectionsCount = self.user.totalCommonConnections
        self.view = self.userConnectionView
    }
    
    public func didReceiveCommonContactsUsers(_ users: NSOrderedSet!, for searchToken: ZMCommonContactsSearchToken!) {
        self.userConnectionView.commonConnectionsCount = UInt(users.count)
    }
}
