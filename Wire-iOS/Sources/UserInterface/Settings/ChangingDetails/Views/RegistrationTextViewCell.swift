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

import UIKit
import Cartography

protocol RegistrationTextFieldCellDelegate: class {
    func tableViewCellDidChangeText(cell: RegistrationTextFieldCell, text: String)
}

final class RegistrationTextFieldCell: UITableViewCell {
    
    let textField: RegistrationTextField = {
        let textField = RegistrationTextField()

        textField.font = .normalFont
        textField.textColor = .from(scheme: .textForeground, variant: .dark)
        textField.backgroundColor = .clear

        return textField
    }()
    weak var delegate: RegistrationTextFieldCellDelegate?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        setupViews()
        createConstraints()

        backgroundColor = .clear
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews() {
        addSubview(textField)
        textField.addTarget(self, action: #selector(editingChanged), for: .editingChanged)
    }
    
    func createConstraints() {
        constrain(self, textField) { view, emailTextField in
            emailTextField.top == view.top
            emailTextField.bottom == view.bottom
            emailTextField.trailing == view.trailing - 8
            emailTextField.leading == view.leading + 8
        }
    }
    
    @objc func editingChanged(textField: UITextField) {
        let lowercase = textField.text?.lowercased() ?? ""
        let noSpaces = lowercase.components(separatedBy: .whitespacesAndNewlines).joined()
        textField.text = noSpaces
        delegate?.tableViewCellDidChangeText(cell: self, text: noSpaces)
    }
}
