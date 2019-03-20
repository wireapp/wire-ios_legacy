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
import UIKit

@objc protocol AudioTrackCellDelegate: NSObjectProtocol {
    func audioTrackCell(_ cell: AudioTrackCell?, didPlayPauseTrack audioTrack: AudioTrack?)
}

@objcMembers
final class AudioTrackCell: UICollectionViewCell {
    var audioTrack: AudioTrack? {
        didSet {
            artworkObserver = KeyValueObserver.observe(self.audioTrack, keyPath: "artwork", target: self, selector: #selector(self.artworkChanged(_:)), options: [.initial, .new])

            if audioTrack?.artwork == nil {
                audioTrack?.fetchArtwork()
            } else {
                updateArtwork()
            }

            audioTrackView.failedToLoad = self.audioTrack?.failedToLoad ?? false || self.audioTrack == nil

        }
    }

    let audioTrackView = AudioTrackView()
    var artworkObserver: NSObject?
    weak var delegate: AudioTrackCellDelegate?

    override func prepareForReuse() {
        audioTrackView.playPauseButton?.setIcon(.play, with: .large, for: .normal)
        
        audioTrackView.progress = 0
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(audioTrackView)
        audioTrackView.playPauseButton.addTarget(self, action: #selector(self.playPause(_:)), for: .touchUpInside)

        audioTrackView.translatesAutoresizingMaskIntoConstraints = false
        audioTrackView.fitInSuperview()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateArtwork() {
        audioTrackView.artworkImageView.image = audioTrack?.artwork
    }

    func artworkChanged(_ change: [AnyHashable : Any]?) {
        updateArtwork()
    }

    func playPause(_ sender: Any) {
        delegate?.audioTrackCell(self, didPlayPauseTrack: audioTrack)
    }

}
