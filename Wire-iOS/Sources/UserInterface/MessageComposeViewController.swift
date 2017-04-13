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

protocol MessageComposeViewControllerDelegate: class {
    func composeViewController(_ controller: MessageComposeViewController, wantsToSendDraft: MessageDraft)
}


final class MessageComposeViewController: UIViewController {

    weak var delegate: MessageComposeViewControllerDelegate?

    private let topContainer = UIView()
    private let subjectImageContainer = UIView()
    private let subjectImageView = UIImageView()
    private let subjectTextField = UITextField()
    private let subjectSeparator = UIView()
    private let messageTextView = UITextView()
    private let color = ColorScheme.default().color(withName:)
    private let sendButtonView = DraftSendInputAccessoryView()

    private var draft: MessageDraft?

    required init(draft: MessageDraft?) {
        self.draft = draft
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        createConstraints()
        loadDraft()
    }

    private func setupViews() {
        title = "compose.drafts.compose.title".localized.uppercased()
        navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
        navigationItem.leftItemsSupplementBackButton = true

        subjectImageView.image = UIImage(
            for: .hamburger,
            iconSize: .tiny,
            color: color(ColorSchemeColorTextForeground)
        )

        subjectSeparator.backgroundColor = color(ColorSchemeColorSeparator)
        subjectTextField.textColor = color(ColorSchemeColorTextForeground)
        let placeholder = "compose.drafts.compose.subject.placeholder".localized.uppercased()
        subjectTextField.attributedPlaceholder = placeholder && color(ColorSchemeColorSeparator) && FontSpec(.normal, .none).font!
        view.backgroundColor = color(ColorSchemeColorBackground)
        messageTextView.textColor = color(ColorSchemeColorTextForeground)
        messageTextView.backgroundColor = .clear
        messageTextView.font = FontSpec(.normal, .none).font!
        messageTextView.contentInset = UIEdgeInsetsMake(16, 0, 16, 0)
        messageTextView.textContainerInset = .zero
        messageTextView.textContainer.lineFragmentPadding = 0

        messageTextView.indicatorStyle = ColorScheme.default().indicatorStyle

        subjectImageContainer.addSubview(subjectImageView)
        [topContainer, messageTextView, sendButtonView].forEach(view.addSubview)
        [subjectImageContainer, subjectTextField, subjectSeparator].forEach(topContainer.addSubview)

        setupInputAccessoryView()
    }

    private func setupInputAccessoryView() {
        sendButtonView.onSend = { [unowned self] in
            self.delegate?.composeViewController(self, wantsToSendDraft: self.draft!)
        }

        sendButtonView.onDelete = {
            // TODO
        }
    }

    private dynamic func dismissViewController() {
        dismiss(animated: true, completion: nil)
    }

    private func createConstraints() {
        constrain(view, topContainer, messageTextView, subjectTextField, sendButtonView) { view, topContainer, messageTextView, subjectTextField, sendButtonView in
            topContainer.leading == view.leading
            topContainer.trailing == view.trailing
            topContainer.top == view.top
            topContainer.height == 60

            messageTextView.top == topContainer.bottom
            messageTextView.leading == subjectTextField.leading
            messageTextView.trailing == view.trailing - 16
            messageTextView.bottom == sendButtonView.top

            sendButtonView.leading == view.leading
            sendButtonView.trailing == view.trailing
            sendButtonView.bottom == view.bottom
        }

        constrain(topContainer, subjectImageContainer, subjectTextField, subjectSeparator) { container, imageContainer, textField, separator in
            separator.bottom == container.bottom
            separator.leading == container.leading
            separator.trailing == container.trailing
            separator.height == .hairline

            imageContainer.leading == container.leading
            imageContainer.centerY == container.centerY
            imageContainer.width == 60

            textField.leading == imageContainer.trailing
            textField.trailing == container.trailing
            textField.centerY == container.centerY
        }

        constrain(subjectImageContainer, subjectImageView) { imageContainer, image in
            image.center == imageContainer.center
        }
    }


    private func loadDraft() {
        subjectTextField.text = draft?.subject
        messageTextView.text = draft?.message
    }

}
