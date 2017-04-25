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
    fileprivate let messageTextView = UITextView()
    private let color = ColorScheme.default().color(withName:)
    private let sendButtonView = DraftSendInputAccessoryView()

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
        navigationController?.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        navigationController?.navigationController?.interactivePopGestureRecognizer?.delegate = self
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
        updateLeftNavigationItem()
        updateRightNavigationItem()
    }

    private lazy var backButton: IconButton = {
        let button = IconButton.iconButtonDefault()
        button.setIcon(.backArrow, with: .tiny, for: .normal)
        button.frame = CGRect(x: 0, y: 0, width: 32, height: 20)
        button.imageEdgeInsets = UIEdgeInsetsMake(0, -26, 0, 0)
        button.accessibilityIdentifier = "back"
        return button
    }()

    private func setupTextView() {
        messageTextView.textColor = color(ColorSchemeColorTextForeground)
        messageTextView.backgroundColor = .clear
        messageTextView.font = FontSpec(.normal, .none).font!
        messageTextView.contentInset = .zero
        messageTextView.textContainerInset = UIEdgeInsetsMake(24, 16, 24, 16)
        messageTextView.textContainer.lineFragmentPadding = 0
        messageTextView.delegate = self
        messageTextView.indicatorStyle = ColorScheme.default().indicatorStyle
        messageTextView.accessibilityLabel = "messageTextField"
    }

    private dynamic func backButtonPressed() {
        navigationController?.navigationController?.popViewController(animated: true)
    }

    private func setupNavigationItem() {
        backButton.addTarget(self, action: #selector(backButtonPressed), for: .touchUpInside)
        subjectTextField.delegate = self
        subjectTextField.textColor = color(ColorSchemeColorTextForeground)
        subjectTextField.tintColor = .accent()
        subjectTextField.textAlignment = .center
        subjectTextField.font = FontSpec(.medium, .semibold).font!
        let placeholder = "compose.drafts.compose.subject.placeholder".localized.uppercased()
        subjectTextField.attributedPlaceholder = placeholder && color(ColorSchemeColorSeparator) && FontSpec(.medium, .semibold).font!
        subjectTextField.bounds = CGRect(x: 0, y: 0, width: 200, height: 44)
        subjectTextField.accessibilityLabel = "subjectTextField"
        subjectTextField.alpha = 0
        navigationItem.titleView = subjectTextField
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        guard traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass else { return }
        updateLeftNavigationItem()
        updateRightNavigationItem()
    }

    private func updateRightNavigationItem() {
        let showItem = traitCollection.horizontalSizeClass == .compact
        navigationItem.rightBarButtonItem = showItem ? UIBarButtonItem(icon: .X, target: self, action: #selector(dismissTapped)) : nil
        navigationItem.rightBarButtonItem?.accessibilityLabel = "closeButton"
    }

    private func updateLeftNavigationItem() {
        let showItem = traitCollection.horizontalSizeClass == .compact
        navigationItem.leftBarButtonItem = showItem ? UIBarButtonItem(customView: backButton) : nil
        navigationItem.leftBarButtonItem?.accessibilityLabel = "backButton"
    }

    private func setupInputAccessoryView() {
        sendButtonView.onSend = { [unowned self] in
            self.delegate?.composeViewController(self, wantsToSendDraft: self.draft!)
        }

        sendButtonView.onDelete = { [weak self] in
            guard let `self` = self else { return }
            let controller = UIAlertController.controllerForDraftDeletion {
                self.persistence.enqueue(
                    block: {
                        self.draft.map($0.delete)
                        self.draft = nil
                }, completion: {
                    self.subjectTextField.text = nil
                    self.messageTextView.text = nil
                    self.updateButtonStates()
                    self.popToListIfNeeded()
                })
            }

            self.present(controller, animated: true, completion: nil)
        }
    }

    private func popToListIfNeeded() {
        if splitViewController?.isCollapsed == true && persistence.numberOfStoredDrafts() > 0 {
           navigationController?.navigationController?.popToRootViewController(animated: true)
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
                if self.hasDraftContent {
                    let (subject, message) = (self.subjectTextField.text?.trimmed, self.messageTextView.text?.trimmed)
                    guard draft.subject != subject || draft.message != message else { return }
                    draft.subject = subject
                    draft.message = message
                    draft.lastModifiedDate = NSDate()
                } else {
                    $0.delete(draft)
                    self.draft = nil
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

    private var hasDraftContent: Bool {
        return subjectTextField.text?.isEmpty == false || messageTextView.text?.isEmpty == false
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

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if range.location == 0 && text == " " && textView.text?.isEmpty ?? true {
            return false
        }

        return true
    }

}


extension MessageComposeViewController: UITextFieldDelegate {

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if range.location == 0 && string == " " && textField.text?.isEmpty ?? true {
            return false
        }

        return true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        messageTextView.becomeFirstResponder()
        return true
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        updateDraft() // No throttling in this case
    }

}


fileprivate extension String {

    var trimmed: String {
        return trimmingCharacters(in: .whitespacesAndNewlines)
    }

}


extension MessageComposeViewController: UIGestureRecognizerDelegate {

    @nonobjc public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return navigationController?.navigationController?.interactivePopGestureRecognizer == gestureRecognizer
            && navigationController?.navigationController?.viewControllers.count > 1
    }
}
