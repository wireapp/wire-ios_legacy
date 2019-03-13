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
        
        tracksCollectionView.fitInSuperview(exclude: [.top, .bottom])

        playlistTableView.fitInSuperview(exclude: [.top, .trailing])
        NSLayoutConstraint.activate([
            playlistTableView.topAnchor.constraint(equalTo: tracksCollectionView.bottomAnchor, constant: 16),
            playlistTableView.rightAnchor.constraint(equalTo: view.layoutMarginsGuide.rightAnchor),
            playlistTableView.heightAnchor.constraint(equalToConstant: playlistTableView.rowHeight * 2.5)])

        contentContainer.fitInSuperview(exclude: [.leading])
        NSLayoutConstraint.activate([
            contentContainer.leftAnchor.constraint(equalTo: view.layoutMarginsGuide.leftAnchor)])

        tracksSeparatorLineHeightConstraint = tracksSeparatorLine.heightAnchor.constraint(equalToConstant: 0)

        let constraint = view.heightAnchor.constraint(equalTo: view.widthAnchor)
        constraint.priority = .defaultLow

        NSLayoutConstraint.activate([
            tracksSeparatorLine.widthAnchor.constraint(equalToConstant:0.5),
            tracksSeparatorLine.centerYAnchor.constraint(equalTo: tracksCollectionView.centerYAnchor),
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
        
}
