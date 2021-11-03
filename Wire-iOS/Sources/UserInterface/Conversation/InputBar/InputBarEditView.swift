//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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

import WireCommonComponents
import UIKit

enum EditButtonType {
    case undo, confirm, cancel
}

protocol InputBarEditViewDelegate: class {
    func inputBarEditView(_ editView: InputBarEditView, didTapButtonWithType buttonType: EditButtonType)
    func inputBarEditViewDidLongPressUndoButton(_ editView: InputBarEditView)
}

final class InputBarEditView: UIView {
    private static var iconButtonTemplate: IconButton {
        let iconButton = IconButton()
        iconButton.setIconColor(.from(scheme: .iconNormal), for: .normal)
        iconButton.setIconColor(.from(scheme: .iconHighlighted), for: .highlighted)

        return iconButton
    }

    let undoButton = InputBarEditView.iconButtonTemplate
    let confirmButton = InputBarEditView.iconButtonTemplate
    let cancelButton = InputBarEditView.iconButtonTemplate
    let iconSize: CGFloat = StyleKitIcon.Size.tiny.rawValue
    private let margin: CGFloat = 16
    private lazy var buttonMargin: CGFloat = margin + iconSize / 2

    weak var delegate: InputBarEditViewDelegate?

    init() {
        super.init(frame: .zero)
        configureViews()
        createConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    fileprivate func configureViews() {
        [undoButton, confirmButton, cancelButton].forEach {
            addSubview($0)
            $0.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        }

        undoButton.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(didLongPressUndoButton)))
        undoButton.setIcon(.undo, size: .tiny, for: [])
        undoButton.accessibilityIdentifier = "undoButton"
        confirmButton.setIcon(.checkmark, size: .medium, for: [])
        confirmButton.accessibilityIdentifier = "confirmButton"
        cancelButton.setIcon(.cross, size: .tiny, for: [])
        cancelButton.accessibilityIdentifier = "cancelButton"
        undoButton.isEnabled = false
        confirmButton.isEnabled = false
    }

    fileprivate func createConstraints() {
        [undoButton, confirmButton, cancelButton].prepareForLayout()
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: undoButton.topAnchor),
            topAnchor.constraint(equalTo: confirmButton.topAnchor),
            topAnchor.constraint(equalTo: cancelButton.topAnchor),

            bottomAnchor.constraint(equalTo: undoButton.bottomAnchor),
            bottomAnchor.constraint(equalTo: confirmButton.bottomAnchor),
            bottomAnchor.constraint(equalTo: cancelButton.bottomAnchor),

            undoButton.centerXAnchor.constraint(equalTo: leadingAnchor, constant: buttonMargin),
            undoButton.widthAnchor.constraint(equalTo: heightAnchor),

            confirmButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            confirmButton.widthAnchor.constraint(equalTo: heightAnchor),
            cancelButton.centerXAnchor.constraint(equalTo: trailingAnchor, constant: -buttonMargin),
            cancelButton.widthAnchor.constraint(equalTo: heightAnchor)
        ])
    }

    @objc func buttonTapped(_ sender: IconButton) {
        let typeBySender = [undoButton: EditButtonType.undo, confirmButton: .confirm, cancelButton: .cancel]
        guard let type = typeBySender[sender] else { return }
        delegate?.inputBarEditView(self, didTapButtonWithType: type)
    }

    @objc func didLongPressUndoButton(_ sender: UILongPressGestureRecognizer) {
        guard sender.state == .began else { return }
        delegate?.inputBarEditViewDidLongPressUndoButton(self)
    }

}
