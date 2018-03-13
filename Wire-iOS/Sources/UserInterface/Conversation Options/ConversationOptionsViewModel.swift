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

import UIKit

protocol ConversationOptionsViewModelConfiguration: class {
    var title: String { get }
    var allowGuests: Bool { get }
    var isCodeEnabled: Bool { get }
    var allowGuestsChangedHandler: ((Bool) -> Void)? { get set }
    func setAllowGuests(_ allowGuests: Bool, completion: @escaping (VoidResult) -> Void)
    func createConversationLink(completion: @escaping (Result<String>) -> Void)
    func fetchConversationLink(completion: @escaping (Result<String?>) -> Void)
    func deleteLink(completion: @escaping (VoidResult) -> Void)
}

protocol ConversationOptionsViewModelDelegate: class {
    func viewModel(_ viewModel: ConversationOptionsViewModel, didUpdateState state: ConversationOptionsViewModel.State)
    func viewModel(_ viewModel: ConversationOptionsViewModel, didReceiveError error: Error)
    func viewModel(_ viewModel: ConversationOptionsViewModel, confirmRemovingGuests completion: @escaping (Bool) -> Void)
    func viewModel(_ viewModel: ConversationOptionsViewModel, confirmRevokingLink completion: @escaping (Bool) -> Void)
    func viewModel(_ viewModel: ConversationOptionsViewModel, wantsToShareMessage message: String)
}

class ConversationOptionsViewModel {
    struct State {
        var rows = [CellConfiguration]()
        var isLoading = false
        var title = ""
    }
    
    private var showLoadingCell = false {
        didSet {
            updateRows()
        }
    }
    
    private var link: String?

    var copyInProgress = false {
        didSet {
            updateRows()
        }
    }
    
    var state = State() {
        didSet {
            delegate?.viewModel(self, didUpdateState: state)
        }
    }
    
    weak var delegate: ConversationOptionsViewModelDelegate? {
        didSet {
            delegate?.viewModel(self, didUpdateState: state)
        }
    }
    
    private let configuration: ConversationOptionsViewModelConfiguration
    
    init(configuration: ConversationOptionsViewModelConfiguration) {
        self.configuration = configuration
        state.title = configuration.title
        updateRows()
        configuration.allowGuestsChangedHandler = { [weak self] allowGuests in
            guard let `self` = self else { return }
            if allowGuests && self.configuration.isCodeEnabled {
                self.fetchLink()
            } else {
                self.updateRows()
            }
        }
        
        if configuration.allowGuests && configuration.isCodeEnabled {
            fetchLink()
        }
    }
    
    private func updateRows() {
        state.rows = computeVisibleRows()
    }
    
    private func computeVisibleRows() -> [CellConfiguration] {
        var rows: [CellConfiguration] = [.allowGuestsToogle(
                get: { [unowned self] in return self.configuration.allowGuests },
                set: { [unowned self] in self.setAllowGuests($0) }
            )]

        if configuration.allowGuests {
            rows.append(.linkHeader)
            
            if showLoadingCell {
                rows.append(.loading)
            } else {
                // Check if we have a link already
                if let link = link {
                    rows.append(.text(link))
                    rows.append(copyInProgress ? .copiedLink : .copyLink { [weak self] in self?.copyLink() })
                    rows.append(.shareLink { [weak self] in self?.shareLink() })
                    rows.append(.revokeLink { [weak self] in self?.revokeLink() })
                } else {
                    rows.append(.createLinkButton { [weak self] in self?.createLink() })
                }
            }
        }

        return rows
    }
    
    private func revokeLink() {
        delegate?.viewModel(self, confirmRevokingLink: { [weak self] revoke in
            guard let `self` = self else { return }
            guard revoke else { return self.updateRows() }
            GuestLinkEvent.revoked.track()
            self.state.isLoading = true
            self.configuration.deleteLink { result in
                switch result {
                case .success:
                    self.link = nil
                    self.updateRows()
                case .failure(let error):
                    self.delegate?.viewModel(self, didReceiveError: error)
                }
                self.state.isLoading = false
            }
        })
    }
    
    private func shareLink() {
        guard let link = link else { return }
        GuestLinkEvent.shared.track()
        let message = "guest_room.share.message".localized(args: link)
        delegate?.viewModel(self, wantsToShareMessage: message)
    }
    
    private func copyLink() {
        GuestLinkEvent.copied.track()
        UIPasteboard.general.string = link
        copyInProgress = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.copyInProgress = false
        }
    }
    
    private func fetchLink() {
        showLoadingCell = true
        configuration.fetchConversationLink { [weak self] result in
            guard let `self` = self else { return }
            switch result {
                case .success(let link): self.link = link
                case .failure(let error): self.delegate?.viewModel(self, didReceiveError: error)
            }
            self.showLoadingCell = false
        }
    }
    
    private func createLink() {
        GuestLinkEvent.created.track()
        showLoadingCell = true
        configuration.createConversationLink { [weak self] result in
            guard let `self` = self else { return }
            switch result {
            case .success(let link): self.link = link
            case .failure(let error): self.delegate?.viewModel(self, didReceiveError: error)
            }
            self.showLoadingCell = false
        }
    }
    
    func setAllowGuests(_ allowGuests: Bool) {
        func _setAllowGuests() {
            state.isLoading = true
            
            configuration.setAllowGuests(allowGuests) { [weak self] result in
                guard let `self` = self else { return }
                self.state.isLoading = false
                switch result {
                case .success:
                    self.updateRows()
                    if nil == self.link && allowGuests {
                        self.fetchLink()
                    }
                case .failure(let error): self.delegate?.viewModel(self, didReceiveError: error)
                }
            }
        }
        
        guard allowGuests != configuration.allowGuests else { return }
        
        // In case allow guests mode should be deactivated, ask the delegate
        // to confirm this action as all guests will be removed.
        if !allowGuests {
            delegate?.viewModel(self, confirmRemovingGuests: { [weak self] remove in
                guard let `self` = self else { return }
                guard remove else { return self.updateRows() }
                self.link = nil
                _setAllowGuests()
            })
        } else {
            _setAllowGuests()
        }
    }
    
}
