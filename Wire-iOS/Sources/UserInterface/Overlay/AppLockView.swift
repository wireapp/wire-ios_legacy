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

import Foundation
import Cartography

@objc internal final class AppLockView: UIView {
    public var onReauthRequested: (()->())?
    
    public let shieldViewContainer = UIView()
    public let blurView: UIVisualEffectView!
    public let authenticateLabel = UILabel()
    public let authenticateButton = Button(style: .fullMonochrome)
    
    public var showReauth: Bool = false {
        didSet {
            self.authenticateLabel.isHidden = !showReauth
            self.authenticateButton.isHidden = !showReauth
        }
    }
    
    override init(frame: CGRect) {
        let blurEffect = UIBlurEffect(style: .dark)
        self.blurView = UIVisualEffectView(effect: blurEffect)
        
        super.init(frame: frame)
        
        let loadedObjects = UINib(nibName: "LaunchScreen", bundle: nil).instantiate(withOwner: .none, options: .none)
        
        let nibView = loadedObjects.first as! UIView
        self.shieldViewContainer.addSubview(nibView)
        constrain(self.shieldViewContainer, nibView) { shieldViewContainer, nibView in
            nibView.edges == shieldViewContainer.edges
        }
        
        self.addSubview(self.shieldViewContainer)
        self.addSubview(self.blurView)
        
        self.authenticateLabel.isHidden = true
        self.authenticateLabel.numberOfLines = 0
        self.authenticateButton.isHidden = true
        
        self.addSubview(self.authenticateLabel)
        self.addSubview(self.authenticateButton)
        
        self.authenticateLabel.text = "self.settings.privacy_security.lock_cancelled.description".localized
        self.authenticateButton.setTitle("self.settings.privacy_security.lock_cancelled.action".localized, for: .normal)
        self.authenticateButton.addTarget(self, action: #selector(AppLockView.onReauthenticatePressed(_:)), for: .touchUpInside)
        
        constrain(self, self.shieldViewContainer, self.blurView, self.authenticateLabel, self.authenticateButton) { selfView, shieldViewContainer, blurView, authenticateLabel, authenticateButton in
            shieldViewContainer.edges == selfView.edges
            blurView.edges == selfView.edges
            
            authenticateLabel.leading == selfView.leading + 24
            authenticateLabel.trailing == selfView.trailing - 24
            
            authenticateButton.top == authenticateLabel.bottom + 24
            authenticateButton.leading == selfView.leading + 24
            authenticateButton.trailing == selfView.trailing - 24
            authenticateButton.bottom == selfView.bottom - 24
            authenticateButton.height == 40
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatal("init(coder) is not implemented")
    }
    
    @objc public func onReauthenticatePressed(_ sender: AnyObject!) {
        self.onReauthRequested?()
    }
}
