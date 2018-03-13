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
import Cartography

final class ActionCell: UITableViewCell, CellConfigurationConfigurable {
    
    private let button = IconButton()
    
    private var variant: ColorSchemeVariant = .light {
        didSet {
            styleViews()
        }
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        createConstraints()
        styleViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        let backgroundView = UIView()
        backgroundView.backgroundColor = .init(white: 0, alpha: 0.08)
        selectedBackgroundView = backgroundView
        button.isUserInteractionEnabled = false
        button.setIcon(.link, with: .tiny, for: .normal)
        button.setIconColor(.init(for: .strongBlue), for: .normal)
        button.setTitleColor(.init(for: .strongBlue), for: .normal)
        button.titleLabel?.font = FontSpec(.normal, .regular).font
        button.titleImageSpacing = 8
        contentView.addSubview(button)
    }
    
    private func createConstraints() {
        constrain(contentView, button) { contentView, button in
            button.edges == contentView.edges
            button.height == 56
        }
    }
    
    private func styleViews() {
        backgroundColor = ColorScheme.default().color(withName: ColorSchemeColorBarBackground, variant: variant)
    }
    
    func configure(with configuration: CellConfiguration, variant: ColorSchemeVariant) {
        guard case let .centerButton(title, identifier, _) = configuration else { preconditionFailure() }
        button.setTitle(title, for: .normal)
        accessibilityIdentifier = identifier
        self.variant = variant
    }
}
