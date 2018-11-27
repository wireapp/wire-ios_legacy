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

class EphemeralCountdownView: UIView {
    
    fileprivate let destructionCountdownView: DestructionCountdownView = DestructionCountdownView()
    fileprivate let containerView =  UIView()
    fileprivate var timer: Timer?
    
    var message: ZMConversationMessage? = nil
    
    init() {
        super.init(frame: .zero)
        
        addSubview(destructionCountdownView)
        
        destructionCountdownView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            destructionCountdownView.centerXAnchor.constraint(equalTo: centerXAnchor),
            destructionCountdownView.topAnchor.constraint(equalTo: topAnchor),
            destructionCountdownView.bottomAnchor.constraint(equalTo: bottomAnchor),
            destructionCountdownView.widthAnchor.constraint(equalToConstant: 8),
            destructionCountdownView.heightAnchor.constraint(equalToConstant: 8),
        ])
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        
        if window == nil {
            stopCountDown()
        }
    }
    
    func startCountDown() {
        stopCountDown()
        
        guard !isHidden else {
            return
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.updateCountdown()
        }
    }
    
    func stopCountDown() {
        destructionCountdownView.stopAnimating()
        timer?.invalidate()
        timer = nil
    }
    
    @objc
    fileprivate func updateCountdown() {
        guard let destructionDate = message?.destructionDate else {
            return
        }
        
        let duration = destructionDate.timeIntervalSinceNow
        
        if !destructionCountdownView.isAnimatingProgress && duration >= 1, let progress = message?.countdownProgress {
            destructionCountdownView.startAnimating(duration: duration, currentProgress: CGFloat(progress))
        }
    }
    
}
