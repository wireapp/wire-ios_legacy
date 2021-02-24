//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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
import WireSyncEngine

final class DotView: UIView {
    
    fileprivate let circleView = ShapeView()
    fileprivate let centerView = ShapeView()
    private var userObserver: NSObjectProtocol!
    private var clientsObserverTokens: [NSObjectProtocol] = []
    private let user: ZMUser?
    public var hasUnreadMessages: Bool = false {
        didSet { self.updateIndicator() }
    }
    
    var showIndicator: Bool {
        set { self.isHidden = !newValue }
        get { return !self.isHidden }
    }
    
    init(user: ZMUser? = nil) {
        self.user = user
        super.init(frame: .zero)
        self.isHidden = true
        
        circleView.pathGenerator = {
            return UIBezierPath(ovalIn: CGRect(origin: .zero, size: $0))
        }
        circleView.hostedLayer.lineWidth = 0
        circleView.hostedLayer.fillColor = UIColor.white.cgColor
        
        centerView.pathGenerator = {
            return UIBezierPath(ovalIn: CGRect(origin: .zero, size: $0))
        }
        centerView.hostedLayer.fillColor = UIColor.accent().cgColor
        
        addSubview(circleView)
        addSubview(centerView)
        constrain(self, circleView, centerView) { selfView, backingView, centerView in
            backingView.edges == selfView.edges
            centerView.edges == inset(selfView.edges, 1, 1, 1, 1)
        }
        
        if let userSession = ZMUserSession.shared(), let user = user {
            userObserver = UserChangeInfo.add(observer: self, for: user, in: userSession)
        }
        
        self.createClientObservers()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func createClientObservers() {
        guard let user = user else { return }
        clientsObserverTokens = user.clients.map { UserClientChangeInfo.add(observer: self, for: $0) }
    }
    
    func updateIndicator() {
        showIndicator = hasUnreadMessages ||
                        user?.clientsRequiringUserAttention.count > 0 ||
                        user?.readReceiptsEnabledChangedRemotely == true
    }
}

extension DotView: ZMUserObserver {
    func userDidChange(_ changeInfo: UserChangeInfo) {
        
        guard changeInfo.trustLevelChanged ||
              changeInfo.clientsChanged ||
              changeInfo.accentColorValueChanged ||
              changeInfo.readReceiptsEnabledChanged ||
              changeInfo.readReceiptsEnabledChangedRemotelyChanged else { return }
        
        centerView.hostedLayer.fillColor = UIColor.accent().cgColor
        
        updateIndicator()
        
        if changeInfo.clientsChanged {
            createClientObservers()
        }
    }
}

// MARK: - Clients observer

extension DotView: UserClientObserver {
    func userClientDidChange(_ changeInfo: UserClientChangeInfo) {
        guard changeInfo.needsToNotifyUserChanged else { return }
        updateIndicator()
    }
}


