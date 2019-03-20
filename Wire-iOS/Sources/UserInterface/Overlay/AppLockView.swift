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

final class AppLockView: UIView {
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

    var userInterfaceSizeClass :(UITraitEnvironment) -> UIUserInterfaceSizeClass = {traitEnvironment in
        return traitEnvironment.traitCollection.horizontalSizeClass
    }

    public var showReauth: Bool = false {
        didSet {
            self.authenticateLabel.isHidden = !showReauth
            self.authenticateButton.isHidden = !showReauth
        }
    }

    init(authenticationType: AuthenticationType = .current) {
        let blurEffect = UIBlurEffect(style: .dark)
        self.blurView = UIVisualEffectView(effect: blurEffect)
        
        super.init(frame: .zero)
        
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

        switch authenticationType {
        case .touchID:
            self.authenticateLabel.text = "self.settings.privacy_security.lock_cancelled.description_touch_id".localized
        case .faceID:
            self.authenticateLabel.text = "self.settings.privacy_security.lock_cancelled.description_face_id".localized
        case .none:
            self.authenticateLabel.text = "self.settings.privacy_security.lock_cancelled.description_passcode".localized
        }

        self.authenticateButton.setTitle("self.settings.privacy_security.lock_cancelled.action".localized, for: .normal)
        self.authenticateButton.addTarget(self, action: #selector(AppLockView.onReauthenticatePressed(_:)), for: .touchUpInside)

        createConstraints(nibView: nibView)

        toggleConstraints()
    }

    private func createConstraints(nibView: UIView) {

        [self,
         nibView,
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

    }
    
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        toggleConstraints()
    }

    
    func toggleConstraints() {
        userInterfaceSizeClass(self).toggle(compactConstraints: [contentLeadingConstraint, contentTrailingConstraint],
               regularConstraints: [contentCenterConstraint, contentWidthConstraint])
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatal("init(coder) is not implemented")
    }
    
    @objc public func onReauthenticatePressed(_ sender: AnyObject!) {
        self.onReauthRequested?()
    }
}
