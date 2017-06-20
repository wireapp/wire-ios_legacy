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


#import <Classy/Classy.h>

#import "LinkAttachmentViewControllerFactory.h"
#import "MediaPreviewViewController.h"
#import "AudioTrackViewController.h"
#import "AudioPlaylistViewController.h"
#import "AppDelegate.h"
#import "MediaPlaybackManager.h"
#import "LinkAttachment.h"
@import WireDataModel;


@implementation LinkAttachmentViewControllerFactory

+ (instancetype)sharedInstance
{
    static LinkAttachmentViewControllerFactory *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    
    return sharedInstance;
}

- (UIViewController<LinkAttachmentPresenter> *)viewControllerForLinkAttachment:(LinkAttachment *)linkAttachment message:(id<ZMConversationMessage>)message
{
    if (message.isObfuscated) {
        return nil;
    }

    UIViewController<LinkAttachmentPresenter> *viewController = nil;

    if (linkAttachment.type == LinkAttachmentTypeSoundcloudTrack) {
        AudioTrackViewController *audioTrackViewController = [[AudioTrackViewController alloc] initWithAudioTrackPlayer:[AppDelegate sharedAppDelegate].mediaPlaybackManager.audioTrackPlayer sourceMessage:message];
        audioTrackViewController.providerImage = [UIImage imageNamed:@"soundcloud"];
        audioTrackViewController.linkAttachment = linkAttachment;
        
        viewController = audioTrackViewController;
    }
    else if (linkAttachment.type == LinkAttachmentTypeSoundcloudSet) {
        AudioPlaylistViewController *audioPlaylistViewController = [[AudioPlaylistViewController alloc] initWithAudioTrackPlayer:[AppDelegate sharedAppDelegate].mediaPlaybackManager.audioTrackPlayer sourceMessage:message];
        audioPlaylistViewController.providerImage = [UIImage imageNamed:@"soundcloud"];
        audioPlaylistViewController.linkAttachment = linkAttachment;
        
        viewController = audioPlaylistViewController;
    }
    else if (linkAttachment.type == LinkAttachmentTypeYoutubeVideo) {
        MediaPreviewViewController *mediaPreviewViewController = [[MediaPreviewViewController alloc] init];
        mediaPreviewViewController.linkAttachment = linkAttachment;
        viewController = mediaPreviewViewController;
    }
    
    return viewController;
}

@end
