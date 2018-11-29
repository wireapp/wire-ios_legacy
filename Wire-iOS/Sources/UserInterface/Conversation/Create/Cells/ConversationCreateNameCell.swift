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

class ConversationCreateNameCell: UICollectionViewCell {
    
    let textField = SimpleTextField()
    
    var variant : ColorSchemeVariant = ColorScheme.default.variant {
        didSet {
            guard oldValue != variant else { return }
            configureColors()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    fileprivate func setup() {
        textField.isAccessibilityElement = true
        textField.accessibilityIdentifier = "textfield.newgroup.name"
        textField.placeholder = "conversation.create.group_name.placeholder".localized.uppercased()
        
        // this needs to be the conversation creation vc
        // we could set this from the outside.
        // textField.textFieldDelegate =
        
        contentView.addSubview(textField)
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.fitInSuperview(with: EdgeInsets(top: 0, leading: 24, bottom: 0, trailing: 16))
        
        configureColors()
    }
    
    private func configureColors() {
        backgroundColor = UIColor.from(scheme: .barBackground, variant: variant)
        textField.applyColorScheme(variant)
    }
}
