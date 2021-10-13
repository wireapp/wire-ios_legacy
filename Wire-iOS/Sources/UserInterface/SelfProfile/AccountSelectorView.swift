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
import WireDataModel
import WireSyncEngine

protocol AccountSelectorViewDelegate: class {

    func accountSelectorDidSelect(account: Account)

}

class LineView: UIView {
    public let views: [UIView]
    init(views: [UIView]) {
        self.views = views
        super.init(frame: .zero)
        layoutViews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func layoutViews() {

        self.views.forEach(self.addSubview)

        guard let first = self.views.first else {
            return
        }

        let inset: CGFloat = 6

        NSLayoutConstraint.activate([
          first.leadingAnchor.constraint(equalTo: selfView.leadingAnchor),
          first.topAnchor.constraint(equalTo: selfView.topAnchor),
          first.bottomAnchor.constraint(equalTo: selfView.bottomAnchor, constant: ~ 750.0)
        ])

        var previous: UIView = first

        self.views.dropFirst().forEach {
            NSLayoutConstraint.activate([
              current.leadingAnchor.constraint(equalTo: previous.trailingAnchor, constant: inset),
              current.topAnchor.constraint(equalTo: selfView.topAnchor),
              current.bottomAnchor.constraint(equalTo: selfView.bottomAnchor)
            ])
            previous = $0
        }

        guard let last = self.views.last else {
            return
        }

        NSLayoutConstraint.activate([
          last.trailingAnchor.constraint(equalTo: selfView.trailingAnchor)
        ])
    }
}

final class AccountSelectorView: UIView {
    weak var delegate: AccountSelectorViewDelegate?

    private var selfUserObserverToken: NSObjectProtocol!
    private var applicationDidBecomeActiveToken: NSObjectProtocol!

    fileprivate var accounts: [Account]? = nil {
        didSet {
            guard ZMUserSession.shared()  != nil else {
                return
            }

            accountViews = accounts?.map({ AccountViewFactory.viewFor(account: $0, displayContext: .accountSelector) }) ?? []

            accountViews.forEach { (accountView) in

                accountView.unreadCountStyle = accountView.account.isActive ? .none : .current
                accountView.onTap = { [weak self] account in
                    guard let account = account else { return }
                    self?.delegate?.accountSelectorDidSelect(account: account)
                }
            }

            self.lineView = LineView(views: self.accountViews)
            self.topOffsetConstraint.constant = imagesCollapsed ? -20 : 0
            self.accountViews.forEach { $0.collapsed = imagesCollapsed }
        }
    }

    private var accountViews: [BaseAccountView] = []
    private var lineView: LineView? {
        didSet {
            oldValue?.removeFromSuperview()
            if let newLineView = self.lineView {
                self.addSubview(newLineView)

                NSLayoutConstraint.activate([
                  self.topOffsetConstraint = lineView.centerYAnchor.constraint(equalTo: selfView.centerYAnchor),
                  lineView.leadingAnchor.constraint(equalTo: selfView.leadingAnchor),
                  lineView.trailingAnchor.constraint(equalTo: selfView.trailingAnchor),
                  lineView.heightAnchor.constraint(equalTo: selfView.heightAnchor)
                ])
            }
        }
    }
    private var topOffsetConstraint: NSLayoutConstraint!
    public var imagesCollapsed: Bool = false {
        didSet {
            self.topOffsetConstraint.constant = imagesCollapsed ? -20 : 0

            self.accountViews.forEach { $0.collapsed = imagesCollapsed }

            self.layoutIfNeeded()
        }
    }

    init() {
        super.init(frame: .zero)

        applicationDidBecomeActiveToken = NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: nil, using: { [weak self] _ in
            self?.update(with: SessionManager.shared?.accountManager.accounts)
        })

        self.update(with: SessionManager.shared?.accountManager.accounts)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    fileprivate func update(with accounts: [Account]?) {
        self.accounts = accounts
    }

}

private extension Account {

    var isActive: Bool {
        return SessionManager.shared?.accountManager.selectedAccount == self
    }
}
