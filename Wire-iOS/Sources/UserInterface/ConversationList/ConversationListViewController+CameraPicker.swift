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
import Cartography

func forward(_ image: UIImage, to conversations: [AnyObject]) {
    guard let imageData = image.jpegData(compressionQuality: 0.9),
        let conversations = conversations as? [ZMConversation] else {
        
        return
    }
    
    conversations.forEach { conversation in
        conversation.append(imageFromData: imageData)
    }
}

extension UIImage: Shareable {

    public func share<ZMConversation>(to conversations: [ZMConversation]) {
        forward(self, to: conversations as [AnyObject])
    }
    
    public typealias I = ZMConversation
    
    public func previewView() -> UIView? {
        let imageView = UIImageView(image: self)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .white
        imageView.layer.cornerRadius = 4
        constrain(imageView) { imageView in
            imageView.height == PreviewHeightCalculator.heightForImage(self)
        }
        
        return imageView
    }
}

func forward(_ videoAtURL: URL, to conversations: [AnyObject]) {
    guard let conversations = conversations as? [ZMConversation] else {
        return
    }
    
    FileMetaDataGenerator.metadataForFileAtURL(videoAtURL, UTI: kUTTypeMovie as String, name: "Recording") { metadata in
        conversations.forEach { conversation in
            conversation.append(file: metadata)
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
        playerViewController.showsPlaybackControls = false
        playerViewController.view.backgroundColor = .white
        playerViewController.view.layer.cornerRadius = 4

        constrain(playerViewController.view) { playerViewControllerView in
            playerViewControllerView.height == PreviewHeightCalculator.heightForVideo()
        }
        
        return playerViewController.view
    }
}


extension ConversationListViewController {

    @objc public func showCameraPicker() {
        UIApplication.wr_requestOrWarnAboutVideoAccess { (granted) in
            if granted {
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
        }
    }
    
    public func showShareControllerFor(image: UIImage) {
        let conversations = ZMConversationList.conversationsIncludingArchived(inUserSession: ZMUserSession.shared()!) as! [ZMConversation]
        
        let shareViewController: ShareViewController<ZMConversation, UIImage> = ShareViewController(shareable: image, destinations: conversations)
        let keyboardAvoiding = KeyboardAvoidingViewController(viewController: shareViewController)

        shareViewController.preferredContentSize = CGSize.IPadPopover.preferredContentSize
        shareViewController.onDismiss = { [weak self] (shareController: ShareViewController<ZMConversation, UIImage>, _) -> () in
            guard let `self` = self else {
                return
            }
            self.dismiss(animated: true)
        }
        
        self.present(keyboardAvoiding, animated: true)
    }
    
    public func showShareControllerFor(videoAtURL: URL) {
        let conversations = ZMConversationList.conversationsIncludingArchived(inUserSession: ZMUserSession.shared()!) as! [ZMConversation]
        
        let shareViewController: ShareViewController<ZMConversation, URL> = ShareViewController(shareable: videoAtURL, destinations: conversations)
        let keyboardAvoiding = KeyboardAvoidingViewController(viewController: shareViewController)

        shareViewController.preferredContentSize =  CGSize.IPadPopover.preferredContentSize
        shareViewController.onDismiss = { [weak self] (shareController: ShareViewController<ZMConversation, URL>, _) -> () in
            guard let `self` = self else {
                return
            }
            self.dismiss(animated: true)
        }
        
        self.present(keyboardAvoiding, animated: true)
    }
}
