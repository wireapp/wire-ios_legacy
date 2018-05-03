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

import Foundation

class CallParticipantsViewController: UIViewController, CallParticipantsViewModel, UICollectionViewDelegateFlowLayout {
    
    let cellHeight: CGFloat = 56
    let viewModel: CallParticipantsViewModel
    var collectionView: UICollectionView!
    let allowsScrolling: Bool
    
    init(viewModel: CallParticipantsViewModel, allowsScrolling: Bool) {
        self.viewModel = viewModel
        self.allowsScrolling = allowsScrolling
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        self.view = ThemableContainerView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let collectionViewLayout = UICollectionViewFlowLayout()
        collectionViewLayout.scrollDirection = .vertical
        collectionViewLayout.minimumInteritemSpacing = 12
        collectionViewLayout.minimumLineSpacing = 0
        
        let collectionView = CallParticipantsView(frame: CGRect.zero, collectionViewLayout: collectionViewLayout, viewModel: self)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.bounces = allowsScrolling
        collectionView.delegate = self
        self.collectionView = collectionView
        
        view.addSubview(collectionView)
        
        CallParticipantsCellConfiguration.prepare(collectionView)
        
        createConstraints()
    }
    
    private func createConstraints() {
        NSLayoutConstraint.activate([
            collectionView.leftAnchor.constraint(equalTo: view.leftAnchor),
            collectionView.rightAnchor.constraint(equalTo: view.rightAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionView.topAnchor.constraint(equalTo: view.topAnchor)
        ])
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        collectionView.reloadData()
    }
    
    var rows: [CallParticipantsCellConfiguration] {
        guard !allowsScrolling else {
            return viewModel.rows
        }
        
        let visibleRows = Int(collectionView.bounds.height / cellHeight)
        
        if viewModel.rows.count > visibleRows {
            return viewModel.rows[0..<(visibleRows - 1)] + [.showAll(totalCount: viewModel.rows.count)]
        } else {
            return viewModel.rows
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.size.width, height: cellHeight)
    }
    
}
