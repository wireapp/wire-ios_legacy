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

import UIKit

protocol ViewWithContentView {
    var contentView: UIView { get }
}

extension UICollectionViewCell: ViewWithContentView {}
extension UITableViewCell: ViewWithContentView {}

protocol SeparatorViewProtocol: class {
    var separator: UIView { get }
    var separatorInsetConstraint: NSLayoutConstraint! { get set }
    var separatorLeadingInset: CGFloat { get }
}

extension SeparatorViewProtocol where Self: ViewWithContentView {
    func createSeparatorConstraints() {
        separatorInsetConstraint = separator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor,
                                                                      constant: separatorLeadingInset)

        NSLayoutConstraint.activate([
            separatorInsetConstraint,
            separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            separator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separator.heightAnchor.constraint(equalToConstant: .hairline),
            ])
    }
}
