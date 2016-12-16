//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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
import Cartography

final public class CollectionFileCell: UICollectionViewCell, Reusable {
    private let fileTransferView = FileTransferView()
    
    public weak var delegate: TransferViewDelegate? {
        didSet {
            self.fileTransferView.delegate = self.delegate
        }
    }
    public var message: ZMConversationMessage? {
        didSet {
            guard let message = self.message else {
                return
            }
            fileTransferView.configure(for: message, isInitial: true)
        }
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.loadView()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.loadView()
    }
    
    func loadView() {
        self.fileTransferView.delegate = self.delegate
        self.fileTransferView.layer.cornerRadius = 4
        self.fileTransferView.cas_styleClass = "container-view"
        self.fileTransferView.clipsToBounds = true
        
        self.layoutMargins = UIEdgeInsetsMake(4, 4, 4, 4)
        
        self.contentView.addSubview(self.fileTransferView)

        constrain(self, self.fileTransferView) { selfView, fileTransferView in
            fileTransferView.edges == selfView.edgesWithinMargins
        }
    }
    
    public override func prepareForReuse() {
        super.prepareForReuse()
        self.message = .none
    }
}

