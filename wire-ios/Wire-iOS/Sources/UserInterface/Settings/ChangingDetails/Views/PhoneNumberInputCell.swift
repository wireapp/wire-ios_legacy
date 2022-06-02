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

class PhoneNumberInputCell: UITableViewCell {

    let phoneInputView: PhoneNumberInputView = {
        let inputView = PhoneNumberInputView()
        inputView.showConfirmButton = false
        inputView.tintColor = .white
        return inputView
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        setupViews()
        createConstraints()

        backgroundColor = .clear
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        addSubview(phoneInputView)
    }

    private func createConstraints() {
        phoneInputView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            phoneInputView.leadingAnchor.constraint(equalTo: leadingAnchor),
            phoneInputView.trailingAnchor.constraint(equalTo: trailingAnchor),
            phoneInputView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            phoneInputView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 8)
        ])
    }

}
