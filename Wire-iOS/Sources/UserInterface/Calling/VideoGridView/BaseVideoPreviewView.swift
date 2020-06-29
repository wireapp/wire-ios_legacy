//
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
import avs

protocol AVSIdentifierProvider {
    var stream: Stream { get }
}

extension AVSVideoView: AVSIdentifierProvider {
    
    var stream: Stream {
        return Stream(userId: UUID(uuidString: userid)!,
                      clientId: clientid,
                      participantName: nil,
                      microphoneState: .unmuted)
    }
}

class BaseVideoPreviewView: UIView, AVSIdentifierProvider {
    var stream: Stream
    
    let userDetailsView = VideoParticipantDetailsView()
    
    init(stream: Stream) {
        self.stream = stream
        
        super.init(frame: .zero)
        
        userDetailsView.name = stream.participantName
        userDetailsView.microphoneIconStyle = MicrophoneIconStyle(state: stream.microphoneState)
        setupViews()
        createConstraints()
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateUserDetailsVisibility), name: .videoGridVisibilityChanged, object: nil)
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func setupViews() {
        userDetailsView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(userDetailsView)
        userDetailsView.alpha = 0.0
    }
    
    func createConstraints() {
        NSLayoutConstraint.activate([
            userDetailsView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            userDetailsView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -8),
            userDetailsView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            userDetailsView.heightAnchor.constraint(equalToConstant: 24),
        ])
    }
    
    @objc private func updateUserDetailsVisibility(_ notification: Notification?) {
        guard let isCovered = notification?.userInfo?[VideoGridViewController.isCoveredKey] as? Bool else {
            return
        }
        UIView.animate(
            withDuration: 0.2,
            delay: 0,
            options: [.curveEaseInOut, .beginFromCurrentState],
            animations: {
                self.userDetailsView.alpha = isCovered ? 0.0 : 1.0
        })
    }
}
