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
    func createInitialConstraints() {
        backgroundView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets.zero)
        blurEffectView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets.zero)

        audioHeaderView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets.zero, excludingEdge: ALEdgeBottom)
        audioHeaderView.autoSetDimension(ALDimensionHeight, toSize: 64)

        tracksCollectionView.autoPinEdge(ALEdgeTop, toEdge: ALEdgeBottom, ofView: audioHeaderView)
        tracksCollectionView.autoPinEdge(toSuperviewEdge: ALEdgeLeft)
        tracksCollectionView.autoPinEdge(toSuperviewEdge: ALEdgeRight)

        playlistTableView.autoPinEdge(toSuperviewEdge: ALEdgeLeft)
        playlistTableView.autoPinEdge(toSuperviewEdge: ALEdgeBottom)
        playlistTableView.autoPinEdge(toSuperviewMargin: ALEdgeRight)
        playlistTableView.autoPinEdge(ALEdgeTop, toEdge: ALEdgeBottom, ofView: tracksCollectionView, withOffset: 16)
        playlistTableView.autoSetDimension(ALDimensionHeight, toSize: playlistTableView.rowHeight * 2.5)

        contentContainer.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets.zero, excludingEdge: ALEdgeLeft)
        contentContainer.autoPinEdge(toSuperviewMargin: ALEdgeLeft)

        tracksSeparatorLine.autoSetDimension(ALDimensionWidth, toSize: 0.5)
        tracksSeparatorLine.autoAlignAxis(ALAxisHorizontal, toSameAxisOfView: tracksCollectionView)
        tracksSeparatorLine.autoPinEdge(ALEdgeRight, toEdge: ALEdgeLeft, ofView: tracksCollectionView)
        tracksSeparatorLineHeightConstraint = tracksSeparatorLine.autoSetDimension(ALDimensionHeight, toSize: 0)

        playlistSeparatorLine.autoSetDimension(ALDimensionHeight, toSize: 0.5)
        playlistSeparatorLine.autoMatchDimension(ALDimensionWidth, toDimension: ALDimensionWidth, ofView: playlistTableView, withOffset: 2 * Int(SeparatorLineOverflow))
        playlistSeparatorLine.autoPinEdge(ALEdgeBottom, toEdge: ALEdgeTop, ofView: playlistTableView)
        playlistSeparatorLine.autoPinEdge(ALEdgeLeft, toEdge: ALEdgeLeft, ofView: tracksCollectionView, withOffset: -SeparatorLineOverflow)

        view.autoSetDimension(ALDimensionHeight, toSize: 375, relation: NSLayoutConstraint.Relation.lessThanOrEqual)

        NSLayoutConstraint.autoSetPriority(UILayoutPriority.defaultHigh, forConstraints: {
            self.view.autoMatchDimension(ALDimensionHeight, toDimension: ALDimensionWidth, ofView: self.view)
        })
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
