//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

@objcMembers
class AudioPlaylistCell: UITableViewCell {
    var titleLabel: UILabel!
    var durationLabel: UILabel!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none
        backgroundColor = .clear

        createViews()
        createConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func createConstraints() {

        [titleLabel,
         durationLabel].forEach{$0.translatesAutoresizingMaskIntoConstraints = false}

        titleLabel.fitInSuperview(exclude: [.trailing])
        durationLabel.fitInSuperview(exclude: [.leading])

        let constraint = titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: durationLabel.leadingAnchor, constant: -8)
        constraint.priority = .defaultHigh

        constraint.isActive = true

        durationLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        titleLabel?.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        updateStyle()
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)

        updateStyle()
    }

    func updateStyle() {
        titleLabel.font = UIFont.smallRegularFont
        titleLabel.textColor = UIColor.from(scheme: .textForeground, variant: .dark)
        durationLabel.textColor = UIColor.from(scheme: .textDimmed, variant: .light)

        if isHighlighted {
            titleLabel.textColor = UIColor.accent()
        } else if isSelected {
            durationLabel.textColor = UIColor.from(scheme: .textForeground, variant: .dark)
            titleLabel.font = UIFont.smallSemiboldFont
        }
    }

    func createViews() {
        titleLabel = UILabel()
        titleLabel.font = UIFont.smallRegularFont
        titleLabel.textColor = UIColor.from(scheme: .textForeground, variant: .dark)
        if let titleLabel = titleLabel {
            contentView.addSubview(titleLabel)
        }

        durationLabel = UILabel()
        durationLabel.font = UIFont.smallRegularFont
        durationLabel.textColor = UIColor.from(scheme: .textDimmed, variant: .light)
        contentView.addSubview(durationLabel)
    }

}

