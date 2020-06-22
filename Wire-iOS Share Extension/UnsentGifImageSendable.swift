
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

import Foundation
import WireShareEngine
import MobileCoreServices

/// `UnsentSendable` implementation to send GIF image messages
final class UnsentGifImageSendable: UnsentSendableBase, UnsentSendable {
    private var gifImageData: Data?
    private let attachment: NSItemProvider
    
    init?(conversation: Conversation, sharingSession: SharingSession, attachment: NSItemProvider) {
        guard attachment.hasItemConformingToTypeIdentifier(kUTTypeGIF as String) else { return nil }
        self.attachment = attachment
        super.init(conversation: conversation, sharingSession: sharingSession)
        needsPreparation = true
    }
    
    func prepare(completion: @escaping () -> Void) {
        precondition(needsPreparation, "Ensure this objects needs preparation, c.f. `needsPreparation`")
        needsPreparation = false
        
        attachment.loadItem(forTypeIdentifier: kUTTypeGIF as String) { [weak self] (url, error) in
            
            error?.log(message: "Unable to load image from attachment")
            
            if let url = url as? URL,
               let data = try? Data(contentsOf: url) {
                self?.gifImageData = data
            } else if let data = url as? Data {
                self?.gifImageData = data
            } else {
                error?.log(message: "Invalid Gif data")
            }
            
            completion()
        }
    }
    
    func send(completion: @escaping (Sendable?) -> Void) {
        sharingSession.enqueue { [weak self] in
            guard let `self` = self else { return }
            completion(self.gifImageData.flatMap(self.conversation.appendImage))
        }
    }
}
