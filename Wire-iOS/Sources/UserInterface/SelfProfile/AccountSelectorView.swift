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

protocol AccountSelectorViewDelegate: class {
    func accountSelectorDidSelect(account: Account)
}

class LineView: UIView {
    let views: [UIView]
    private let inset: CGFloat = 6

    init(views: [UIView]) {
        self.views = views
        super.init(frame: .zero)
        layoutViews()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func layoutViews() {

        views.forEach(addSubview)

        guard let first = views.first else {
            return
        }

        let bottomConstraint = first.bottomAnchor.constraint(equalTo: bottomAnchor)
        bottomConstraint.priority = UILayoutPriority(rawValue: 750)
        NSLayoutConstraint.activate([
          first.leadingAnchor.constraint(equalTo: leadingAnchor),
          first.topAnchor.constraint(equalTo: topAnchor),
            bottomConstraint
        ])

        var previous: UIView = first

        var constraints = [NSLayoutConstraint]()
        
        views.dropFirst().forEach { current in
            constraints += [
              current.leadingAnchor.constraint(equalTo: previous.trailingAnchor, constant: inset),
              current.topAnchor.constraint(equalTo: topAnchor),
              current.bottomAnchor.constraint(equalTo: bottomAnchor)
            ]
            previous = current
        }

        if let last = views.last {
            constraints.append(last.trailingAnchor.constraint(equalTo: trailingAnchor))
        }

        NSLayoutConstraint.activate(constraints)
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

            lineView = LineView(views: accountViews)
            topOffsetConstraint.constant = imagesCollapsed ? -20 : 0
            accountViews.forEach { $0.collapsed = imagesCollapsed }
        }
    }

    private var accountViews: [BaseAccountView] = []
    private var lineView: LineView? {
        didSet {
            oldValue?.removeFromSuperview()
            if let newLineView = lineView {
                addSubview(newLineView)

                topOffsetConstraint = newLineView.centerYAnchor.constraint(equalTo: centerYAnchor)

                NSLayoutConstraint.activate([
                topOffsetConstraint,
                    newLineView.leadingAnchor.constraint(equalTo: leadingAnchor),
                    newLineView.trailingAnchor.constraint(equalTo: trailingAnchor),
                    newLineView.heightAnchor.constraint(equalTo: heightAnchor)
                ])
            }
        }
    }
    private var topOffsetConstraint: NSLayoutConstraint!
    var imagesCollapsed: Bool = false {
        didSet {
            topOffsetConstraint.constant = imagesCollapsed ? -20 : 0

            accountViews.forEach { $0.collapsed = imagesCollapsed }

            layoutIfNeeded()
        }
    }

    init() {
        super.init(frame: .zero)

        applicationDidBecomeActiveToken = NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: nil, using: { [weak self] _ in
            self?.update(with: SessionManager.shared?.accountManager.accounts)
        })

        update(with: SessionManager.shared?.accountManager.accounts)
    }

    @available(*, unavailable)
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
