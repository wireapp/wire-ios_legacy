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
    var isTeamOnly: Bool { get }
    func setTeamOnly(_ teamOnly: Bool, completion: @escaping (VoidResult) -> Void)
}

protocol ConversationOptionsViewModelDelegate: class {
    func viewModel(_ viewModel: ConversationOptionsViewModel, didUpdateState state: ConversationOptionsViewModel.State)
    func viewModel(_ viewModel: ConversationOptionsViewModel, didReceiveError error: Error)
}

extension ZMConversation: ConversationOptionsViewModelConfiguration {
    var isTeamOnly: Bool {
        return accessMode.isEmpty
    }
    
    func setTeamOnly(_ teamOnly: Bool, completion: @escaping (VoidResult) -> Void) {
        // TODO: User proper API to enable / disable team only mode.
        upgradeAccessLevel(in: ZMUserSession.shared()!, completion: completion)
    }
}

class ConversationOptionsViewModel {
    struct State {
        var rows = [CellConfiguration]()
        var isLoading = false
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
    }
    
    private func updateRows() {
        state.rows = computeVisibleRows()
    }
    
    private func computeVisibleRows() -> [CellConfiguration] {
        // TODO: Append additional rows depending on whether or not we have a link or not.
        return [
            .toggle(
                title: "guest_room.allow_guests.title".localized,
                get: { [unowned self] in return self.configuration.isTeamOnly },
                set: { [unowned self] in self.setTeamOnly($0) }
            )
        ]
    }
    
    private func setTeamOnly(_ teamOnly: Bool) {
        state.isLoading = true
        configuration.setTeamOnly(teamOnly) { [unowned self] result in
            self.state.isLoading = false
            switch result {
            case .success: self.updateRows()
            case .failure(let error): self.delegate?.viewModel(self, didReceiveError: error)
            }
        }
    }
    
}
