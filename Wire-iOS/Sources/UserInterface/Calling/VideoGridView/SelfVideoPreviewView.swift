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

protocol AVSIdentifierProvider {
    var identifier: String { get }
}

extension AVSVideoView: AVSIdentifierProvider {
    var identifier: String {
        return userid
    }
}

final class SelfVideoPreviewView: UIView, AVSIdentifierProvider {
    
    private let previewView = AVSVideoPreview()
    private let mutedOverlayView = UIView()
    let identifier: String
    
    var isMuted = false {
        didSet {
            guard oldValue != isMuted else { return }
            updateState(animated: true)
        }
    }
    
    init(identifier: String) {
        self.identifier = identifier
        super.init(frame: .zero)
        setupViews()
        createConstraints()
        updateState()
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        stopCapture()
    }
    
    private func setupViews() {
        [previewView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }
    }
    
    private func createConstraints() {
        previewView.fitInSuperview()
        mutedOverlayView.fitInSuperview()
    }
    
    private func updateState(animated: Bool = false) {
        let duration: TimeInterval = animated ? 0.2 : 0
        UIView.animate(withDuration: duration) { [mutedOverlayView, isMuted] in
            mutedOverlayView.alpha = isMuted ? 1 : 0
        }
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
