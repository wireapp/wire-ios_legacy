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

final class ToggleCell: UITableViewCell, CellConfigurationConfigurable {
    private let topContainer = UIView()
    private let titleLabel = UILabel()
    private let toggle = UISwitch()
    private let subtitleLabel = UILabel()
    private var action: ((Bool) -> Void)?
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
        [titleLabel, toggle].forEach(topContainer.addSubview)
        [topContainer, subtitleLabel].forEach(contentView.addSubview)
        toggle.addTarget(self, action: #selector(toggleChanged), for: .valueChanged)
        subtitleLabel.numberOfLines = 0
    }
    
    private func createConstraints() {
        constrain(topContainer, titleLabel, toggle) { topContainer, titleLabel, toggle in
            toggle.centerY == topContainer.centerY
            toggle.trailing == topContainer.trailing - 16
            titleLabel.centerY == topContainer.centerY
            titleLabel.leading == topContainer.leading + 16
        }
        constrain(contentView, topContainer, subtitleLabel) { contentView, topContainer, subtitleLabel in
            topContainer.top == contentView.top
            topContainer.leading == contentView.leading
            topContainer.trailing == contentView.trailing
            topContainer.height == 44
            
            subtitleLabel.leading == contentView.leading + 16
            subtitleLabel.trailing == contentView.trailing - 16
            subtitleLabel.top == topContainer.bottom + 8
            subtitleLabel.bottom == contentView.bottom - 8
        }
    }
    
    private func styleViews() {
        func color(_ name: String) -> UIColor {
            return ColorScheme.default().color(withName: name, variant: variant)
        }
        topContainer.backgroundColor = color(ColorSchemeColorBackground)
        titleLabel.textColor = color(ColorSchemeColorTextForeground)
        subtitleLabel.textColor = color(ColorSchemeColorTextDimmed)
    }
    
    @objc private func toggleChanged(_ sender: UISwitch) {
        action?(sender.isOn)
    }
    
    func configure(with configuration: CellConfiguration, variant: ColorSchemeVariant) {
        guard case let .toggle(title, get, set) = configuration else { preconditionFailure() }
        textLabel?.text = title
        action = set
        toggle.isOn = get()
        self.variant = variant
    }
}
