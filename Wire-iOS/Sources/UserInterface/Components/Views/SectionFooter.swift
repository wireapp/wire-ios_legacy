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

final class SectionFooterView: UIView, Themeable {

    let titleLabel = UILabel()

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

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        titleLabel.font = .preferredFont(forTextStyle: .footnote)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.numberOfLines = 0
        addSubview(titleLabel)
    }

    private func createConstraints() {
        NSLayoutConstraint.activate([
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            ])
    }

    func applyColorScheme(_ colorSchemeVariant: ColorSchemeVariant) {
        titleLabel.textColor = UIColor.from(scheme: .textDimmed, variant: colorSchemeVariant)
    }

}

final class SectionFooter: UICollectionReusableView, Themeable {

    let footerView = SectionFooterView()

    var titleLabel: UILabel {
        return footerView.titleLabel
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(footerView)
        footerView.translatesAutoresizingMaskIntoConstraints = false
        footerView.fitInSuperview()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        addSubview(footerView)
        footerView.translatesAutoresizingMaskIntoConstraints = false
        footerView.fitInSuperview()
    }

    @objc dynamic var colorSchemeVariant: ColorSchemeVariant = ColorScheme.default.variant {
        didSet {
            guard oldValue != colorSchemeVariant else { return }
            applyColorScheme(colorSchemeVariant)
        }
    }

    func applyColorScheme(_ colorSchemeVariant: ColorSchemeVariant) {
        footerView.applyColorScheme(colorSchemeVariant)
    }

    class func register(collectionView: UICollectionView) {
        collectionView.register(SectionFooter.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: "SectionFooter")
    }
}

class SectionTableFooter: UITableViewHeaderFooterView, Themeable {

    let footerView = SectionFooterView()

    var titleLabel: UILabel {
        return footerView.titleLabel
    }

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        addSubview(footerView)
        footerView.translatesAutoresizingMaskIntoConstraints = false
        footerView.fitInSuperview()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        addSubview(footerView)
        footerView.translatesAutoresizingMaskIntoConstraints = false
        footerView.fitInSuperview()
    }

    @objc dynamic var colorSchemeVariant: ColorSchemeVariant = ColorScheme.default.variant {
        didSet {
            guard oldValue != colorSchemeVariant else { return }
            applyColorScheme(colorSchemeVariant)
        }
    }

    func applyColorScheme(_ colorSchemeVariant: ColorSchemeVariant) {
        footerView.applyColorScheme(colorSchemeVariant)
    }

}
