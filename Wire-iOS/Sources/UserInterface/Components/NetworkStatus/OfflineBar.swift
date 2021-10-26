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

class OfflineBar: UIView {

    private let offlineLabel: UILabel
    private var heightConstraint: NSLayoutConstraint?

    var state: NetworkStatusViewState = .online {
        didSet {
            if oldValue != state {
                updateView()
            }
        }
    }

    convenience init() {
        self.init(frame: CGRect.zero)
    }

    override init(frame: CGRect) {
        offlineLabel = UILabel()

        super.init(frame: frame)
        backgroundColor = UIColor(rgb: 0xFEBF02, alpha: 1)

        layer.cornerRadius = CGFloat.OfflineBar.cornerRadius
        layer.masksToBounds = true

        offlineLabel.font = FontSpec(FontSize.small, .medium).font
        offlineLabel.textColor = UIColor.white
        offlineLabel.text = "system_status_bar.no_internet.title".localized(uppercased: true)

        addSubview(offlineLabel)

        createConstraints()
        updateView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func createConstraints() {
        [<#views#>].prepareForLayout()
        NSLayoutConstraint.activate([
          offlineLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
          offlineLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
          offlineLabel.leftAnchor.constraint(greaterThanOrEqualTo: containerView.leftMarginAnchor),
          offlineLabel.rightAnchor.constraint(lessThanOrEqualTo: containerView.rightMarginAnchor),

          heightConstraint = containerView.heightAnchor.constraint(equalToConstant: 0)
        ])
    }

    private func updateView() {
        switch state {
        case .online:
            heightConstraint?.constant = 0
            offlineLabel.alpha = 0
            layer.cornerRadius = 0
        case .onlineSynchronizing:
            heightConstraint?.constant = CGFloat.SyncBar.height
            offlineLabel.alpha = 0
            layer.cornerRadius = CGFloat.SyncBar.cornerRadius
        case .offlineExpanded:
            heightConstraint?.constant = CGFloat.OfflineBar.expandedHeight
            offlineLabel.alpha = 1
            layer.cornerRadius = CGFloat.OfflineBar.cornerRadius
        }
    }
}
