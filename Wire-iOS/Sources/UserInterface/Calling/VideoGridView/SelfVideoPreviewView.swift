//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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
import avs

final class SelfVideoPreviewView: BaseVideoPreviewView {
    
    private let previewView = AVSVideoPreview()
        
    deinit {
        stopCapture()
    }
    
    override func setupViews() {
        previewView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(previewView)
        super.setupViews()
    }
    
    override func createConstraints() {
        super.createConstraints()
        previewView.fitInSuperview()
    }
    
    override func updateUserDetails() {
        userDetailsView.microphoneIconStyle = MicrophoneIconStyle(state: stream.microphoneState)
        
        guard let name = stream.participantName else {
            return
        }
        userDetailsView.name = name + "user_cell.title.you_suffix".localized
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        
        if window != nil {
            startCapture()
        }
    }
    
    func startCapture() {
        previewView.startVideoCapture()
    }
    
    func stopCapture() {
        previewView.stopVideoCapture()
    }

}
