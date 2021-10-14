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

final class AccountSelectorView: UIView {
    weak var delegate: AccountSelectorViewDelegate?

    private var selfUserObserverToken: NSObjectProtocol!
    private var applicationDidBecomeActiveToken: NSObjectProtocol!

    fileprivate var accounts: [Account]? = nil {
        didSet {
            guard ZMUserSession.shared() != nil else {
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

            lineView.arrangedSubviews.forEach { $0.removeFromSuperview() }

            accountViews.forEach {
                lineView.addArrangedSubview($0)
            }
            topOffsetConstraint.constant = imagesCollapsed ? -20 : 0
            accountViews.forEach { $0.collapsed = imagesCollapsed }
        }
    }

    private var accountViews: [BaseAccountView] = []
    private lazy var lineView: UIStackView = {
        let view = UIStackView(axis: .horizontal)
        view.spacing = 6
        view.translatesAutoresizingMaskIntoConstraints = false

        return view
    }()

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

        addSubview(lineView)

        topOffsetConstraint = lineView.centerYAnchor.constraint(equalTo: centerYAnchor)

        NSLayoutConstraint.activate([
            topOffsetConstraint,
            lineView.leadingAnchor.constraint(equalTo: leadingAnchor),
            lineView.trailingAnchor.constraint(equalTo: trailingAnchor),
            lineView.heightAnchor.constraint(equalTo: heightAnchor)
        ])

        applicationDidBecomeActiveToken = NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: nil, using: { [weak self] _ in
            self?.updateAccounts()
        })

        updateAccounts()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    fileprivate func updateAccounts() {
        accounts = SessionManager.shared?.accountManager.accounts
    }
}

private extension Account {
    var isActive: Bool {
        return SessionManager.shared?.accountManager.selectedAccount == self
    }
}
