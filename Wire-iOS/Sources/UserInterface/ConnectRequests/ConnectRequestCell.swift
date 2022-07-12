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
import WireSyncEngine

final class ConnectRequestCell: UITableViewCell {

    var acceptBlock: (() -> Void)?
    var ignoreBlock: (() -> Void)?

    private var connectRequestViewController: IncomingConnectionViewController?

    var user: UserType! {
        didSet {
            guard let user = user else { return }

            connectRequestViewController?.view.removeFromSuperview()

            let incomingConnectionViewController = IncomingConnectionViewController(userSession: ZMUserSession.shared(), user: user)

            incomingConnectionViewController.onAction = {[weak self] action in
                switch action {
                case .accept:
                    self?.acceptBlock?()
                case .ignore:
                    self?.ignoreBlock?()
                }
            }

            let view = incomingConnectionViewController.view!

            contentView.addSubview(view)

            view.translatesAutoresizingMaskIntoConstraints = false
            view.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
            view.fitIn(view: contentView)
            view.widthAnchor.constraint(lessThanOrEqualToConstant: 420).isActive = true

            connectRequestViewController = incomingConnectionViewController
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = UIColor.clear
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
