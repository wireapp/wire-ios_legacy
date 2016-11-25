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


#import "VoiceChannelParticipantsController.h"

#import "VoiceChannelParticipantCell.h"
#import "VoiceUserImageView.h"
#import "NSIndexSet+IndexPaths.h"
#import "zmessaging+iOS.h"

#import <Classy/Classy.h>
#import <ZMCDataModel/ZMVoiceChannelNotifications.h>



@interface VoiceChannelParticipantsController () <ZMVoiceChannelParticipantsObserver, ZMVoiceChannelVoiceGainObserver>

@property (nonatomic) ZMConversation *conversation;
@property (nonatomic) UICollectionView *collectionView;
@property (nonatomic) id<ZMVoiceChannelParticipantsObserverOpaqueToken> participantsStateObserverToken;

@end


@implementation VoiceChannelParticipantsController

- (void)dealloc
{
    if (self.participantsStateObserverToken) {
        [ZMVoiceChannel removeCallParticipantsObserverForToken:self.participantsStateObserverToken inConversation:self.conversation];
    }
    
    [ZMVoiceChannelParticipantVoiceGainChangedNotification removeObserver:self];
}

- (instancetype)initWithConversation:(ZMConversation *)conversation collectionView:(UICollectionView *)collectionView
{
    self = [super init];
    
    if (self) {
        self.conversation = conversation;
        self.collectionView = collectionView;
        
        self.participantsStateObserverToken = [ZMVoiceChannel addCallParticipantsObserver:self inConversation:conversation voiceChannel:conversation.voiceChannel];
        [self.collectionView registerClass:[VoiceChannelParticipantCell class] forCellWithReuseIdentifier:@"VoiceChannelParticipantCell"];
        self.collectionView.dataSource = self;
        
        // Force the collection view to sync with the datasource since we might get notifications before
        // the next layout pass, which is when the collection view normally queries the data source.
        [self.collectionView performBatchUpdates:nil completion:nil];
        
        // FIXME
        [ZMVoiceChannelParticipantVoiceGainChangedNotification addObserver:self forVoiceChannel:self.conversation.voiceChannel.v2];
    }
    
    return self;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ZMUser *user = [self.conversation.voiceChannel.participants objectAtIndex:indexPath.row];
    
    ZMVoiceChannelParticipantState *participantState = [self.conversation.voiceChannel stateForParticipant:user];
        
    VoiceChannelParticipantCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"VoiceChannelParticipantCell" forIndexPath:indexPath];
    [cell configureForUser:user participantState:participantState];
    
    return cell;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.conversation.voiceChannel.participants.count;
}

#pragma mark - ZMVoiceChannelParticipantStateObserver

- (void)voiceChannelParticipantsDidChange:(VoiceChannelParticipantsChangeInfo *)info
{
    if (self.conversation.conversationType != ZMConversationTypeGroup) {
        return;
    }
    
    if (info.needsReload) {
        [self.collectionView reloadData];
    } else {
        [self.collectionView performBatchUpdates:^{
            [self.collectionView insertItemsAtIndexPaths:info.insertedIndexes.indexPaths];
            [self.collectionView deleteItemsAtIndexPaths:info.deletedIndexes.indexPaths];
            
            [info.movedIndexPairs enumerateObjectsUsingBlock:^(ZMMovedIndex *moved, NSUInteger idx, BOOL *stop) {
                NSIndexPath *from = [NSIndexPath indexPathForRow:moved.from inSection:0];
                NSIndexPath *to = [NSIndexPath indexPathForRow:moved.to inSection:0];
                [self.collectionView moveItemAtIndexPath:from toIndexPath:to];
            }];
        } completion:nil];
        
        [info.updatedIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
            VoiceChannelParticipantCell *cell = (VoiceChannelParticipantCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:idx inSection:0]];
            ZMUser *user = [self.conversation.voiceChannel.participants objectAtIndex:idx];
            ZMVoiceChannelParticipantState *participantState = [self.conversation.voiceChannel stateForParticipant:user];
            
            [cell configureForUser:user participantState:participantState];
        }];
    }
}

#pragma mark - ZMVoiceChannelVoiceGainObserver

- (void)voiceChannelParticipantVoiceGainDidChange:(ZMVoiceChannelParticipantVoiceGainChangedNotification *)info
{
    // Workaround for AUDIO-508
    if (info.voiceGain > 0.01) {
        
        NSUInteger index = [self.conversation.voiceChannel.participants indexOfObject:info.participant];
        VoiceChannelParticipantCell *cell = (VoiceChannelParticipantCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
        [cell updateVoiceGain:info.voiceGain];
    }
}

@end
