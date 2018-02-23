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


class GroupDetailsSectionHeader: UICollectionReusableView {
    
    let titleLabel = UILabel()
 
    var variant: ColorSchemeVariant = .light {
        didSet {
            guard oldValue != variant else { return }
            configureColors()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        createConstraints()
        configureColors()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        titleLabel.font = FontSpec(.small, .semibold).font!
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.numberOfLines = 0
        addSubview(titleLabel)
    }
    
    private func createConstraints() {
        NSLayoutConstraint.activate([
            titleLabel.heightAnchor.constraint(equalToConstant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 24),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
        ])
    }
    
    private func configureColors() {
        titleLabel.textColor = UIColor.wr_color(fromColorScheme: ColorSchemeColorSectionText, variant: variant)
    }
    
}
