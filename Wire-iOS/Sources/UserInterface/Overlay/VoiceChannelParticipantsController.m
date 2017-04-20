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
#import "WireSyncEngine+iOS.h"

#import <Classy/Classy.h>



@interface VoiceChannelParticipantsController () <VoiceChannelParticipantObserver, VoiceGainObserver>

@property (nonatomic) ZMConversation *conversation;
@property (nonatomic) UICollectionView *collectionView;
@property (nonatomic) id participantsStateObserverToken;
@property (nonatomic) id voiceGainObserverToken;

@end


@implementation VoiceChannelParticipantsController

- (instancetype)initWithConversation:(ZMConversation *)conversation collectionView:(UICollectionView *)collectionView
{
    self = [super init];
    
    if (self) {
        self.conversation = conversation;
        self.collectionView = collectionView;
        
        self.participantsStateObserverToken = [self.conversation.voiceChannel addParticipantObserver:self];
        self.voiceGainObserverToken = [self.conversation.voiceChannel addVoiceGainObserver:self];
        
        [self.collectionView registerClass:[VoiceChannelParticipantCell class] forCellWithReuseIdentifier:@"VoiceChannelParticipantCell"];
        self.collectionView.dataSource = self;
        
        // Force the collection view to sync with the datasource since we might get notifications before
        // the next layout pass, which is when the collection view normally queries the data source.
        [self.collectionView performBatchUpdates:nil completion:nil];
    }
    
    return self;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ZMUser *user = [self.conversation.voiceChannel.participants objectAtIndex:indexPath.row];
    VoiceChannelV2ParticipantState *participantState = [self.conversation.voiceChannel stateForParticipant:user];
        
    VoiceChannelParticipantCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"VoiceChannelParticipantCell" forIndexPath:indexPath];
    [cell configureForUser:user participantState:participantState];
    
    return cell;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.conversation.voiceChannel.participants.count;
}

#pragma mark - VoiceChannelParticipantStateObserver

- (void)voiceChannelParticipantsDidChange:(VoiceChannelParticipantNotification *)changeInfo
{
    if (self.conversation.conversationType != ZMConversationTypeGroup) {
        return;
    }
    if (self.conversation.voiceChannel.state == VoiceChannelV2StateInvalid){
        return;
    }
    
    [self.collectionView performBatchUpdates:^{
        [self.collectionView insertItemsAtIndexPaths:changeInfo.insertedIndexes.indexPaths];
        [self.collectionView deleteItemsAtIndexPaths:changeInfo.deletedIndexes.indexPaths];
        
        [changeInfo.zm_movedIndexPairs enumerateObjectsUsingBlock:^(ZMMovedIndex *moved, NSUInteger idx, BOOL *stop) {
            NSIndexPath *from = [NSIndexPath indexPathForRow:moved.from inSection:0];
            NSIndexPath *to = [NSIndexPath indexPathForRow:moved.to inSection:0];
            [self.collectionView moveItemAtIndexPath:from toIndexPath:to];
        }];
    } completion:nil];
    
    [changeInfo.updatedIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        VoiceChannelParticipantCell *cell = (VoiceChannelParticipantCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:idx inSection:0]];
        ZMUser *user = [self.conversation.voiceChannel.participants objectAtIndex:idx];
        VoiceChannelV2ParticipantState *participantState = [self.conversation.voiceChannel stateForParticipant:user];
        
        [cell configureForUser:user participantState:participantState];
    }];
}

#pragma mark - VoiceGainObserver

- (void)voiceGainDidChangeForParticipant:(ZMUser *)participant volume:(float)volume
{
    // Workaround for AUDIO-508
    if (volume > 0.01) {
        
        NSUInteger index = [self.conversation.voiceChannel.participants indexOfObject:participant];
        VoiceChannelParticipantCell *cell = (VoiceChannelParticipantCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
        [cell updateVoiceGain:volume];
    }
}

@end
