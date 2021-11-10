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

import Foundation
import UIKit
import WireCommonComponents

final class PlaceholderConversationView: UIView {

    var shieldImageView: UIImageView!

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureSubviews()
        configureConstraints()
        configureObservers()
        applyColorScheme(ColorScheme.default.variant)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init?(coder aDecoder: NSCoder) is not implemented")
    }

    private func configureSubviews() {
        let image = WireStyleKit.imageOfShield(color: UIColor(rgb: 0xbac8d1, alpha: 0.24))
        shieldImageView = UIImageView(image: image)
        addSubview(shieldImageView)
    }

    private func configureObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(updateForColorSchemeVariant), name: .SettingsColorSchemeChanged, object: nil)
    }

    private func configureConstraints() {
        shieldImageView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            shieldImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            shieldImageView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    // MARK: - Colors

    @objc
    private func updateForColorSchemeVariant() {
        applyColorScheme(ColorScheme.default.variant)
    }

    func applyColorScheme(_ colorSchemeVariant: ColorSchemeVariant) {
        backgroundColor = UIColor.from(scheme: .background, variant: colorSchemeVariant)
    }

}
