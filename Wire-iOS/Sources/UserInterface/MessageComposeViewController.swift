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
    func composeViewControllerWantsToDismiss(_ controller: MessageComposeViewController)
}


final class MessageComposeViewController: UIViewController {

    weak var delegate: MessageComposeViewControllerDelegate?

    private let subjectTextField = UITextField()
    private let messageTextView = UITextView()
    private let color = ColorScheme.default().color(withName:)
    private let sendButtonView = DraftSendInputAccessoryView()
    private let dismissItem = UIBarButtonItem(icon: .X, target: self, action: #selector(dismissTapped))

    private var draft: MessageDraft?
    private let persistence: MessageDraftStorage

    required init(draft: MessageDraft?, persistence: MessageDraftStorage = .shared) {
        self.draft = draft
        self.persistence = persistence
        super.init(nibName: nil, bundle: nil)
        loadDraft()
        setupViews()
        createConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        messageTextView.becomeFirstResponder()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(updateDraft), object: nil)
        updateDraft() // We do not want to throttle in this case
    }

    private func setupViews() {
        view.backgroundColor = color(ColorSchemeColorBackground)
        [messageTextView, sendButtonView].forEach(view.addSubview)
        setupInputAccessoryView()
        setupNavigationItem()
        setupTextView()
        updateRightNavigationItem()
    }

    private func setupTextView() {
        messageTextView.textColor = color(ColorSchemeColorTextForeground)
        messageTextView.backgroundColor = .clear
        messageTextView.font = FontSpec(.normal, .none).font!
        messageTextView.contentInset = .zero
        messageTextView.textContainerInset = UIEdgeInsetsMake(24, 16, 24, 16)
        messageTextView.textContainer.lineFragmentPadding = 0
        messageTextView.delegate = self
        messageTextView.indicatorStyle = ColorScheme.default().indicatorStyle
    }

    private func setupNavigationItem() {
        navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
        navigationItem.leftItemsSupplementBackButton = true

        subjectTextField.delegate = self
        subjectTextField.textColor = color(ColorSchemeColorTextForeground)
        subjectTextField.tintColor = .accent()
        subjectTextField.textAlignment = .center
        let placeholder = "compose.drafts.compose.subject.placeholder".localized.uppercased()
        subjectTextField.attributedPlaceholder = placeholder && color(ColorSchemeColorSeparator) && FontSpec(.normal, .none).font!
        subjectTextField.bounds = CGRect(x: 0, y: 0, width: 200, height: 44)
        navigationItem.titleView = subjectTextField
        subjectTextField.alpha = 0
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        guard traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass else { return }
        updateRightNavigationItem()
    }

    private func updateRightNavigationItem() {
        navigationItem.rightBarButtonItem = traitCollection.horizontalSizeClass == .compact ? dismissItem : nil
    }

    private func setupInputAccessoryView() {
        sendButtonView.onSend = { [unowned self] in
            self.delegate?.composeViewController(self, wantsToSendDraft: self.draft!)
        }

        sendButtonView.onDelete = { [weak self] in
            let controller = UIAlertController.controllerForDraftDeletion {
                self?.persistence.enqueue(
                    block: {
                        self?.draft.map($0.delete)
                        self?.draft = nil
                }, completion: {
                    self?.subjectTextField.text = nil
                    self?.messageTextView.text = nil
                })
            }

            self?.present(controller, animated: true, completion: nil)
        }
    }

    fileprivate dynamic func dismissTapped() {
        delegate?.composeViewControllerWantsToDismiss(self)
    }

    fileprivate dynamic func updateDraftThrottled() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(updateDraft), object: nil)
        perform(#selector(updateDraft), with: nil, afterDelay: 0.2)
    }

    fileprivate dynamic func updateDraft() {
        if let draft = draft {
            persistence.enqueue(block: {
                if self.subjectTextField.text?.isEmpty == false || self.messageTextView.text?.isEmpty == false {
                    guard draft.subject != self.subjectTextField.text || draft.message != self.messageTextView.text else { return }
                    draft.subject = self.subjectTextField.text
                    draft.message = self.messageTextView.text
                    draft.lastModifiedDate = NSDate()
                } else {
                    $0.delete(draft)
                }
            }, completion: {
                self.updateButtonStates()
            })
        } else {
            persistence.enqueue(
                block: { self.draft = MessageDraft.insertNewObject(in: $0) },
                completion: { self.updateDraft() }
            )
        }
    }

    private func updateButtonStates() {
        sendButtonView.isEnabled = draft?.canBeSent ?? false
    }

    private func createConstraints() {
        constrain(view, messageTextView, sendButtonView) { view, messageTextView, sendButtonView in
            messageTextView.top == view.top
            messageTextView.leading == view.leading
            messageTextView.trailing == view.trailing
            messageTextView.bottom == sendButtonView.top

            sendButtonView.leading == view.leading
            sendButtonView.trailing == view.trailing
            sendButtonView.bottom == view.bottom
        }
    }

    private func loadDraft() {
        subjectTextField.text = draft?.subject
        messageTextView.text = draft?.message
        updateButtonStates()
    }

}


extension MessageComposeViewController: UITextViewDelegate {

    func textViewDidChange(_ textView: UITextView) {
        updateDraftThrottled()
    }

}

extension MessageComposeViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return false
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        updateDraft() // No throttling in this case
    }

}
