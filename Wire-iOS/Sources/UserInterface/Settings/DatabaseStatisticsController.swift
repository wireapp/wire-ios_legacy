////
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
import UIKit
import Cartography
import WireDataModel

@objcMembers open class DatabaseStatisticsController: UIViewController {

    let stackView = UIStackView()
    let spinner = UIActivityIndicatorView()

    override open func viewDidLoad() {
        super.viewDidLoad()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 15

        stackView.layoutMargins = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.addArrangedSubview(spinner)
        spinner.startAnimating()

        edgesForExtendedLayout = []

        self.title = "Database Statistics".uppercased()

        view.addSubview(stackView)

        constrain(view, stackView) { view, stackView in
            stackView.top == view.top + 20
            stackView.leading == view.leading
            stackView.trailing == view.trailing
        }
    }

    func rowWith(title: String, contents: String) -> UIView {

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.textColor = .white
        titleLabel.textAlignment = .left

        let contentsLabel = UILabel()
        contentsLabel.text = contents
        contentsLabel.textColor = .white
        contentsLabel.setContentHuggingPriority(UILayoutPriority(rawValue: 200), for: .horizontal)
        contentsLabel.textAlignment = .right

        let stackView = UIStackView(arrangedSubviews:[titleLabel, contentsLabel])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 15

        return stackView
    }

    func addRow(title: String, contents: String) {
        DispatchQueue.main.async {
            let spinnerIndex = self.stackView.arrangedSubviews.index(of: self.spinner)!
            self.stackView.insertArrangedSubview(self.rowWith(title:title, contents: contents), at: spinnerIndex)
        }
    }

    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let session = ZMUserSession.shared()
        let syncMoc = session!.managedObjectContext.zm_sync!
        syncMoc.performGroupedBlock {
            do {
                defer {
                    // Hide the spinner when we are done
                    DispatchQueue.main.async {
                        self.spinner.isHidden = true
                    }
                }

                let conversations = ZMConversation.sortedFetchRequest()!
                let conversationsCount = try syncMoc.count(for: conversations)
                self.addRow(title: "Number of conversations", contents: "\(conversationsCount)")


                let messages = ZMMessage.sortedFetchRequest()!
                let messagesCount = try syncMoc.count(for: messages)
                self.addRow(title: "Number of messages", contents: "\(messagesCount)")


                let assetMessages = ZMAssetClientMessage.sortedFetchRequest()!
                let allAssets = try syncMoc.fetch(assetMessages)
                    .compactMap {
                        $0 as? ZMAssetClientMessage
                    }

                self.addRow(title: "Asset messages:", contents: "")

                func addSize(of assets: [ZMAssetClientMessage], title: String, filter: ((ZMAssetClientMessage) -> Bool)) {
                    let filtered = assets.filter(filter)
                    let size = filtered.reduce(0) { (count, asset) -> Int64 in
                        return count + Int64(asset.size)
                    }
                    let titleWithCount = filtered.isEmpty ? title : title + " (\(filtered.count))"
                    self.addRow(title: titleWithCount, contents: ByteCountFormatter.string(fromByteCount: size, countStyle: .file))
                }

                addSize(of: allAssets, title: "   Total", filter: { _ in true })
                addSize(of: allAssets, title: "   Images", filter: { $0.isImage })
                addSize(of: allAssets, title: "   Files", filter: { $0.isFile })
                addSize(of: allAssets, title: "   Video", filter: { $0.isVideo })
                addSize(of: allAssets, title: "   Audio", filter: { $0.isAudio })

            } catch {}
        }
    }
}
