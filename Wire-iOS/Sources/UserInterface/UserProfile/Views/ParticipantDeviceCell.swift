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

final class ParticipantDeviceCell: UITableViewCell {

    private var nameLabel: UILabel?
    private var boldFingerprintFont: UIFont?
    private var fingerprintFont: UIFont?
    private var identifierLabel: UILabel?
    private var trustLevelImageView: UIImageView?

    init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = UIColor.clear
        selectionStyle = EKCalendarChooserSelectionStyle(rawValue: UITableViewCell.SelectionStyle.none.rawValue)
        accessoryType = .disclosureIndicator
        createViews()
        setupConstraints()
        setupStyle()
    }

    private func createViews() {
        nameLabel = UILabel()
        contentView.addSubview(nameLabel)

        identifierLabel = UILabel()
        contentView.addSubview(identifierLabel)

        trustLevelImageView = UIImageView()
        trustLevelImageView.contentMode = .scaleAspectFit
        trustLevelImageView.clipsToBounds = true
        contentView.addSubview(trustLevelImageView)
    }

    private func setupConstraints() {
        trustLevelImageView.autoSetDimensions(toSize: CGSize(width: 16, height: 16))
        trustLevelImageView.autoPinEdge(toSuperviewEdge: ALEdgeLeading, withInset: 24)
        trustLevelImageView.autoAlignAxis(ALAxisHorizontal, toSameAxisOfView: nameLabel)

        nameLabel.autoPinEdge(toSuperviewEdge: ALEdgeTop, withInset: 16)
        nameLabel.autoPinEdge(ALEdgeLeading, toEdge: ALEdgeTrailing, ofView: trustLevelImageView, withOffset: 16)

        identifierLabel.autoPinEdge(ALEdgeLeading, toEdge: ALEdgeLeading, ofView: nameLabel)
        identifierLabel.autoPinEdge(ALEdgeTop, toEdge: ALEdgeBottom, ofView: nameLabel, withOffset: 0, relation: NSLayoutConstraint.Relation.greaterThanOrEqual)
        identifierLabel.autoPinEdge(toSuperviewEdge: ALEdgeBottom, withInset: 16)
    }

    private func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        backgroundColor = highlighted ? UIColor(white: 0, alpha: 0.08) : UIColor.clear
    }

    // MARK: - Configuration

    func configure(for client: UserClient?) {
        let attributes = [
                          NSAttributedString.Key.font: fingerprintFont.monospaced
                          ]
        let boldAttributes = [
                              NSAttributedString.Key.font: boldFingerprintFont.monospaced
                              ]
        identifierLabel.attributedText = client?.attributedRemoteIdentifier(attributes, boldAttributes: boldAttributes, uppercase: true)
        nameLabel.text = client?.deviceClass.uppercased() ?? client?.type.uppercased()
        trustLevelImageView.image = client?.verified != nil ? WireStyleKit.imageOfShieldverified : WireStyleKit.imageOfShieldnotverified
    }

    private func setupStyle() {
        boldFingerprintFont = .smallSemiboldFont
        fingerprintFont = .smallFont

        nameLabel.textColor = .from(scheme: .textForeground)
        nameLabel.font = .smallSemiboldFont

        identifierLabel.textColor = .from(scheme: .textForeground)
    }
}
