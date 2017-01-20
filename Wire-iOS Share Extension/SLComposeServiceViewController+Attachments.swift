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


import Social
import MobileCoreServices


// MARK: - Process attachements
extension SLComposeServiceViewController {

    /// Get all the attachments to this post
    var allAttachments : [NSItemProvider] {
        guard let items = extensionContext?.inputItems as? [NSExtensionItem] else { return [] }
        return items.flatMap { $0.attachments as? [NSItemProvider] } // remove optional
            .flatMap { $0 } // flattens array
    }

    /// Gets all the URLs in this post, and invoke the callback (on main queue) when done
    func fetchURLAttachments(callback: @escaping ([URL])->()) {
        var urls : [URL] = []
        let group = DispatchGroup()
        allAttachments.forEach { attachment in
            if attachment.hasItemConformingToTypeIdentifier(kUTTypeURL as String) {
                group.enter()
                attachment.fetchURL { url in
                    DispatchQueue.main.async {
                        defer {  group.leave() }
                        guard let url = url else { return }
                        urls.append(url)
                    }
                }
            }
        }
        group.notify(queue: .main) { _ in callback(urls) }
    }
}
