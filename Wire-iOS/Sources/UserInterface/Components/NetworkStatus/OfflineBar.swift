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

import Foundation
import Cartography

enum OfflineBarState {
    case minimized
    case expanded
}

class OfflineBar: UIView {

    private let offlineLabel: UILabel
    private var heightConstraint: NSLayoutConstraint?
    private var _state: OfflineBarState = .minimized

    var state: OfflineBarState {
        set {
            update(state: newValue, animated: false)
        }
        get {
            return _state
        }
    }

    func update(state: OfflineBarState, animated: Bool) {
        guard self.state != state else { return }

        _state = state

        updateViews(animated: animated)
    }

    convenience init() {
        self.init(frame: CGRect.zero)
    }

    override init(frame: CGRect) {
        offlineLabel = UILabel()

        super.init(frame: frame)
        backgroundColor = UIColor(rgb:0xFEBF02, alpha: 1)

        layer.cornerRadius = CGFloat.OfflineBar.cornerRadius
        layer.masksToBounds = true

        offlineLabel.font = FontSpec(FontSize.small, .medium).font
        offlineLabel.textColor = UIColor.white
        offlineLabel.text = "system_status_bar.no_internet.title".localized.uppercased()

        addSubview(offlineLabel)

        createConstraints()
        updateViews(animated: false)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func createConstraints() {
        constrain(self, offlineLabel) { containerView, offlineLabel in
            offlineLabel.center == containerView.center
            offlineLabel.left >= containerView.leftMargin
            offlineLabel.right <= containerView.rightMargin

            heightConstraint = containerView.height == 0
        }
    }

    private func updateViews(animated: Bool = true) {
        heightConstraint?.constant = state == .expanded ? CGFloat.OfflineBar.expandedHeight : 0
        offlineLabel.alpha = state == .expanded ? 1 : 0
        layer.cornerRadius = state == .expanded ? CGFloat.OfflineBar.cornerRadius : CGFloat.SyncBar.cornerRadius
    }

}
