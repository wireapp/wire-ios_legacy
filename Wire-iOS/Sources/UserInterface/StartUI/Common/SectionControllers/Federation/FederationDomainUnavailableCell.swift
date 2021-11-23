//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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

class FederationDomainUnavailableCell: UICollectionViewCell {

    fileprivate let titleLabel = WebLinkTextView()

    fileprivate var title: String? {
        didSet {
            titleLabel.text = title
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        configureLabel()
        createConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    fileprivate func setupViews() {
        titleLabel.font = FontSpec(.normal, .light).font
        titleLabel.textColor = .white
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.linkTextAttributes = [
            NSAttributedString.Key.underlineStyle: NSUnderlineStyle().rawValue as NSNumber,
            NSAttributedString.Key.foregroundColor: SelfUser.provider?.selfUser.accentColor ?? UIColor.accent()
        ]
        contentView.addSubview(titleLabel)
    }

    fileprivate func configureLabel() {
        let markdownTitle = L10n.Localizable.Peoplepicker.Federation.domainUnvailable(
            URL.wr_support.absoluteString)

        titleLabel.attributedText = .markdown(from: markdownTitle,
                                              style: .search)
    }

    fileprivate func createConstraints() {
        titleLabel.fitInSuperview(with: .init(top: 8, leading: 16, bottom: 8, trailing: 16))
    }

}
