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
import WireDataModel
import WireSyncEngine

final class ConversationOptionsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, SpinnerCapable, ConversationOptionsViewModelDelegate {

    private let tableView = UITableView()
    private var viewModel: ConversationOptionsViewModel
    private let variant: ColorSchemeVariant

    var dismissSpinner: SpinnerCompletion?

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return wr_supportedInterfaceOrientations
    }

    convenience init(conversation: ZMConversation, userSession: ZMUserSession) {
        let configuration = ZMConversation.OptionsConfigurationContainer(
            conversation: conversation,
            userSession: userSession
        )
        self.init(
            viewModel: .init(configuration: configuration),
            variant: ColorScheme.default.variant
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.rightBarButtonItem = navigationController?.closeItem()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        view.addSubview(tableView)
        CellConfiguration.prepare(tableView)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.contentInset = UIEdgeInsets(top: 32, left: 0, bottom: 0, right: 0)
        tableView.estimatedRowHeight = 80
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = UIColor.from(scheme: .contentBackground, variant: variant)
        if #available(iOS 11.0, *) {
            tableView.contentInsetAdjustmentBehavior = .never
        }
    }

    private func createConstraints() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
    }

    // MARK: – ConversationOptionsViewModelDelegate

    func viewModel(_ viewModel: ConversationOptionsViewModel,
                   didUpdateState state: ConversationOptionsViewModel.State) {
        tableView.reloadData()

        (navigationController as? SpinnerCapableViewController)?.isLoadingViewVisible = state.isLoading
        title = state.title
    }

    func viewModel(_ viewModel: ConversationOptionsViewModel, didReceiveError error: Error) {
        present(UIAlertController.checkYourConnection(), animated: false)
    }

    func viewModel(_ viewModel: ConversationOptionsViewModel, sourceView: UIView? = nil, confirmRemovingGuests completion: @escaping (Bool) -> Void) -> UIAlertController? {
        let alertController = UIAlertController.confirmRemovingGuests(completion)
        alertController.configPopover(pointToView: sourceView ?? view)
        present(alertController, animated: true)

        return alertController
    }

    func viewModel(_ viewModel: ConversationOptionsViewModel, sourceView: UIView? = nil, confirmRevokingLink completion: @escaping (Bool) -> Void) {
        let alertController = UIAlertController.confirmRevokingLink(completion)
        present(alertController, animated: true)

        alertController.configPopover(pointToView: sourceView ?? view)
    }

    func viewModel(_ viewModel: ConversationOptionsViewModel, wantsToShareMessage message: String, sourceView: UIView? = nil) {
        let activityController = TintCorrectedActivityViewController(activityItems: [message], applicationActivities: nil)
        present(activityController, animated: true)

        activityController.configPopover(pointToView: sourceView ?? view)
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
        let cell = tableView.cellForRow(at: indexPath)
        viewModel.state.rows[indexPath.row].action?(cell)
    }

}
