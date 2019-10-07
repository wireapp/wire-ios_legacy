//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

protocol FolderPickerViewControllerDelegate {
    func didPickFolder(_ folder: String, for conversation: ZMConversation)
}

class FolderPickerViewController: UIViewController {

    var delegate: FolderPickerViewControllerDelegate?
    
    fileprivate var items: [String] = []
    fileprivate let conversation: ZMConversation
    private let collectionViewLayout = UICollectionViewFlowLayout()
    
    private lazy var collectionView: UICollectionView = {
        return UICollectionView(frame: .zero, collectionViewLayout: self.collectionViewLayout)
    }()
    
    
    public init(conversation: ZMConversation, folders: [String]) {
        self.conversation = conversation
        self.items = folders
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "folder.picker.title".localized(uppercased: true)
        navigationItem.leftBarButtonItem = navigationController?.closeItem()
        
        let newFolderItem = UIBarButtonItem(icon: .plus, target: self, action: #selector(createNewFolder))
        newFolderItem.accessibilityIdentifier = "button.newfolder.create"
        
        navigationItem.rightBarButtonItem = newFolderItem
        
        configureSubviews()
        configureConstraints()
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return wr_supportedInterfaceOrientations
    }
    
    private func configureSubviews() {
        
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = UIColor.from(scheme: .contentBackground)
        collectionView.alwaysBounceVertical = true
        
        collectionViewLayout.minimumLineSpacing = 0
        
        CheckmarkCell.register(in: collectionView)
        
    }
    
    private func configureConstraints() {
        
        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        collectionView.fitInSuperview()
    }
    
    @objc private func createNewFolder() {
        let folderCreation = FolderCreationController(conversation: conversation)
        folderCreation.delegate = self
        self.navigationController?.pushViewController(folderCreation, animated: true)
    }


}

// MARK: - Table View

extension FolderPickerViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let item = items[indexPath.row]
        let cell = collectionView.dequeueReusableCell(ofType: CheckmarkCell.self, for: indexPath)
        cell.title = item
        cell.showCheckmark = false
        cell.showSeparator = indexPath.row < (items.count - 1)
        
        return cell
    }
    
    private func pickFolder(_ name: String) {
        
        /// TODO logic for choosing folder
        
        self.delegate?.didPickFolder(name, for: conversation)
    }
    
    private func handle(error: Error) {
        let controller = UIAlertController.checkYourConnection()
        present(controller, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        let selectedItem = items[indexPath.row]
        pickFolder(selectedItem)
    }
    
    // MARK: Layout
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.size.width, height: 56)
    }
    
}

extension FolderPickerViewController : FolderCreationControllerDelegate {
    func folderController(_ controller: FolderCreationController, didCreateFolder name: String) {
        self.items.append(name)
        
        // logic to reload folders
    }
}
