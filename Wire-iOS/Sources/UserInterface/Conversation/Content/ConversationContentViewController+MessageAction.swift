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

import Foundation

extension ConversationContentViewController {
    // MARK: - EditMessages
    func editLastMessage() {
        if let lastEditableMessage = conversation.lastEditableMessage {
            perform(action: .edit, for: lastEditableMessage, view: tableView)
        }
    }

    func presentDetails(for message: ZMConversationMessage) {
        let isFile = Message.isFileTransfer(message)
        let isImage = Message.isImage(message)
        let isLocation = Message.isLocation(message)

        guard isFile || isImage || isLocation else {
            return
        }

        messagePresenter.open(message, targetView: tableView.targetView(for: message, dataSource: dataSource), actionResponder: self)
    }

    func openSketch(for message: ZMConversationMessage, in editMode: CanvasViewControllerEditMode) {
        let canvasViewController = CanvasViewController()
        if let imageData = message.imageMessageData?.imageData {
            canvasViewController.sketchImage = UIImage(data: imageData)
        }
        canvasViewController.delegate = self
        canvasViewController.title = message.conversation?.displayName.localizedUppercase
        canvasViewController.select(editMode: editMode, animated: false)

        present(canvasViewController.wrapInNavigationController(), animated: true)
    }

    func messageAction(actionId: MessageAction,
                       for message: ZMConversationMessage,
                       view: UIView) {
        switch actionId {
        case .cancel:
            session.enqueue({
                message.fileMessageData?.cancelTransfer()
            })
        case .resend:
            session.enqueue({
                message.resend()
            })
        case .delete:
            assert(message.canBeDeleted)

            deletionDialogPresenter = DeletionDialogPresenter(sourceViewController: presentedViewController ?? self)
            deletionDialogPresenter?.presentDeletionAlertController(forMessage: message, source: view) { deleted in
                if deleted {
                    self.presentedViewController?.dismiss(animated: true)
                }
            }
        case .present:
            dataSource.selectedMessage = message
            presentDetails(for: message)
        case .save:
            if Message.isImage(message) {
                saveImage(from: message, view: view)
            } else {
                dataSource.selectedMessage = message

                let targetView: UIView

                if let selectableView = view as? SelectableView {
                    targetView = selectableView.selectionView
                } else {
                    targetView = view
                }

                if let saveController = UIActivityViewController(message: message, from: targetView) {
                    present(saveController, animated: true)
                }
            }
        case .digitallySign:
            dataSource.selectedMessage = message
            message.isFileDownloaded()
                ? signPDFDocument(for: message, observer: self)
                : presentDownloadNecessaryAlert(for: message)
        case .edit:
            dataSource.editingMessage = message
            delegate?.conversationContentViewController(self, didTriggerEditing: message)
        case .sketchDraw:
            openSketch(for: message, in: .draw)
        case .sketchEmoji:
            openSketch(for: message, in: .emoji)
        case .sketchText:
            // Not implemented yet
            break
        case .like:
            // The new liked state, the value is flipped
            let updatedLikedState = !Message.isLikedMessage(message)
            guard let indexPath = dataSource.topIndexPath(for: message) else { return }

            let selectedMessage = dataSource.selectedMessage

            session.perform({
                Message.setLikedMessage(message, liked: updatedLikedState)
            })

            if updatedLikedState {
                // Deselect if necessary to show list of likers
                if selectedMessage == message {
                    willSelectRow(at: indexPath, tableView: tableView)
                }
            } else {
                // Select if necessary to prevent message from collapsing
                if !(selectedMessage == message) && !Message.hasReactions(message) {
                    willSelectRow(at: indexPath, tableView: tableView)
                    tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
                }
            }
        case .forward:
            showForwardFor(message: message, from: view)
        case .showInConversation:
            scroll(to: message) { cell in
                self.dataSource.highlight(message: message)
            }
        case .copy:
            message.copy(in: .general)
        case .download:
            session.enqueue({
                message.fileMessageData?.requestFileDownload()
            })
        case .reply:
            delegate?.conversationContentViewController(self, didTriggerReplyingTo: message)
        case .openQuote:
            if let quote = message.textMessageData?.quote {
                scroll(to: quote) { cell in
                    self.dataSource.highlight(message: quote)
                }
            }
        case .openDetails:
            let detailsViewController = MessageDetailsViewController(message: message)
            parent?.present(detailsViewController, animated: true)
        }
    }
    
    private func signPDFDocument(for message: ZMConversationMessage,
                                 observer: SignatureObserver) {
        guard let token = message.fileMessageData?.signPDFDocument(observer: observer) else {
            didFailSignature()
            return
        }
        digitalSignatureToken = token
    }
    
    private func presentDownloadNecessaryAlert(for message: ZMConversationMessage) {
        let alertMessage = "digital_signature.alert.download_necessary".localized
        let alertController = UIAlertController(title: "",
                                                message: alertMessage,
                                                preferredStyle: .alert)
        let downloadAction = UIAlertAction(title: "content.message.download".localized,
                                           style: .default) { _ in
                message.fileMessageData?.requestFileDownload()
        }
        
        alertController.addAction(downloadAction)
        present(alertController, animated: true)
    }
}

// MARK: - SignatureObserver
extension ConversationContentViewController: SignatureObserver {
    func willReceiveSignatureURL() {
        showLoadingView = true
    }
    
    func didReceiveSignatureURL(_ url: URL) {
        showLoadingView = false
        presentDigitalSignatureVerification(with: url)
    }
    
    func didReceiveDigitalSignature(_ cmsFileMetadata: ZMFileMetadata) {
        dismissDigitalSignatureVerification(completion: { [weak self] in
            ZMUserSession.shared()?.perform({
                self?.conversation.append(file: cmsFileMetadata)
            })
        })
    }
    
    func didFailSignature() {
        showLoadingView = false
        isDigitalSignatureVerificationShown
            ? dismissDigitalSignatureVerification(completion: { [weak self] in                  self?.presentDigitalSignatureErrorAlert()
            })
            : presentDigitalSignatureErrorAlert()
    }
    
    // MARK: - Helpers
    private func presentDigitalSignatureVerification(with url: URL) {
        let digitalSignatureVerification = DigitalSignatureVerificationViewController(url: url) { [weak self] result in
            switch result {
            case .success:
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) { [weak self] in
                    self?.dataSource.selectedMessage?
                        .fileMessageData?.retrievePDFSignature()
                }
            case .failure:
                self?.dismissDigitalSignatureVerification(completion: {                        self?.presentDigitalSignatureErrorAlert()
                })
            }
        }
        let navigationController = UINavigationController(rootViewController: digitalSignatureVerification)
        present(navigationController, animated: true, completion: { [weak self] in
            self?.isDigitalSignatureVerificationShown =  true
        })
    }
    
    private func presentDigitalSignatureErrorAlert() {
        let message = "\("digital_signature.alert.error".localized) \("general.failure.try_again".localized)"
        let alertController = UIAlertController(title: "",
                                                message: message,
                                                preferredStyle: .alert)
        
        let closeAction = UIAlertAction(title: "general.close".localized,
                                        style: .default)
        
        alertController.addAction(closeAction)
        present(alertController, animated: true)
    }
    
    private func dismissDigitalSignatureVerification(completion: (() -> Void)? = nil) {
        dismiss(animated: true, completion: { [weak self] in
            self?.isDigitalSignatureVerificationShown =  false
            completion?()
        })
    }
}
