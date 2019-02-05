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


@objcMembers final class AppLockView: UIView {
    public var onReauthRequested: (()->())?
    
    public let shieldViewContainer = UIView()
    public let contentContainerView = UIView()
    public let blurView: UIVisualEffectView!
    public let authenticateLabel: UILabel = {
        let label = UILabel()
        label.font = .largeThinFont
        label.textColor = .from(scheme: .textForeground, variant: .dark)

        return label
    }()
    public let authenticateButton = Button(style: .fullMonochrome)
    
    private var contentWidthConstraint: NSLayoutConstraint!
    private var contentCenterConstraint: NSLayoutConstraint!
    private var contentLeadingConstraint: NSLayoutConstraint!
    private var contentTrailingConstraint: NSLayoutConstraint!
    
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
        shieldViewContainer.addSubview(nibView)

        addSubview(shieldViewContainer)
        addSubview(blurView)
        
        self.authenticateLabel.isHidden = true
        self.authenticateLabel.numberOfLines = 0
        self.authenticateButton.isHidden = true
        
        addSubview(contentContainerView)
        
        contentContainerView.addSubview(authenticateLabel)
        contentContainerView.addSubview(authenticateButton)
        
        self.authenticateLabel.text = "self.settings.privacy_security.lock_cancelled.description".localized
        self.authenticateButton.setTitle("self.settings.privacy_security.lock_cancelled.action".localized, for: .normal)
        self.authenticateButton.addTarget(self, action: #selector(AppLockView.onReauthenticatePressed(_:)), for: .touchUpInside)

        createConstraints(nibView: nibView)

        updateConstraints(userInterfaceSizeClass: traitCollection.horizontalSizeClass)
    }

    private func createConstraints(nibView: UIView) {

        [nibView,
         shieldViewContainer,
         blurView,
         contentContainerView,
         authenticateButton,
         authenticateLabel].forEach(){ $0.translatesAutoresizingMaskIntoConstraints = false }

        nibView.fitInSuperview()
        shieldViewContainer.fitInSuperview()
        blurView.fitInSuperview()

        let constraints = contentContainerView.fitInSuperview()

        ///for compact
        contentLeadingConstraint = constraints[.leading]
        contentTrailingConstraint = constraints[.trailing]

        ///for regular
        contentCenterConstraint = contentContainerView.centerXAnchor.constraint(equalTo: centerXAnchor)
        contentWidthConstraint = contentContainerView.widthAnchor.constraint(equalToConstant: 320)

        authenticateLabel.fitInSuperview(with: EdgeInsets(margin: 24), exclude: [.top, .bottom])

        authenticateButton.fitInSuperview(with: EdgeInsets(margin: 24), exclude: [.top])


        NSLayoutConstraint.activate([
            authenticateButton.heightAnchor.constraint(equalToConstant: 40),
            authenticateButton.topAnchor.constraint(equalTo: authenticateLabel.bottomAnchor, constant: 24)
        ])

        constrain(self, self.contentContainerView, self.authenticateLabel, self.authenticateButton) { selfView, contentContainerView, authenticateLabel, authenticateButton in
//            contentContainerView.top == selfView.top
//            contentContainerView.bottom == selfView.bottom
//
//            self.contentLeadingConstraint = contentContainerView.leading == selfView.leading
//            self.contentTrailingConstraint = contentContainerView.trailing == selfView.trailing
//
//            self.contentCenterConstraint = contentContainerView.centerX == selfView.centerX
//            self.contentWidthConstraint = contentContainerView.width == 320

//            authenticateLabel.leading == contentContainerView.leading + 24
//            authenticateLabel.trailing == contentContainerView.trailing - 24

            authenticateButton.top == authenticateLabel.bottom + 24
//            authenticateButton.leading == contentContainerView.leading + 24
//            authenticateButton.trailing == contentContainerView.trailing - 24
//            authenticateButton.bottom == contentContainerView.bottom - 24
//            authenticateButton.height == 40
        }

    }
    
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        updateConstraints(userInterfaceSizeClass: traitCollection.horizontalSizeClass)
    }
    
    func updateConstraints(userInterfaceSizeClass: UIUserInterfaceSizeClass) {

        toggle(compactConstraints: [contentLeadingConstraint, contentTrailingConstraint],
               regularConstraints: [contentCenterConstraint, contentWidthConstraint],
               userInterfaceSizeClass: userInterfaceSizeClass)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatal("init(coder) is not implemented")
    }
    
    @objc public func onReauthenticatePressed(_ sender: AnyObject!) {
        self.onReauthRequested?()
    }
}
