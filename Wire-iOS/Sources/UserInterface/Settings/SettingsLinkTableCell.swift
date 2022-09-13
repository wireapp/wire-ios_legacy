//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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
import WireCommonComponents

class SettingsLinkTableCell: SettingsTableCellProtocol {

    // MARK: - Properties

    var cellCopyablelabel = CopyableLabel()

    let cellNameLabel: UILabel = {
        let label = DynamicFontLabel(
            fontSpec: .normalSemiboldFont,
            color: .textForeground)

        label.textColor = SemanticColors.Label.textDefault
        label.numberOfLines = 0
        label.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        label.setContentHuggingPriority(UILayoutPriority.required, for: .horizontal)
        label.adjustsFontSizeToFitWidth = true

        return label
    }()

    var titleText: String = ""

    var preview: SettingsCellPreview = .none

    var icon: StyleKitIcon?

    var descriptor: SettingsCellDescriptorType?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        updateBackgroundColor()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init?(coder aDecoder: NSCoder) is not implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        preview = .none
    }

    fileprivate func setup() {
        backgroundView = UIView()
        selectedBackgroundView = UIView()

        [cellNameLabel, cellCopyablelabel].forEach {
            contentView.addSubview($0)
        }

        cellNameLabel.numberOfLines = 0
        accessibilityTraits = .staticText

        cellCopyablelabel.textColor = SemanticColors.Label.textDefault
        cellCopyablelabel.font = FontSpec(.normal, .light).font
        cellCopyablelabel.lineBreakMode = .byClipping
        cellCopyablelabel.numberOfLines = 0
        accessibilityTraits = .staticText

        createConstraints()
        setupAccessibility()
        backgroundView?.backgroundColor = SemanticColors.View.backgroundDefault
    }

    private func createConstraints() {
        let leadingConstraint = cellNameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16)
        leadingConstraint.priority = .defaultHigh

        [cellNameLabel, cellCopyablelabel].prepareForLayout()

        NSLayoutConstraint.activate([
            leadingConstraint,
            cellNameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            cellNameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cellNameLabel.heightAnchor.constraint(equalToConstant: 32),

            cellCopyablelabel.topAnchor.constraint(equalTo: cellNameLabel.bottomAnchor, constant: 11),
            cellCopyablelabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cellCopyablelabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cellCopyablelabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),

            contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 112)
        ])
    }

    fileprivate func setupAccessibility() {
        isAccessibilityElement = true
        accessibilityTraits = .button
    }

    private func updateBackgroundColor() {
        backgroundColor = SemanticColors.View.backgroundUserCell

        if isHighlighted && selectionStyle != .none {
            backgroundColor = SemanticColors.View.backgroundUserCellHightLighted
        }
    }
//    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
//        super.init(style: style, reuseIdentifier: reuseIdentifier)
//        setup()
//    }
//
//    @available(*, unavailable)
//    required init?(coder aDecoder: NSCoder) {
//        fatalError("init?(coder aDecoder: NSCoder) is not implemented")
//    }
//
//    override func prepareForReuse() {
//        super.prepareForReuse()
//        preview = .none
//    }
//
//    // MARK: - Functions
//
//    override func setup() {
//        backgroundView = UIView()
//        selectedBackgroundView = UIView()
//
//        cellNameLabel.isHidden = true
//
//        [label].forEach { subview in
//            contentView.addSubview(subview)
//        }
//
//        label.textColor = SemanticColors.Label.textDefault
//        label.font = FontSpec(.normal, .light).font
//        label.lineBreakMode = .byClipping
//        label.numberOfLines = 0
//        accessibilityTraits = .staticText
//        backgroundView?.backgroundColor =  SemanticColors.View.backgroundDefault
//
//        createConstraints()
//        setupAccessibility()
//    }
//
//    private func createConstraints() {
//        [label].prepareForLayout()
//
//        NSLayoutConstraint.activate([
//            contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 56)
//        ])
//
//        label.fitIn(view: contentView, insets: UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16))
//    }
}
