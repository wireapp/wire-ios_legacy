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
        get {
            return !isHidden
        }

        set {
            isHidden = !newValue
        }
    }

    init(user: ZMUser? = nil) {
        self.user = user
        super.init(frame: .zero)
        isHidden = true

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

        createConstraints()

        if let userSession = ZMUserSession.shared(),
            let user = user {
            userObserver = UserChangeInfo.add(observer: self, for: user, in: userSession)
        }

        createClientObservers()
    }

    private func createConstraints() {
        [self, circleView, centerView].prepareForLayout()

        let centerViewConstraints = centerView.fitInConstraints(view: self, inset: 1)

        NSLayoutConstraint.activate([
            circleView.topAnchor.constraint(equalTo: topAnchor),
            circleView.bottomAnchor.constraint(equalTo: bottomAnchor),
            circleView.leftAnchor.constraint(equalTo: leftAnchor),
            circleView.rightAnchor.constraint(equalTo: rightAnchor)] + centerViewConstraints)
    }

    @available(*, unavailable)
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
