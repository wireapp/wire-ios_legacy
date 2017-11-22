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


import AVKit
import Foundation

class AVPlayerViewControllerWithoutStatusBar: AVPlayerViewController {

    private let outputVolumeKeyPath = "outputVolume"
    
    init() {
        super.init(nibName: nil, bundle: nil)
        AVAudioSession.sharedInstance().addObserver(self, forKeyPath: outputVolumeKeyPath, options: NSKeyValueObservingOptions(rawValue: 0), context: nil)
    }
    
    deinit {
        AVAudioSession.sharedInstance().removeObserver(self, forKeyPath: outputVolumeKeyPath)
        try? AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryAmbient)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        let targetCategory = AVAudioSessionCategoryPlayback
        if keyPath == outputVolumeKeyPath && AVAudioSession.sharedInstance().category != targetCategory {
            try? AVAudioSession.sharedInstance().setCategory(targetCategory)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }

}


