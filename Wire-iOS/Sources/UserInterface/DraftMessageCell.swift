//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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
import Cartography


final class DraftMessageCell: UITableViewCell {

    static private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.doesRelativeDateFormatting = true
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    private let titleLabel = UILabel()
    private let dateLabel = UILabel()
    private let separator = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        createConstraints()
    }

    private func setupViews() {
        titleLabel.font = FontSpec(.normal, .light).font!
        titleLabel.textColor = UIColor.from(scheme: .textForeground)
        dateLabel.font = FontSpec(.medium, .regular).font!
        dateLabel.textColor = UIColor.from(scheme: .textDimmed)
        backgroundColor = UIColor.from(scheme: .background)
        let selectedView = UIView()
        selectedView.backgroundColor = UIColor.from(scheme: .tokenFieldBackground)
        selectedBackgroundView = selectedView
        separator.backgroundColor = UIColor.from(scheme: .separator)
        [titleLabel, dateLabel, separator].forEach(addSubview)
    }

    private func createConstraints() {
        constrain(self, titleLabel, dateLabel, separator) { view, titleLabel, dateLabel, separator in
            separator.height == .hairline
            separator.leading == view.leading
            separator.trailing == view.trailing
            separator.bottom == view.bottom

            titleLabel.bottom == view.centerY + 2
            dateLabel.top == titleLabel.bottom + 2

            titleLabel.leading == view.leading + 16
            dateLabel.leading == titleLabel.leading
            titleLabel.trailing == view.trailing
            dateLabel.trailing == view.trailing
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with draft: MessageDraft) {
        dateLabel.text = draft.lastModifiedDate.flatMap(DraftMessageCell.dateFormatter.string)
        if let subject = draft.subject, !subject.isEmpty {
            titleLabel.text = subject
        } else {
            titleLabel.text = draft.message
        }
    }

}
