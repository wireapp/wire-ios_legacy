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
import Cartography

final class ConversationOptionsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, ConversationOptionsViewModelDelegate {

    private let tableView = UITableView()
    private var viewModel: ConversationOptionsViewModel
    private let variant: ColorSchemeVariant
    
    convenience init(conversation: ZMConversation) {
        self.init(
            viewModel: .init(configuration: conversation),
            variant: ColorScheme.default().variant
        )
    }
    
    init(viewModel: ConversationOptionsViewModel, variant: ColorSchemeVariant) {
        self.viewModel = viewModel
        self.variant = variant
        super.init(nibName: nil, bundle: nil)
        setupViews()
        createConstraints()
        viewModel.delegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        view.addSubview(tableView)
        tableView.register(ToggleSubtitleCell.self, forCellReuseIdentifier: ToggleSubtitleCell.reuseIdentifier)
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.contentInset = UIEdgeInsets(top: 32, left: 0, bottom: 0, right: 0)
        tableView.estimatedRowHeight = 80
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = ColorScheme.default().color(withName: ColorSchemeColorContentBackground, variant: variant)
    }
    
    private func createConstraints() {
        constrain(view, tableView) { view, tableView in
            tableView.edges == view.edges
        }
    }
    
    // MARK: – ConversationOptionsViewModelDelegate
    
    func viewModel(_ viewModel: ConversationOptionsViewModel, didUpdateState state: ConversationOptionsViewModel.State) {
        tableView.reloadData()
        showLoadingView = state.isLoading
    }
    
    func viewModel(_ viewModel: ConversationOptionsViewModel, didReceiveError error: Error) {
        // TODO: Present error alert.
    }
    
    func viewModel(_ viewModel: ConversationOptionsViewModel, confirmRemovingGuests completion: @escaping (Bool) -> Void) {
        let alert = UIAlertController.confirmRemovingGuests(completion)
        present(alert, animated: false)
    }

    // MARK: – UITableViewDelegate & UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.state.rows.count
    }
    
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return viewModel.state.rows[indexPath.row].action != nil
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = viewModel.state.rows[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: row.cellType.reuseIdentifier, for: indexPath) as! CellConfigurationConfigurable
        cell.configure(with: row, variant: variant)
        return cell as! UITableViewCell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        viewModel.state.rows[indexPath.row].action?()
    }

}
