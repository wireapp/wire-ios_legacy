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

final class StartUIView : UIView { }

extension StartUIViewController {
    private func presentProfileViewController(for bareUser: UserType,
                                              at indexPath: IndexPath?) {
        searchHeaderViewController.tokenField.resignFirstResponder()

        guard let indexPath = indexPath,
            let cell = searchResultsViewController.searchResultsView?.collectionView.cellForItem(at: indexPath) else { return }


        profilePresenter.presentProfileViewController(for: bareUser, in: self, from: view.convert(cell.bounds, from: cell), onDismiss: {
            if self.isIPadRegular(),
                let indexPaths = self.searchResultsViewController.searchResultsView?.collectionView.indexPathsForVisibleItems {
                self.searchResultsViewController.searchResultsView?.collectionView.reloadItems(at: indexPaths)
            } else if self.profilePresenter.keyboardPersistedAfterOpeningProfile {
                    self.searchHeaderViewController.tokenField.becomeFirstResponder()
                    self.profilePresenter.keyboardPersistedAfterOpeningProfile = false
            }
        }, arrowDirection: .left)
    }
}

extension StartUIViewController: SearchResultsViewControllerDelegate {
    public func searchResultsViewController(_ searchResultsViewController: SearchResultsViewController,
                                            didTapOnUser user: UserType,
                                            indexPath: IndexPath,
                                            section: SearchResultsViewControllerSection) {
        
        if !user.isConnected && !user.isTeamMember {
            presentProfileViewController(for: user, at: indexPath)
        } else if let unboxed = user.zmUser {
            delegate?.startUI(self, didSelect: [unboxed])
        }
    }
    
    public func searchResultsViewController(_ searchResultsViewController: SearchResultsViewController,
                                            didDoubleTapOnUser user: UserType,
                                            indexPath: IndexPath) {
    
        guard let unboxedUser = user.zmUser, unboxedUser.isConnected, !unboxedUser.isBlocked else {
            return
        }
        
        delegate?.startUI(self, didSelect: [unboxedUser])
    }
    
    public func searchResultsViewController(_ searchResultsViewController: SearchResultsViewController,
                                            didTapOnConversation conversation: ZMConversation) {
        guard conversation.conversationType == .group || conversation.conversationType == .oneOnOne else { return }

        delegate?.startUI(self, didSelect: conversation)
    }
    
    public func searchResultsViewController(_ searchResultsViewController: SearchResultsViewController,
                                            didTapOnSeviceUser user: ServiceUser) {

        let detail = ServiceDetailViewController(serviceUser: user,
                                                 actionType: .openConversation,
                                                 variant: ServiceDetailVariant(colorScheme: .dark, opaque: false)) { [weak self] result in
            guard let weakSelf = self else { return }

            if let result = result {
                switch result {
                case .success(let conversation):
                    weakSelf.delegate?.startUI(weakSelf, didSelect: conversation)
                case .failure(let error):
                    error.displayAddBotError(in: weakSelf)
                }
            } else {
                weakSelf.navigationController?.dismiss(animated: true, completion: nil)
            }
        }
        
        navigationController?.pushViewController(detail, animated: true)
    }
    
    public func searchResultsViewController(_ searchResultsViewController: SearchResultsViewController,
                                            wantsToPerformAction action: SearchResultsViewControllerAction) {
        switch action {
        case .createGroup:
            openCreateGroupController()
        case .createGuestRoom:
            createGuestRoom()
        }
    }
    
    func openCreateGroupController() {
        let controller = ConversationCreationController()
        controller.delegate = self
        
        if self.traitCollection.horizontalSizeClass == .compact {
            let avoiding = KeyboardAvoidingViewController(viewController: controller)
            self.navigationController?.pushViewController(avoiding, animated: true) {
                UIApplication.shared.wr_updateStatusBarForCurrentControllerAnimated(true)
            }
        }
        else {
            let embeddedNavigationController = controller.wrapInNavigationController()
            embeddedNavigationController.modalPresentationStyle = .formSheet
            self.present(embeddedNavigationController, animated: true)
        }
    }
    
    func createGuestRoom() {
        guard let userSession = ZMUserSession.shared() else {
            fatal("No user session present")
        }
        
        GuestRoomEvent.created.track()
        showLoadingView = true
        userSession.performChanges { [weak self] in
            guard let weakSelf = self else { return }

            if let conversation = ZMConversation.insertGroupConversation(session: userSession,
                                                                      participants: [],
                                                                      name: "general.guest-room-name".localized,
                                                                      team: ZMUser.selfUser().team) {
                weakSelf.delegate?.startUI(weakSelf, didSelect: conversation)
            }
        }
    }
}

extension StartUIViewController: ConversationCreationControllerDelegate {
    func dismiss(controller: ConversationCreationController, completion: (() -> Void)? = nil) {
        if traitCollection.horizontalSizeClass == .compact {
            navigationController?.popToRootViewController(animated: true) {
                UIApplication.shared.wr_updateStatusBarForCurrentControllerAnimated(true)
                completion?()
            }
        } else {
            controller.navigationController?.dismiss(animated: true, completion: completion)
        }
    }
    
    func conversationCreationController(_ controller: ConversationCreationController,
                                        didSelectName name: String,
                                        participants: Set<ZMUser>,
                                        allowGuests: Bool,
                                        enableReceipts: Bool) {
        dismiss(controller: controller) { [weak self] in
            guard let weakSelf = self else { return }

            weakSelf.delegate?.startUI(weakSelf, createConversationWith: participants, name: name, allowGuests: allowGuests, enableReceipts: enableReceipts)
        }
    }
    
}

extension StartUIViewController: EmptySearchResultsViewDelegate {
    func execute(action: EmptySearchResultsViewAction, from: EmptySearchResultsView) {
        switch action {
        case .openManageServices:
            URL.manageTeam(source: .onboarding).openInApp(above: self)
        }
    }
}
