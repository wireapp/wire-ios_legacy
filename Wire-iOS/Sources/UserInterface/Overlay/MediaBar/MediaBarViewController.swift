// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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
import UIKit
import WireCommonComponents

final class MediaBarViewController: UIViewController {
    private var mediaPlaybackManager: MediaPlaybackManager?
    
    private var mediaBarView: MediaBar? {
        return view as? MediaBar
    }
    
    required init(mediaPlaybackManager: MediaPlaybackManager?) {
        super.init(nibName: nil, bundle: nil)
        
        self.mediaPlaybackManager = mediaPlaybackManager
        self.mediaPlaybackManager?.changeObserver = self
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = MediaBar()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mediaBarView?.playPauseButton.addTarget(self, action: #selector(playPause(_:)), for: .touchUpInside)
        mediaBarView?.closeButton.addTarget(self, action: #selector(stop(_:)), for: .touchUpInside)
        
        updatePlayPauseButton()
    }
    
    private func updateTitleLabel() {
        mediaBarView?.titleLabel.text = mediaPlaybackManager?.activeMediaPlayer?.title?.uppercasedWithCurrentLocale
    }
    
    func updatePlayPauseButton() {
        let playPauseIcon: StyleKitIcon
        let accessibilityIdentifier: String
        
        if mediaPlaybackManager?.activeMediaPlayer?.state == .playing {
            playPauseIcon = .pause
            accessibilityIdentifier = "mediaBarPauseButton"
        } else {
            playPauseIcon = .play
            accessibilityIdentifier = "mediaBarPlayButton"
        }
        
        mediaBarView?.playPauseButton.setIcon(playPauseIcon, size: .tiny, for: UIControl.State.normal)
        mediaBarView?.playPauseButton.accessibilityIdentifier = accessibilityIdentifier
    }
    
    // MARK: - Actions
    @objc
    private func playPause(_ sender: Any?) {
        if mediaPlaybackManager?.activeMediaPlayer?.state == .playing {
            mediaPlaybackManager?.pause()
        } else {
            mediaPlaybackManager?.play()
        }
    }
    
    @objc
    private func stop(_ sender: Any?) {
        mediaPlaybackManager?.stop()
    }

}

extension MediaBarViewController: MediaPlaybackManagerChangeObserver {
    
    func activeMediaPlayerStateDidChange() {
        updatePlayPauseButton()
    }
}
