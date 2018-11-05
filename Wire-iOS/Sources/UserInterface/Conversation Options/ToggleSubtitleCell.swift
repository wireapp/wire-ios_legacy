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

final class ToggleSubtitleCell: UITableViewCell, CellConfigurationConfigurable {
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
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
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
        subtitleLabel.font = FontSpec(.medium, .regular).font
        titleLabel.font = FontSpec(.normal, .light).font
        titleLabel.accessibilityIdentifier = "label.guestoptions.description"
        accessibilityElements = [titleLabel, toggle]
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
            topContainer.height == 56
            
            subtitleLabel.leading == contentView.leading + 16
            subtitleLabel.trailing == contentView.trailing - 16
            subtitleLabel.top == topContainer.bottom + 16
            subtitleLabel.bottom == contentView.bottom - 24
        }
    }
    
    private func styleViews() {
        topContainer.backgroundColor = UIColor.from(scheme: .barBackground, variant: variant)
        titleLabel.textColor = UIColor.from(scheme: .textForeground, variant: variant)
        subtitleLabel.textColor = UIColor.from(scheme: .textDimmed, variant: variant)
        backgroundColor = .clear
    }
    
    @objc private func toggleChanged(_ sender: UISwitch) {
        action?(sender.isOn)
    }
    
    func configure(with configuration: CellConfiguration, variant: ColorSchemeVariant) {
        guard case let .toggle(title, subtitle, identifier, get, set) = configuration else { preconditionFailure() }
        titleLabel.text = title
        subtitleLabel.text = subtitle
        action = set
        toggle.accessibilityIdentifier = identifier
        toggle.isOn = get()
        self.variant = variant
    }
}
