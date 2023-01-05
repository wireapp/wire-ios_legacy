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

import UIKit

final class LoadingIndicatorCell: UITableViewCell, CellConfigurationConfigurable {

    private let spinner = ProgressSpinner()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(spinner)
        backgroundColor = .clear
        spinner.hidesWhenStopped = false
        spinner.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
          spinner.topAnchor.constraint(equalTo: contentView.topAnchor),
          spinner.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
          spinner.leftAnchor.constraint(equalTo: contentView.leftAnchor),
          spinner.rightAnchor.constraint(equalTo: contentView.rightAnchor),
          spinner.heightAnchor.constraint(equalToConstant: 120)
        ])
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with configuration: CellConfiguration, variant: ColorSchemeVariant) {
        spinner.color = SemanticColors.Label.textDefault
        spinner.isAnimating = false
        spinner.isAnimating = true
    }

}
