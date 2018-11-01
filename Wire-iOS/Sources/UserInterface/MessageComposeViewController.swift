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
import Down

protocol MessageComposeViewControllerDelegate: class {
    func composeViewController(_ controller: MessageComposeViewController, wantsToSendDraft: MessageDraft)
    func composeViewControllerWantsToDismiss(_ controller: MessageComposeViewController)
}


final class MessageComposeViewController: UIViewController {

    weak var delegate: MessageComposeViewControllerDelegate?

    private let subjectTextField = UITextField()
    fileprivate let messageTextView = MarkdownTextView()
    private let sendButtonView = DraftSendInputAccessoryView()
    fileprivate let markdownBarView = MarkdownBarView()
    private var bottomEdgeConstraint : NSLayoutConstraint?

    private var draft: MessageDraft?
    private let persistence: MessageDraftStorage

    required init(draft: MessageDraft?, persistence: MessageDraftStorage = .shared) {
        self.draft = draft
        self.persistence = persistence
        super.init(nibName: nil, bundle: nil)
        loadDraft()
        setupViews()
        createConstraints()
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(MessageComposeViewController.keyboardFrameWillChange(_:)),
                                               name: UIResponder.keyboardWillChangeFrameNotification,
                                               object: nil)
        
        NotificationCenter.default.addObserver(markdownBarView,
                                               selector: #selector(markdownBarView.textViewDidChangeActiveMarkdown),
                                               name: Notification.Name.MarkdownTextViewDidChangeActiveMarkdown,
                                               object: messageTextView)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
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
        view.backgroundColor = UIColor.from(scheme: .background)
        [messageTextView, sendButtonView, markdownBarView].forEach(view.addSubview)
        setupInputAccessoryView()
        setupNavigationItem()
        setupTextView()
        updateLeftNavigationItem()
        updateRightNavigationItem()
    }

    private func setupTextView() {
        
        // NB: setting the textContainerInset causes the content size to change
        // drastically when tapping on a white space ¯\_(ツ)_/¯. We simulate
        // textContainerInset = UIEdgeInsetsMake(24, 16, 56, 16) by constraining
        // the text view's leading margin 16 points from the view's margin and
        // setting the scroll views content inset to compensate (accounting for
        // the default text container inset (8,0,8,0))
        
        messageTextView.contentInset = UIEdgeInsets(top: 16, left: 0, bottom: 48, right: -16)
        messageTextView.textContainer.lineFragmentPadding = 0
        messageTextView.backgroundColor = .clear
        messageTextView.delegate = self
        messageTextView.indicatorStyle = ColorScheme.default.indicatorStyle
        messageTextView.accessibilityLabel = "messageTextField"
        messageTextView.keyboardAppearance = ColorScheme.default.keyboardAppearance
        markdownBarView.delegate = messageTextView
    }

    @objc private dynamic func backButtonPressed() {
        navigationController?.navigationController?.popViewController(animated: true)
    }

    private func setupNavigationItem() {
        subjectTextField.delegate = self
        subjectTextField.textColor = UIColor.from(scheme: .textForeground)
        subjectTextField.tintColor = .accent()
        subjectTextField.textAlignment = .center
        subjectTextField.font = FontSpec(.medium, .semibold).font!
        let placeholder = "compose.drafts.compose.subject.placeholder".localized.uppercased()
        subjectTextField.attributedPlaceholder = placeholder && UIColor.from(scheme: .separator) && FontSpec(.medium, .semibold).font!
        subjectTextField.bounds = CGRect(x: 0, y: 0, width: 200, height: 44)
        subjectTextField.accessibilityLabel = "subjectTextField"
        subjectTextField.alpha = 0
        subjectTextField.keyboardAppearance = ColorScheme.default.keyboardAppearance
        navigationItem.titleView = subjectTextField
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        guard traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass else { return }
        updateLeftNavigationItem()
        updateRightNavigationItem()
    }

    private let draftsBackButton = IconButton(style: .default)

    private func updateRightNavigationItem() {
        let showItem = traitCollection.horizontalSizeClass == .compact
        navigationItem.rightBarButtonItem = showItem ? UIBarButtonItem(icon: .X, target: self, action: #selector(dismissTapped)) : nil
        navigationItem.rightBarButtonItem?.accessibilityLabel = "closeButton"
    }

    private func updateLeftNavigationItem() {
        guard traitCollection.horizontalSizeClass == .compact else {
            navigationItem.leftBarButtonItem = nil
            return
        }

        draftsBackButton.setIcon(.compose, with: .tiny, for: .normal)
        draftsBackButton.frame = CGRect(x: 0, y: 0, width: 40, height: 20)
        draftsBackButton.titleLabel?.font = FontSpec(.medium, .semibold).font
        draftsBackButton.setIconColor(UIColor.from(scheme: .textForeground), for: .normal)
        draftsBackButton.setTitleColor(UIColor.from(scheme: .separator), for: .normal)
        draftsBackButton.accessibilityIdentifier = "back"

        let count = persistence.numberOfStoredDrafts()
        if count > 0 {
            draftsBackButton.setTitle(String(count), for: .normal)
        }
        draftsBackButton.titleImageSpacing = 2
        draftsBackButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: -4, bottom: 0, right: 0)
        draftsBackButton.sizeToFit()
        draftsBackButton.addTarget(self, action: #selector(backButtonPressed), for: .touchUpInside)

        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: draftsBackButton)
        navigationItem.leftBarButtonItem?.accessibilityLabel = "backButton"
    }

    private func setupInputAccessoryView() {
        sendButtonView.onSend = { [unowned self] in
            self.delegate?.composeViewController(self, wantsToSendDraft: self.draft!)
        }
    }
    
    private func popToListIfNeeded() {
        if splitViewController?.isCollapsed == true {
           navigationController?.navigationController?.popToRootViewController(animated: true)
        }
    }

    @objc fileprivate dynamic func dismissTapped() {
        
        // if nothing to save/delete, just dismiss
        if !hasDraftContent {
            self.delegate?.composeViewControllerWantsToDismiss(self)
            return
        }
        
        let deleteHandler: () -> Void = {
            self.persistence.enqueue(
                block: {
                    self.draft.map($0.delete)
                    self.draft = nil
            }, completion: {
                self.messageTextView.text = ""
                self.subjectTextField.text = ""
                self.delegate?.composeViewControllerWantsToDismiss(self)
            })
        }
        
        // since draft already saved, just dismiss
        let saveHandler: () -> Void = {
            self.delegate?.composeViewControllerWantsToDismiss(self)
        }
        
        let controller = UIAlertController.controllerForDraftDismiss(deleteHandler: deleteHandler,
                                                                     saveHandler: saveHandler)
        self.present(controller, animated: true, completion: nil)
    }

    @objc fileprivate dynamic func updateDraftThrottled() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(updateDraft), object: nil)
        perform(#selector(updateDraft), with: nil, afterDelay: 0.2)
    }

    @objc fileprivate dynamic func updateDraft() {
        if let draft = draft {
            persistence.enqueue(block: {
                if self.hasDraftContent {
                    let (subject, message) = (self.subjectTextField.text?.trimmed, self.messageTextView.text?.trimmed)
                    let attributedText = self.messageTextView.attributedText.withEncodedMarkdownIDs
                    guard draft.subject != subject || draft.message != message else { return }
                    draft.subject = subject
                    draft.message = message
                    draft.attributedMessage = attributedText
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
        constrain(view, messageTextView, sendButtonView, markdownBarView) { view, messageTextView, sendButtonView, markdownBarView in
            messageTextView.top == view.top
            messageTextView.leading == view.leading + 16
            messageTextView.trailing == view.trailing
            messageTextView.bottom == markdownBarView.top

            sendButtonView.leading == view.leading
            sendButtonView.trailing == view.trailing
            sendButtonView.bottom == markdownBarView.top
            sendButtonView.height == 56

            markdownBarView.leading == view.leading
            markdownBarView.trailing == view.trailing
            self.bottomEdgeConstraint = markdownBarView.bottom == view.bottom - UIScreen.safeArea.bottom
            markdownBarView.height == 56
        }
    }

    private func loadDraft() {
        subjectTextField.text = draft?.subject
        messageTextView.attributedText = draft?.attributedMessage?.withDecodedMarkdownIDs
        updateButtonStates()
    }

    @objc func keyboardFrameWillChange(_ notification: Notification) {
        guard let endSize = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
            return
        }
        UIView.animate(withKeyboardNotification: notification, in: self.view, animations: { (keyboardFrame) in
            let keyboardIsClosed = endSize.origin.y == UIScreen.main.bounds.height
            self.bottomEdgeConstraint?.constant = -(keyboardIsClosed ? UIScreen.safeArea.bottom : 0)
            self.view.layoutIfNeeded()
        }, completion: nil)
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
        
        (textView as? MarkdownTextView)?.respondToChange(text, inRange: range)
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
