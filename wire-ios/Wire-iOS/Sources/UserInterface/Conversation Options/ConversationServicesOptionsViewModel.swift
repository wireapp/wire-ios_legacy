//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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
import WireUtilities

protocol ConversationServicesOptionsViewModelConfiguration: AnyObject {
    var title: String { get }
    var allowServices: Bool { get }
    var areServicePresent: Bool { get }
    var allowServicesChangedHandler: ((Bool) -> Void)? { get set }
    func setAllowServices(_ allowServices: Bool, completion: @escaping (VoidResult) -> Void)
}

protocol ConversationServicesOptionsViewModelDelegate: AnyObject {
    func viewModel(_ viewModel: ConversationServicesOptionsViewModel, didUpdateState state: ConversationServicesOptionsViewModel.State)
    func viewModel(_ viewModel: ConversationServicesOptionsViewModel, didReceiveError error: Error)
    func viewModel(_ viewModel: ConversationServicesOptionsViewModel, sourceView: UIView?, confirmRemovingServices completion: @escaping (Bool) -> Void) -> UIAlertController?
}

final class ConversationServicesOptionsViewModel {
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

    var state = State() {
        didSet {
            delegate?.viewModel(self, didUpdateState: state)
        }
    }

    weak var delegate: ConversationServicesOptionsViewModelDelegate? {
        didSet {
            delegate?.viewModel(self, didUpdateState: state)
        }
    }

    private let configuration: ConversationServicesOptionsViewModelConfiguration

    init(configuration: ConversationServicesOptionsViewModelConfiguration) {
        self.configuration = configuration
        state.title = configuration.title
        updateRows()

        configuration.allowServicesChangedHandler = { [weak self] _ in
            self?.updateRows()
        }
    }
    private func updateRows() {
        state.rows = [.allowServicesToggle(
            get: { [unowned self] in return self.configuration.allowServices},
            set: { [unowned self] in self.setAllowServices($0, view: $1) }
        )]
    }

    /// set conversation option AllowServices
    /// - Parameters:
    ///   - allowServices: new state AllowServices
    ///   - view: the source view which triggers setAllowServices action
    /// - Returns: alert controller
    @discardableResult func setAllowServices(_ allowServices: Bool, view: UIView? = nil) -> UIAlertController? {
        func _setAllowServices() {
            let item = CancelableItem(delay: 0.4) { [weak self] in
                self?.state.isLoading = true
            }

            configuration.setAllowServices(allowServices) { [weak self] result in
                guard let self = self else { return }
                item.cancel()
                self.state.isLoading = false

                switch result {
                case .success:
                    self.updateRows()
                case .failure(let error):
                    self.delegate?.viewModel(self, didReceiveError: error)
                }
            }
        }

        guard allowServices != configuration.allowServices else { return nil }

        // In case allow services mode should be deactivated & service in conversation, ask the delegate
        // to confirm this action as all services will be removed.
        if !allowServices && configuration.areServicePresent {
            // Make "remove services" warning only appear if services are present
            return delegate?.viewModel(self, sourceView: view, confirmRemovingServices: { [weak self] remove in
                guard let `self` = self else { return }
                guard remove else { return self.updateRows() }
                _setAllowServices()
            })
        } else {
            _setAllowServices()
        }

        return nil
    }

}
