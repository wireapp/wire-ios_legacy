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

    private let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewLayout())
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
        
        collectionView.register(UserCell.self, forCellWithReuseIdentifier: UserCell.reuseIdentifier)
        collectionView.delegate = self
        collectionView.dataSource = self
        
        setupDesign()
    }
    
    private func setupDesign() {
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = UIColor.white
        
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        view.addSubview(collectionView)
        
        constrain(self.view, collectionView) { (selfView, collectionView) in
            collectionView.bottom == selfView.bottom
            collectionView.leading == selfView.leading
            collectionView.trailing == selfView.trailing
            tableViewHeight = collectionView.height == 0
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func searchForUsers(with name: String) {
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
    
    @objc func reloadTable(with results: [ZMUser]) {
        searchResults = results
        tableViewHeight?.constant = CGFloat(min(3, searchResults.count)) * rowHeight
        collectionView.collectionViewLayout.invalidateLayout()
        collectionView.reloadData()
    }
    
    func cancelPreviousSearch() {
        pendingSearchTask?.cancel()
        pendingSearchTask = nil
    }
}

extension MentionsSearchResultsViewController: UICollectionViewDelegate {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return searchResults.count
    }
}

extension MentionsSearchResultsViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.size.width, height: rowHeight)
    }
}

extension MentionsSearchResultsViewController: UICollectionViewDataSource {
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let user = searchResults[indexPath.item]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: UserCell.reuseIdentifier, for: indexPath) as! UserCell
        cell.configure(with: user)
        return cell
    }
    
}
