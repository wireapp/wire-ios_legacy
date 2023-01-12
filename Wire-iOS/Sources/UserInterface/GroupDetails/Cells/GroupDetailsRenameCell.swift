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
import UIKit
import WireDataModel
import WireCommonComponents

final class GroupDetailsRenameCell: UICollectionViewCell {

    let verifiedIconView = UIImageView()
    let accessoryIconView = UIImageView()
    let titleTextField = SimpleTextField()
    var contentStackView: UIStackView!

    override init(frame: CGRect) {
        super.init(frame: frame)

        setup()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init?(coder aDecoder: NSCoder) is not implemented")
    }

    fileprivate func setup() {

        verifiedIconView.image = WireStyleKit.imageOfShieldverified
        verifiedIconView.translatesAutoresizingMaskIntoConstraints = false
        verifiedIconView.contentMode = .scaleAspectFit
        verifiedIconView.setContentHuggingPriority(UILayoutPriority.required, for: .horizontal)
        verifiedIconView.setContentCompressionResistancePriority(UILayoutPriority.required, for: .horizontal)
        verifiedIconView.accessibilityIdentifier = "img.shield"

        accessoryIconView.translatesAutoresizingMaskIntoConstraints = false
        accessoryIconView.contentMode = .scaleAspectFit
        accessoryIconView.setContentHuggingPriority(UILayoutPriority.required, for: .horizontal)
        accessoryIconView.setContentCompressionResistancePriority(UILayoutPriority.required, for: .horizontal)

        titleTextField.translatesAutoresizingMaskIntoConstraints = false
        titleTextField.font = FontSpec.init(.normal, .light).font!
        titleTextField.returnKeyType = .done
        titleTextField.backgroundColor = .clear
        titleTextField.textInsets = UIEdgeInsets.zero
        titleTextField.keyboardAppearance = .default

        contentStackView = UIStackView(arrangedSubviews: [verifiedIconView, titleTextField, accessoryIconView])
        contentStackView.axis = .horizontal
        contentStackView.distribution = .fill
        contentStackView.alignment = .center
        contentStackView.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(contentStackView)
        contentStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24).isActive = true
        contentStackView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        contentStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        contentStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16).isActive = true
        contentStackView.spacing = 8

        configureColors()
    }

    func configure(for conversation: GroupDetailsConversationType, editable: Bool) {
        titleTextField.text = conversation.displayName
        verifiedIconView.isHidden = conversation.securityLevel != .secure

        titleTextField.isUserInteractionEnabled = editable
        accessoryIconView.isHidden = !editable
    }

    private func configureColors() {
        backgroundColor = SemanticColors.View.backgroundUserCell
        accessoryIconView.setTemplateIcon(.pencil, size: .tiny)
        accessoryIconView.tintColor = SemanticColors.Icon.foregroundDefault
        titleTextField.textColor = SemanticColors.Label.textDefault
    }

}
