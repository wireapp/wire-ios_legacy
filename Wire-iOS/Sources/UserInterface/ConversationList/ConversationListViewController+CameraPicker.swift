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

import Foundation
import AVKit
import MobileCoreServices

func forward(_ image: UIImage, to conversations: [AnyObject]) {
    guard let imageData = UIImageJPEGRepresentation(image, 0.9),
        let conversations = conversations as? [ZMConversation] else {
        
        return
    }
    
    conversations.forEach { conversation in
        conversation.appendMessage(withImageData: imageData)
    }
}

extension UIImage: Shareable {
    public func share<ZMConversation>(to conversations: [ZMConversation]) {
        forward(self, to: conversations as [AnyObject])
    }
    
    public typealias I = ZMConversation
    
    public func previewView() -> UIView? {
        let imageView = UIImageView(image: self)
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .white
        imageView.layer.cornerRadius = 4
        return imageView
    }
}

func forward(_ videoAtURL: URL, to conversations: [AnyObject]) {
    guard let conversations = conversations as? [ZMConversation] else {
        return
    }
    
    FileMetaDataGenerator.metadataForFileAtURL(videoAtURL, UTI: kUTTypeMovie as String, name: "Recording") { metadata in
        conversations.forEach { conversation in
            conversation.appendMessage(with: metadata)
        }
    }
}

extension URL: Shareable {
    public func share<ZMConversation>(to conversations: [ZMConversation]) {
        forward(self, to: conversations as [AnyObject])
    }
    
    public typealias I = ZMConversation
    
    public func previewView() -> UIView? {
        
        let playerViewController = AVPlayerViewController()
        
        playerViewController.player = AVPlayer(url: self)
        playerViewController.showsPlaybackControls = true
        playerViewController.view.backgroundColor = .white
        playerViewController.view.layer.cornerRadius = 4

        return playerViewController.view
    }
}


extension ConversationListViewController {

    @objc public func showCameraPicker() {
        let cameraPicker = CameraPicker(target: self)
        cameraPicker.didPickResult = { [weak self] result in
            guard let `self` = self else {
                return
            }
            
            switch result {
            case .image(let image):
                self.showShareControllerFor(image: image)
            case .video(let videoURL):
                self.showShareControllerFor(videoAtURL: videoURL)
            }
        }
        
        cameraPicker.pick()
    }
    
    public func showShareControllerFor(image: UIImage) {
        let conversations = ZMConversationList.conversationsIncludingArchived(inUserSession: ZMUserSession.shared()!, team: ZMUser.selfUser().activeTeam) as! [ZMConversation]
        
        let shareViewController: ShareViewController<ZMConversation, UIImage> = ShareViewController(shareable: image, destinations: conversations)
        let keyboardAvoiding = KeyboardAvoidingViewController(viewController: shareViewController)

        shareViewController.preferredContentSize = CGSize(width: 320, height: 568)
        shareViewController.onDismiss = { [weak self] (shareController: ShareViewController<ZMConversation, UIImage>, _) -> () in
            guard let `self` = self else {
                return
            }
            self.dismiss(animated: true)
        }
        
        self.present(keyboardAvoiding, animated: true)
    }
    
    public func showShareControllerFor(videoAtURL: URL) {
        let conversations = ZMConversationList.conversationsIncludingArchived(inUserSession: ZMUserSession.shared()!, team: ZMUser.selfUser().activeTeam) as! [ZMConversation]
        
        let shareViewController: ShareViewController<ZMConversation, URL> = ShareViewController(shareable: videoAtURL, destinations: conversations)
        let keyboardAvoiding = KeyboardAvoidingViewController(viewController: shareViewController)

        shareViewController.preferredContentSize = CGSize(width: 320, height: 568)
        shareViewController.onDismiss = { [weak self] (shareController: ShareViewController<ZMConversation, URL>, _) -> () in
            guard let `self` = self else {
                return
            }
            self.dismiss(animated: true)
        }
        
        self.present(keyboardAvoiding, animated: true)
    }
}
