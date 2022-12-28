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
            addSubview(border)
            border.addConstraintsForBorder(for: anchor, borderWidth: borderWidth, to: self)
            border.backgroundColor = color
        }

    private func addConstraintsForBorder(for anchor: Anchor, borderWidth: CGFloat, to parentView: UIView) {
        self.translatesAutoresizingMaskIntoConstraints = false
        switch anchor {
        case .top:
            NSLayoutConstraint.activate([
                self.topAnchor.constraint(equalTo: parentView.topAnchor),
                self.leadingAnchor.constraint(equalTo: parentView.leadingAnchor),
                self.trailingAnchor.constraint(equalTo: parentView.trailingAnchor),
                self.heightAnchor.constraint(equalToConstant: borderWidth)
            ])
        case .bottom:
            NSLayoutConstraint.activate([
                self.bottomAnchor.constraint(equalTo: parentView.bottomAnchor),
                self.leadingAnchor.constraint(equalTo: parentView.leadingAnchor),
                self.trailingAnchor.constraint(equalTo: parentView.trailingAnchor),
                self.heightAnchor.constraint(equalToConstant: borderWidth)
            ])
        case .leading:
            NSLayoutConstraint.activate([
                self.leadingAnchor.constraint(equalTo: parentView.leadingAnchor),
                self.topAnchor.constraint(equalTo: parentView.topAnchor),
                self.bottomAnchor.constraint(equalTo: parentView.bottomAnchor),
                self.widthAnchor.constraint(equalToConstant: borderWidth)
            ])
        case .trailing:
            NSLayoutConstraint.activate([
                self.trailingAnchor.constraint(equalTo: parentView.trailingAnchor),
                self.topAnchor.constraint(equalTo: parentView.topAnchor),
                self.bottomAnchor.constraint(equalTo: parentView.bottomAnchor),
                self.widthAnchor.constraint(equalToConstant: borderWidth)
            ])
        }
    }
}
