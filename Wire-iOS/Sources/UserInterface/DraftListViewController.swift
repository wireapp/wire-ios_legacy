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


final class DraftListViewController: UIViewController {

    private var tableView: UITableView {
        return view as! UITableView
    }

    let storage: MessageDraftStorageType
    var drafts = [MessageDraft]()

    override func loadView() {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        view = tableView
    }

    init(draftStorage: MessageDraftStorageType) {
        storage = draftStorage
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        loadDrafts()
    }

    private func loadDrafts() {
        drafts = storage.storedDrafts()
        tableView.reloadData()
    }

    private func setupViews() {
        title = "compose.drafts.title".localized.uppercased()
        navigationItem.rightBarButtonItem = UIBarButtonItem(icon: .X, style: .done, target: self, action: #selector(closeTapped))
        navigationItem.leftBarButtonItem = UIBarButtonItem(icon: .plus, target: self, action: #selector(newDraftTapped))
        DraftMessageCell.register(in: tableView)
    }

    private dynamic func closeTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

    private dynamic func newDraftTapped(_ sender: Any) {
        showDraft(nil)
    }

    fileprivate func showDraft(_ draft: MessageDraft?) {
        let composeViewController = MessageComposeViewController()
        if let draft = draft {
            composeViewController.draft = draft
        }
        let detail = DraftNavigationController(rootViewController: composeViewController)
        navigationController?.splitViewController?.showDetailViewController(detail, sender: nil)
    }

}

extension DraftListViewController: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return drafts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: DraftMessageCell.zm_reuseIdentifier, for: indexPath) as! DraftMessageCell
        let draft = drafts[indexPath.row]
        cell.textLabel?.text = draft.subject
        cell.detailTextLabel?.text = draft.message
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        showDraft(drafts[indexPath.row])
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return .delete
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        // TODO: Delete draft
    }

}

