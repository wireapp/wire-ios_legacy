//
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

extension AudioPlaylistViewController {
    
    @objc
    func createInitialConstraints() {
        [backgroundView,
         blurEffectView,
         audioHeaderView,
         tracksCollectionView,
         playlistTableView,
         contentContainer,
         tracksSeparatorLine,
         playlistSeparatorLine].forEach{$0.translatesAutoresizingMaskIntoConstraints = false}
        
        backgroundView.fitInSuperview()
        blurEffectView.fitInSuperview()
        
        audioHeaderView.fitInSuperview(exclude: [.bottom])
        NSLayoutConstraint.activate([
            audioHeaderView.heightAnchor.constraint(equalToConstant: 64),
            tracksCollectionView.topAnchor.constraint(equalTo: audioHeaderView.bottomAnchor)])
        
        tracksCollectionView.fitInSuperview(exclude: [.leading, .trailing])
        
        playlistTableView.fitInSuperview(exclude: [.top])
        NSLayoutConstraint.activate([
            playlistTableView.topAnchor.constraint(equalTo: tracksCollectionView.bottomAnchor, constant: 16),
            playlistTableView.heightAnchor.constraint(equalToConstant: playlistTableView.rowHeight * 2.5)])
        
        contentContainer.fitInSuperview()
        
        tracksSeparatorLineHeightConstraint = tracksSeparatorLine.heightAnchor.constraint(equalToConstant: 0)
        
        let constraint = view.heightAnchor.constraint(equalTo: view.widthAnchor)
        constraint.priority = .defaultLow
        
        NSLayoutConstraint.activate([
            tracksSeparatorLine.widthAnchor.constraint(equalToConstant:0.5),
            tracksSeparatorLine.centerXAnchor.constraint(equalTo: tracksCollectionView.centerXAnchor),
            tracksSeparatorLine.rightAnchor.constraint(equalTo: tracksCollectionView.leftAnchor),
            tracksSeparatorLineHeightConstraint,
            
            playlistSeparatorLine.heightAnchor.constraint(equalToConstant:0.5),
            playlistSeparatorLine.widthAnchor.constraint(equalTo: playlistTableView.widthAnchor, constant: CGFloat(2) * AudioPlaylistViewController.separatorLineOverflow()),
            playlistSeparatorLine.bottomAnchor.constraint(equalTo: playlistTableView.topAnchor),
            playlistSeparatorLine.leftAnchor.constraint(equalTo: tracksCollectionView.leftAnchor, constant: -AudioPlaylistViewController.separatorLineOverflow()),
            
            view.heightAnchor.constraint(lessThanOrEqualToConstant: 375),
            constraint
            ])
    }
    
    
    /*
     - (void)createInitialConstraints
     {
     [self.backgroundView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
     [self.blurEffectView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
     
     [self.audioHeaderView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeBottom];
     [self.audioHeaderView autoSetDimension:ALDimensionHeight toSize:64];
     
     [self.tracksCollectionView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.audioHeaderView];
     [self.tracksCollectionView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
     [self.tracksCollectionView autoPinEdgeToSuperviewEdge:ALEdgeRight];
     
     [self.playlistTableView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
     [self.playlistTableView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
     [self.playlistTableView autoPinEdgeToSuperviewMargin:ALEdgeRight];
     [self.playlistTableView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.tracksCollectionView withOffset:16];
     [self.playlistTableView autoSetDimension:ALDimensionHeight toSize:self.playlistTableView.rowHeight * 2.5];
     
     [self.contentContainer autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeLeft];
     [self.contentContainer autoPinEdgeToSuperviewMargin:ALEdgeLeft];
     
     [self.tracksSeparatorLine autoSetDimension:ALDimensionWidth toSize:0.5];
     [self.tracksSeparatorLine autoAlignAxis:ALAxisHorizontal toSameAxisOfView:self.tracksCollectionView];
     [self.tracksSeparatorLine autoPinEdge:ALEdgeRight toEdge:ALEdgeLeft ofView:self.tracksCollectionView];
     _tracksSeparatorLineHeightConstraint = [self.tracksSeparatorLine autoSetDimension:ALDimensionHeight toSize:0];
     
     [self.playlistSeparatorLine autoSetDimension:ALDimensionHeight toSize:0.5];
     [self.playlistSeparatorLine autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.playlistTableView withOffset:2 * SeparatorLineOverflow];
     [self.playlistSeparatorLine autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.playlistTableView];
     [self.playlistSeparatorLine autoPinEdge:ALEdgeLeft toEdge:ALEdgeLeft ofView:self.tracksCollectionView withOffset:-SeparatorLineOverflow];
     
     [self.view autoSetDimension:ALDimensionHeight toSize:375 relation:NSLayoutRelationLessThanOrEqual];
     
     [NSLayoutConstraint autoSetPriority:UILayoutPriorityDefaultHigh forConstraints:^{
     [self.view autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:self.view];
     }];
     }*/
}
