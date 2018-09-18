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

@objc protocol MentionsSearchResultsViewControllerDelegate {
    func didSelectUserToMention(_ user: ZMUser)
}

@objc protocol MentionsSearchResultsViewProtocol {
    func searchForUsers(with name: String)
    func dismissIfVisible()
}

class MentionsSearchResultsViewController: UIViewController {

    private let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewLayout())
    private var searchResults: [ZMUser] = []
    private var query: String = ""
    private var pendingSearchTask: SearchTask? = nil
    private var searchDirectory: SearchDirectory?
    private var tableViewHeight: NSLayoutConstraint?
    private let rowHeight: CGFloat = 56.0
    
    public var delegate: MentionsSearchResultsViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let session = ZMUserSession.shared() {
            searchDirectory = SearchDirectory(userSession: session)
        }
        
        setupCollectionView()
        setupConstraints()
    }
    
    private func setupCollectionView() {
        view.isHidden = true
        
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(UserCell.self, forCellWithReuseIdentifier: UserCell.reuseIdentifier)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = UIColor.white
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 1
        layout.minimumInteritemSpacing = 1
        
        collectionView.collectionViewLayout = layout

        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        view.addSubview(collectionView)
    }

    private func setupConstraints() {
        constrain(self.view, collectionView) { (selfView, collectionView) in
            collectionView.bottom == selfView.bottom
            collectionView.leading == selfView.leading
            collectionView.trailing == selfView.trailing
            tableViewHeight = collectionView.height == 0
        }
    }
    
    private func handleSearchResult(result: SearchResult, isCompleted: Bool) {
        reloadTable(with: result.contacts)
    }
    
    @objc func reloadTable(with results: [ZMUser]) {
        searchResults = results
        
        let viewHeight = self.view.bounds.size.height
        let minValue = min(viewHeight, CGFloat(searchResults.count) * rowHeight)
        tableViewHeight?.constant = minValue
        collectionView.isScrollEnabled = (minValue == viewHeight)
        
        collectionView.reloadData()
    }
    
    func cancelPreviousSearch() {
        pendingSearchTask?.cancel()
        pendingSearchTask = nil
    }
    
    func show() {
        self.view.isHidden = false
    }
    
}

extension MentionsSearchResultsViewController: MentionsSearchResultsViewProtocol {
    
    func dismissIfVisible() {
        self.view.isHidden = true
    }
    
    func searchForUsers(with name: String) {
        
        show()
        
        pendingSearchTask?.cancel()
        
        let request = SearchRequest(query: query,
                                    searchOptions: [.contacts, .teamMembers],
                                    team: ZMUser.selfUser().team)
        let task = searchDirectory?.perform(request)
        
        task?.onResult({ [weak self] in self?.handleSearchResult(result: $0, isCompleted: $1)})
        task?.start()
        
        pendingSearchTask = task
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
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.didSelectUserToMention(searchResults[indexPath.item])
        dismissIfVisible()
    }
}
