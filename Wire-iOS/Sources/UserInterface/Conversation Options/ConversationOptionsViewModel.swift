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
    var allowGuestsChangedHandler: ((Bool) -> Void)? { get set }
    func setAllowGuests(_ allowGuests: Bool, completion: @escaping (VoidResult) -> Void)
}

protocol ConversationOptionsViewModelDelegate: class {
    func viewModel(_ viewModel: ConversationOptionsViewModel, didUpdateState state: ConversationOptionsViewModel.State)
    func viewModel(_ viewModel: ConversationOptionsViewModel, didReceiveError error: Error)
    func viewModel(_ viewModel: ConversationOptionsViewModel, confirmRemovingGuests completion: @escaping (Bool) -> Void)
}

class ConversationOptionsViewModel {
    struct State {
        var rows = [CellConfiguration]()
        var isLoading = false
        var title = ""
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
        configuration.allowGuestsChangedHandler = { [weak self] _ in
            self?.updateRows()
        }
    }
    
    private func updateRows() {
        state.rows = computeVisibleRows()
    }
    
    private func computeVisibleRows() -> [CellConfiguration] {
        return [
            .toggle(
                title: "guest_room.allow_guests.title".localized,
                subtitle: "guest_room.allow_guests.subtitle".localized,
                accessibilityIdentifier: "toggle.guestoptions.allowguests",
                get: { [unowned self] in return self.configuration.allowGuests },
                set: { [unowned self] in self.setAllowGuests($0) }
            )
        ]
    }
    
    func setAllowGuests(_ allowGuests: Bool) {
        func _setAllowGuests() {
            state.isLoading = true
            
            configuration.setAllowGuests(allowGuests) { [unowned self] result in
                self.state.isLoading = false
                switch result {
                case .success: self.updateRows()
                case .failure(let error): self.delegate?.viewModel(self, didReceiveError: error)
                }
            }
        }
        
        guard allowGuests != configuration.allowGuests else { return }
        
        // In case allow guests mode should be deactivated, ask the delegate
        // to confirm this action as all guests will be removed.
        if !allowGuests {
            delegate?.viewModel(self, confirmRemovingGuests: { [unowned self] remove in
                guard remove else { return self.updateRows() }
                _setAllowGuests()
            })
        } else {
            _setAllowGuests()
        }
    }
    
}
