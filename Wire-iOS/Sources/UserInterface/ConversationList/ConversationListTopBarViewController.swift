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

import UIKit
import Cartography

typealias SelfUserType = UserType & SelfLegalHoldSubject

final class ConversationListTopBarViewController: UIViewController {
    
    private var observerToken: Any?
    private var availabilityViewController: AvailabilityTitleViewController?
    private var account: Account
    private let selfUser: SelfUserType
    
    var topBar: TopBar? {
        return view as? TopBar
    }

    /// init a ConversationListTopBarViewController
    ///
    /// - Parameters:
    ///   - account: the Account of the user
    ///   - selfUser: the self user object. Allow to inject a mock self user for testing
    init(account: Account, selfUser: SelfUserType = ZMUser.selfUser()) {
        self.account = account
        self.selfUser = selfUser
        
        super.init(nibName: nil, bundle: nil)

        if let sharedSession = ZMUserSession.shared() {
            observerToken = UserChangeInfo.add(observer: self, for: ZMUser.selfUser(), userSession: sharedSession)
        }
        
        if #available(iOS 11.0, *) {
            self.viewRespectsSystemMinimumLayoutMargins = false
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = TopBar()
    }
    
    override func viewDidLoad() {
        topBar?.layoutMargins = UIEdgeInsets(top: 0, left: 9, bottom: 0, right: 16)
        topBar?.splitSeparator = false
        
        availabilityViewController?.didMove(toParent: self)

        updateTitleView()
        updateAccountView()
        updateLegalHoldIndictor()
    }

    // MARK: - Title View

    func updateTitleView() {
        topBar?.middleView = createTitleView()
    }
    
    func createTitleView() -> UIView {
        if selfUser.isTeamMember {
            let availabilityViewController = AvailabilityTitleViewController(user: selfUser, options: .header)
            availabilityViewController.availabilityTitleView?.colorSchemeVariant = .dark
            addChild(availabilityViewController)
            self.availabilityViewController = availabilityViewController
            
            return availabilityViewController.view
        } else {
            let titleLabel = UILabel()
            
            titleLabel.text = selfUser.name
            titleLabel.font = FontSpec(.normal, .semibold).font
            titleLabel.textColor = UIColor.from(scheme: .textForeground, variant: .dark)
            titleLabel.accessibilityTraits = .header
            titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
            titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
            titleLabel.setContentHuggingPriority(.required, for: .horizontal)
            titleLabel.setContentHuggingPriority(.required, for: .vertical)

            return titleLabel
        }
    }

    private func createLegalHoldView() -> UIView {
        let imageView = UIImageView()

        imageView.setIcon(.legalholdactive, size: .tiny, color: .vividRed)
        imageView.isUserInteractionEnabled = true

        let imageViewContainer = UIView()
        imageViewContainer.setLegalHoldAccessibility()

        imageViewContainer.addSubview(imageView)

        imageViewContainer.translatesAutoresizingMaskIntoConstraints = false
        imageView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            imageViewContainer.widthAnchor.constraint(equalToConstant: CGFloat.ConversationListHeader.iconWidth),
            imageViewContainer.widthAnchor.constraint(equalTo: imageViewContainer.heightAnchor),

            imageView.centerXAnchor.constraint(equalTo: imageViewContainer.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: imageViewContainer.centerYAnchor)])

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(presentLegalHoldInfo))
        imageViewContainer.addGestureRecognizer(tapGestureRecognizer)

        return imageViewContainer
    }

    func createPendingLegalHoldRequestView() -> UIView {
        let button = IconButton(style: .circular)
        button.setBackgroundImageColor(UIColor.vividRed.withAlphaComponent(0.5), for: .normal)

        button.setIcon(.clock, size: 12, for: .normal)
        button.setIconColor(.white, for: .normal)
        button.setIconColor(UIColor.white.withAlphaComponent(0.5), for: .highlighted)

        button.setLegalHoldAccessibility()
        button.accessibilityValue = "legalhold_request.button.accessibility".localized

        button.addTarget(self, action: #selector(presentLegalHoldRequest), for: .touchUpInside)

        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 24),
            button.heightAnchor.constraint(equalToConstant: 24)
        ])

        return button
    }

    func updateAccountView() {
        topBar?.leftView = createAccountView()
    }

    func createAccountView() -> BaseAccountView {
        let session = ZMUserSession.shared() ?? nil
        let user = session == nil ? nil : ZMUser.selfUser(inUserSession: session!)
        let accountView = AccountViewFactory.viewFor(account: account, user: user)
        
        accountView.unreadCountStyle = .others
        accountView.selected = false
        accountView.autoUpdateSelection = false
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(presentSettings))
        accountView.addGestureRecognizer(tapGestureRecognizer)
        
        accountView.accessibilityTraits = .button
        accountView.accessibilityIdentifier = "bottomBarSettingsButton"
        accountView.accessibilityLabel = "self.voiceover.label".localized
        accountView.accessibilityHint = "self.voiceover.hint".localized
        
        if let user = ZMUser.selfUser() {
            if user.clientsRequiringUserAttention.count > 0 {
                accountView.accessibilityLabel = "self.new-device.voiceover.label".localized
            }
        }
        
        return accountView
    }
    
    func updateLegalHoldIndictor() {
        switch selfUser.legalHoldStatus {
        case .disabled:
            topBar?.rightView = nil
        case .pending:
            topBar?.rightView = createPendingLegalHoldRequestView()
        case .enabled:
            topBar?.rightView = createLegalHoldView()
        }
    }

    @objc
    func presentLegalHoldInfo() {
        LegalHoldDetailsViewController.present(in: self, user: ZMUser.selfUser())
    }

    @objc func presentLegalHoldRequest() {
        guard case .pending = selfUser.legalHoldStatus else {
            return
        }

        ZClientViewController.shared()?.legalHoldDisclosureController?.discloseCurrentState(cause: .userAction)
    }

    @objc
    func presentSettings() {
        let settingsViewController = createSettingsViewController()
        let keyboardAvoidingViewController = KeyboardAvoidingViewController(viewController: settingsViewController)
        
        if wr_splitViewController?.layoutSize == .compact {
            keyboardAvoidingViewController.modalPresentationStyle = .currentContext
            keyboardAvoidingViewController.transitioningDelegate = self
            present(keyboardAvoidingViewController, animated: true)
        } else {
            keyboardAvoidingViewController.modalPresentationStyle = .formSheet
            keyboardAvoidingViewController.view.backgroundColor = .black
            present(keyboardAvoidingViewController, animated: true)
        }
    }

    @objc
    func createSettingsViewController() -> UIViewController {
        let selfProfileViewController = SelfProfileViewController(selfUser: ZMUser.selfUser())
        return selfProfileViewController.wrapInNavigationController(navigationControllerClass: ClearBackgroundNavigationController.self)
    }
    
}

