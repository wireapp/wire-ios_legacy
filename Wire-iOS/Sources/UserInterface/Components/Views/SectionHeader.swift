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
import UIKit
import WireCommonComponents

final class SectionHeaderView: UIView, Themeable {

    let titleLabel = DynamicFontLabel(fontSpec: .smallSemiboldFont, color: .sectionText)

    @objc dynamic var colorSchemeVariant: ColorSchemeVariant = ColorScheme.default.variant {
        didSet {
            guard oldValue != colorSchemeVariant else { return }
            applyColorScheme(colorSchemeVariant)
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        createConstraints()
        applyColorScheme(colorSchemeVariant)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.numberOfLines = 0
        titleLabel.accessibilityTraits.insert(.header)
        addSubview(titleLabel)
    }

    private func createConstraints() {
        NSLayoutConstraint.activate([
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 24),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])
    }

    func applyColorScheme(_ colorSchemeVariant: ColorSchemeVariant) {
        titleLabel.textColor = UIColor.from(scheme: .sectionText, variant: colorSchemeVariant)
    }

}

class SectionHeader: UICollectionReusableView, Themeable {

    let headerView = SectionHeaderView()

    var titleLabel: UILabel {
        return headerView.titleLabel
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(headerView)
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.fitInSuperview()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init?(coder aDecoder: NSCoder) is not implemented")
    }

    @objc dynamic var colorSchemeVariant: ColorSchemeVariant = ColorScheme.default.variant {
        didSet {
            guard oldValue != colorSchemeVariant else { return }
            applyColorScheme(colorSchemeVariant)
        }
    }

    func applyColorScheme(_ colorSchemeVariant: ColorSchemeVariant) {
        headerView.applyColorScheme(colorSchemeVariant)
    }

}

class SectionTableHeader: UITableViewHeaderFooterView, Themeable {

    let headerView = SectionHeaderView()

    var titleLabel: UILabel {
        return headerView.titleLabel
    }

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        contentView.addSubview(headerView)
        createConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init?(coder aDecoder: NSCoder) is not implemented")
    }

    private func createConstraints() {
        headerView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            headerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            headerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            headerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            headerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    @objc dynamic var colorSchemeVariant: ColorSchemeVariant = ColorScheme.default.variant {
        didSet {
            guard oldValue != colorSchemeVariant else { return }
            applyColorScheme(colorSchemeVariant)
        }
    }

    func applyColorScheme(_ colorSchemeVariant: ColorSchemeVariant) {
        headerView.applyColorScheme(colorSchemeVariant)
    }

}
