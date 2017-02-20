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
import WireExtensionComponents

open class CollectionForwardableSaveableFileCell: CollectionCell {

    override func menuConfigurationProperties() -> MenuConfigurationProperties? {
        guard let properties = super.menuConfigurationProperties() else { return nil }
        if message?.isFileDownloaded() == true {
            var mutableItems = properties.additionalItems ?? []
            mutableItems.append(.save(with: #selector(save)))
            properties.additionalItems = mutableItems
        }
        return properties
    }

    override open func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        switch action {
        case #selector(forward), #selector(save):
            return self.message?.isFileDownloaded() ?? false
        default:
            return super.canPerformAction(action, withSender: sender)
        }
    }

    func save(_ sender: AnyObject) {
        guard message?.isFileDownloaded() == true else { return }
        delegate?.collectionCell(self, performAction: .save)
    }

}


final public class CollectionFileCell: CollectionForwardableSaveableFileCell {
    private let fileTransferView = FileTransferView()
    private let headerView = CollectionCellHeader()
    
    override func updateForMessage(changeInfo: MessageChangeInfo?) {
        super.updateForMessage(changeInfo: changeInfo)
        
        guard let message = self.message else {
            return
        }
        headerView.message = message
        fileTransferView.configure(for: message, isInitial: changeInfo == .none)
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
        self.fileTransferView.delegate = self
        self.fileTransferView.layer.cornerRadius = 4
        self.fileTransferView.clipsToBounds = true

        self.contentView.cas_styleClass = "container-view"
        self.contentView.layoutMargins = UIEdgeInsetsMake(16, 4, 4, 4)
        self.contentView.addSubview(self.headerView)
        self.contentView.addSubview(self.fileTransferView)

        constrain(self.contentView, self.fileTransferView, self.headerView) { contentView, fileTransferView, headerView in
            headerView.top == contentView.topMargin
            headerView.leading == contentView.leadingMargin + 12
            headerView.trailing == contentView.trailingMargin - 12
            
            fileTransferView.top == headerView.bottom + 4
            
            fileTransferView.left == contentView.leftMargin
            fileTransferView.right == contentView.rightMargin
            fileTransferView.bottom == contentView.bottomMargin
        }
    }

}

extension CollectionFileCell: TransferViewDelegate {
    public func transferView(_ view: TransferView, didSelect action: MessageAction) {
        self.delegate?.collectionCell(self, performAction: action)
    }
}