extension ConversationListTopBarViewController: UIViewControllerTransitioningDelegate {
    
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let transition = SwizzleTransition()
        transition.direction = .vertical
        return transition
    }
    
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let transition = SwizzleTransition()
        transition.direction = .vertical
        return transition
    }
}

extension ConversationListTopBarViewController: ZMUserObserver {
    
    public func userDidChange(_ changeInfo: UserChangeInfo) {
        if changeInfo.nameChanged {
            updateTitleView()
        }

        if changeInfo.teamsChanged {
            updateAccountView()
        }
        
        if changeInfo.legalHoldStatusChanged {
            updateLegalHoldIndictor()
        }
    }
}

extension ConversationListTopBarViewController {
    @objc(scrollViewDidScroll:)
    public func scrollViewDidScroll(scrollView: UIScrollView!) {
        topBar?.leftSeparatorLineView.scrollViewDidScroll(scrollView: scrollView)
        topBar?.rightSeparatorLineView.scrollViewDidScroll(scrollView: scrollView)
    }
}

open class TopBar: UIView {
    public var leftView: UIView? = .none {
        didSet {
            oldValue?.removeFromSuperview()
            
            guard let new = leftView else {
                return
            }
            
            self.addSubview(new)
            
            constrain(self, new) { selfView, new in
                new.leading == selfView.leadingMargin
                new.centerY == selfView.centerY
            }

            if let middleView = middleView {
                NSLayoutConstraint.activate([
                    new.trailingAnchor.constraint(lessThanOrEqualTo: middleView.leadingAnchor, constant: 0)
                    ])
            }
        }
    }
    
    public var rightView: UIView? = .none {
        didSet {
            oldValue?.removeFromSuperview()
            
            guard let new = rightView else {
                return
            }
            
            self.addSubview(new)
            
            constrain(self, new) { selfView, new in
                new.trailing == selfView.trailingMargin
                new.centerY == selfView.centerY
            }
        }
    }
    
    private let middleViewContainer = UIView()
    
    public var middleView: UIView? = .none {
        didSet {
            oldValue?.removeFromSuperview()
            
            guard let new = middleView else {
                return
            }
            
            self.middleViewContainer.addSubview(new)
            
            constrain(middleViewContainer, new) { middleViewContainer, new in
                new.center == middleViewContainer.center
                middleViewContainer.size == new.size
            }
        }
    }
    
    public var splitSeparator: Bool = true {
        didSet {
            leftSeparatorInsetConstraint.isActive = splitSeparator
            rightSeparatorInsetConstraint.isActive = splitSeparator
            self.layoutIfNeeded()
        }
    }
    
    public let leftSeparatorLineView = OverflowSeparatorView()
    public let rightSeparatorLineView = OverflowSeparatorView()
    
    private var leftSeparatorInsetConstraint: NSLayoutConstraint!
    private var rightSeparatorInsetConstraint: NSLayoutConstraint!
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.layoutMargins = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        [leftSeparatorLineView, rightSeparatorLineView, middleViewContainer].forEach(self.addSubview)
        
        constrain(self, self.middleViewContainer, self.leftSeparatorLineView, self.rightSeparatorLineView) {
            selfView, middleViewContainer, leftSeparatorLineView, rightSeparatorLineView in
            
            leftSeparatorLineView.leading == selfView.leading
            leftSeparatorLineView.bottom == selfView.bottom
            
            rightSeparatorLineView.trailing == selfView.trailing
            rightSeparatorLineView.bottom == selfView.bottom
            
            middleViewContainer.center == selfView.center
            leftSeparatorLineView.trailing == selfView.centerX ~ 750.0
            rightSeparatorLineView.leading == selfView.centerX ~ 750.0
            self.leftSeparatorInsetConstraint = leftSeparatorLineView.trailing == middleViewContainer.leading - 7
            self.rightSeparatorInsetConstraint = rightSeparatorLineView.leading == middleViewContainer.trailing + 7
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override open var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: 44)
    }
}
