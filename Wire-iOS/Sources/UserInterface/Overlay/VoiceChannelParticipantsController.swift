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

class VoiceChannelParticipantsController : NSObject {
    
    let conversation : ZMConversation
    let collectionView : UICollectionView
    
    var voiceGainObserverToken : Any?
    var participantObserverToken : Any?
    
    init(conversation : ZMConversation, collectionView: UICollectionView) {
        self.conversation = conversation
        self.collectionView = collectionView
        
        super.init()
        
        voiceGainObserverToken = conversation.voiceChannel?.addVoiceGainObserver(self)
        participantObserverToken = conversation.voiceChannel?.addParticipantObserver(self)
        
        collectionView.register(VoiceChannelParticipantCell.self, forCellWithReuseIdentifier: "VoiceChannelParticipantCell")
        collectionView.dataSource = self
        
        // Force the collection view to sync with the datasource since we might get notifications before
        // the next layout pass, which is when the collection view normally queries the data source.
        collectionView.performBatchUpdates(nil)
    }
    
}

extension VoiceChannelParticipantsController : UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VoiceChannelParticipantCell", for: indexPath)
        
        if let user = conversation.voiceChannel?.participants.object(at: indexPath.row) as? ZMUser,
           let participantState = conversation.voiceChannel?.state(forParticipant: user) {
            (cell as? VoiceChannelParticipantCell)?.configure(for: user, participantState: participantState)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return conversation.voiceChannel?.participants.count ?? 0
    }
    
}

extension VoiceChannelParticipantsController : VoiceChannelParticipantObserver {
    
    func voiceChannelParticipantsDidChange(_ changeInfo: VoiceChannelParticipantNotification) {
        guard conversation.conversationType != .group else { return }
        
        collectionView.performBatchUpdates({ 
            self.collectionView.insertItems(at: (changeInfo.insertedIndexes as NSIndexSet).indexPaths())
            self.collectionView.deleteItems(at: (changeInfo.deletedIndexes as NSIndexSet).indexPaths())
            
            for moved in changeInfo.zm_movedIndexPairs {
                let from = IndexPath(row: Int(moved.from), section: 0)
                let to = IndexPath(row: Int(moved.to), section: 0)
                self.collectionView.moveItem(at: from, to: to)
            }
        })
        
        changeInfo.updatedIndexes.forEach({ (index) in
            let cell = collectionView.cellForItem(at: IndexPath(item: index, section: 0)) as? VoiceChannelParticipantCell
            
            if let user = conversation.voiceChannel?.participants.object(at: index) as? ZMUser,
               let participantState = conversation.voiceChannel?.state(forParticipant: user) {
                cell?.configure(for: user, participantState: participantState)
            }
        })
    }
    
}

extension VoiceChannelParticipantsController : VoiceGainObserver {
    
    func voiceGainDidChange(forParticipant participant: ZMUser, volume: Float) {
        // Workaround for AUDIO-508
        guard volume > 0.01 else { return }
        guard let index = conversation.voiceChannel?.participants.index(of: participant) else { return }
        
        let cell = collectionView.cellForItem(at: IndexPath(item: index, section: 0)) as? VoiceChannelParticipantCell
        
        cell?.updateVoiceGain(CGFloat(volume))
    }
    
}
