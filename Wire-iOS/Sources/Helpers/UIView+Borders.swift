//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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

extension UIView {

    func addBorder(
        for anchor: Anchor,
        color: UIColor = SemanticColors.View.backgroundSeparatorCell,
        borderWidth: CGFloat = 1.0) {

            let border = UIView()
            guard let constraints = getLayoutConstraint(anchor: anchor, border: border, borderWidth: borderWidth) else { return }

            border.backgroundColor = color
            border.translatesAutoresizingMaskIntoConstraints = false
            addSubview(border)
            NSLayoutConstraint.activate(constraints)
        }

    private func getLayoutConstraint(anchor: Anchor, border: UIView, borderWidth: CGFloat) -> [NSLayoutConstraint]? {
        switch anchor {
        case .top:
            return [
                border.topAnchor.constraint(equalTo: self.topAnchor),
                border.leadingAnchor.constraint(equalTo: self.leadingAnchor),
                border.trailingAnchor.constraint(equalTo: self.trailingAnchor),
                border.heightAnchor.constraint(equalToConstant: borderWidth)
            ]
        case .bottom:
            return [
                border.bottomAnchor.constraint(equalTo: self.bottomAnchor),
                border.leadingAnchor.constraint(equalTo: self.leadingAnchor),
                border.trailingAnchor.constraint(equalTo: self.trailingAnchor),
                border.heightAnchor.constraint(equalToConstant: borderWidth)
            ]
        case .leading, .trailing:
            return nil
        }
    }

    func addBottomBorderWithInset(color: UIColor, inset: CGFloat) {
        let border = UIView()
        let borderWidth: CGFloat = 1.0
        border.backgroundColor = color
        border.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
        border.frame = CGRect(x: 0, y: frame.size.height + inset, width: frame.size.width, height: borderWidth)
        addSubview(border)
    }

    func addBottomBorderWithInset(color: UIColor) {
        let border = UIView()
        let borderWidth: CGFloat = 1.0
        border.backgroundColor = color
        border.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
        border.frame = CGRect(x: 0, y: frame.size.height - borderWidth, width: frame.size.width, height: borderWidth)
        addSubview(border)
    }

}
