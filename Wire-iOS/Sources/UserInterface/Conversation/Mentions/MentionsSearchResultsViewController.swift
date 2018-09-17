//
//  MentionsSearchResultsViewController.swift
//  Wire-iOS
//
//  Created by Nicola Giancecchi on 12.09.18.
//  Copyright © 2018 Zeta Project Germany GmbH. All rights reserved.
//

import UIKit
import Cartography

class MentionsSearchResultsViewController: UIViewController {

    private let reuseIdentifier = "MentionsCell"
    private let tableView = UITableView(frame: .zero)
    private var searchResults: [ZMUser] = []
    private var query: String = ""
    private var pendingSearchTask: SearchTask? = nil
    private var searchDirectory: SearchDirectory?
    private var tableViewHeight: NSLayoutConstraint?
    private let rowHeight: CGFloat = 56.0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let session = ZMUserSession.shared() {
            searchDirectory = SearchDirectory(userSession: session)
        }
        
        tableView.register(MentionsSearchResultCell.self, forCellReuseIdentifier: reuseIdentifier)
        
        tableView.delegate = self
        tableView.dataSource = self
        
        setupDesign()
    }
    
    private func setupDesign() {
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        view.addSubview(tableView)
        
        constrain(self.view, tableView) { (selfView, tableView) in
            tableView.bottom == selfView.bottom
            tableView.leading == selfView.leading
            tableView.trailing == selfView.trailing
            tableViewHeight = tableView.height == 0
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func searchForUsers(with name: String) {
        pendingSearchTask?.cancel()
        
        let request = SearchRequest(query: query,
                                    searchOptions: [.contacts, .teamMembers],
                                    team: ZMUser.selfUser().team)
        let task = searchDirectory?.perform(request)
        
        task?.onResult({ [weak self] in self?.handleSearchResult(result: $0, isCompleted: $1)})
        task?.start()
        
        pendingSearchTask = task
    }
    
    private func handleSearchResult(result: SearchResult, isCompleted: Bool) {
        reloadTable(with: result.contacts)
    }
    
    func reloadTable(with results: [ZMUser]) {
        searchResults = results
        tableViewHeight?.constant = CGFloat(min(3, searchResults.count)) * rowHeight
        tableView.reloadData()
    }
    
    func cancelPreviousSearch() {
        pendingSearchTask?.cancel()
        pendingSearchTask = nil
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension MentionsSearchResultsViewController: UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return rowHeight
    }
}

extension MentionsSearchResultsViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! MentionsSearchResultCell
        let user = searchResults[indexPath.item]
        cell.configure(with: user)
        return cell
    }
}
