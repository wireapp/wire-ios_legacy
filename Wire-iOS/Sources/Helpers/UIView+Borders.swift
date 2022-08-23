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
            guard let frame = getFrame(anchor: anchor, width: borderWidth),
                  let autoresizingMask = getAutoresizingMask(anchor: anchor) else { return }

            let border = UIView()
            border.backgroundColor = color
            border.autoresizingMask = autoresizingMask
            border.frame = frame
            addSubview(border)
        }

    private func getAutoresizingMask(anchor: Anchor) -> UIView.AutoresizingMask? {
        switch anchor {
        case .top:
            return [.flexibleWidth, .flexibleBottomMargin]
        case .bottom:
            return [.flexibleWidth, .flexibleTopMargin]
        case .leading, .trailing:
            return nil
        }
    }

    private func getFrame(anchor: Anchor, width: CGFloat) -> CGRect? {
        switch anchor {
        case .top:
            return CGRect(x: 0, y: 0, width: frame.size.width, height: width)
        case .bottom:
            return CGRect(x: 0, y: frame.size.height, width: frame.size.width, height: width)
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
