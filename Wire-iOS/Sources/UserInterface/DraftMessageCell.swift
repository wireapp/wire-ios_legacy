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


final class DraftMessageCell: UITableViewCell {

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        textLabel?.font = FontSpec(.normal, .light).font!
        textLabel?.textColor = ColorScheme.default().color(withName: ColorSchemeColorTextForeground)
        detailTextLabel?.font = FontSpec(.medium, .regular).font!
        detailTextLabel?.textColor = ColorScheme.default().color(withName: ColorSchemeColorTextDimmed)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with draft: MessageDraft) {
        if let subject = draft.subject {
            textLabel?.text = "#" + subject
        }
        detailTextLabel?.text = draft.message
    }

}
