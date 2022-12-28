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

final class ArchivedNavigationBar: UIView {

    typealias NavigationColors = SemanticColors.Label

    let titleLabel: UILabel = {
        let label = DynamicFontLabel(
            fontSpec: .mediumSemiboldFont,
            color: NavigationColors.textDefault
        )
        return label
    }()
    let dismissButton = IconButton()
    private let barHeight: CGFloat = 44
    private let statusbarHeight: CGFloat = 20

    var dismissButtonHandler: (() -> Void)? = .none

    init(title: String) {
        super.init(frame: CGRect.zero)
        titleLabel.text = title
        createViews()
        createConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func createViews() {
        titleLabel.accessibilityTraits.insert(.header)
        dismissButton.setIcon(.cross, size: .tiny, for: [])
        dismissButton.addTarget(self, action: #selector(ArchivedNavigationBar.dismissButtonTapped(_:)), for: .touchUpInside)
        dismissButton.accessibilityIdentifier = "archiveCloseButton"
        dismissButton.accessibilityLabel = "general.close".localized
        dismissButton.setIconColor(NavigationColors.textDefault, for: .normal)
        [titleLabel, dismissButton].forEach(addSubview)
        addBorder(for: .bottom)
    }

    private func createConstraints() {
        [titleLabel, dismissButton].prepareForLayout()
        NSLayoutConstraint.activate([

            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            dismissButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            dismissButton.rightAnchor.constraint(equalTo: rightAnchor, constant: -16),
            dismissButton.leftAnchor.constraint(greaterThanOrEqualTo: titleLabel.rightAnchor, constant: 8),

            heightAnchor.constraint(equalToConstant: barHeight)
        ])
    }

    @objc func dismissButtonTapped(_ sender: IconButton) {
        dismissButtonHandler?()
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: barHeight + statusbarHeight)
    }

}
