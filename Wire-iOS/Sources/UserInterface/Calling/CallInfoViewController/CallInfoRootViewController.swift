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

protocol CallInfoRootViewControllerDelegate: class {
    func infoRootViewController(_ viewController: CallInfoRootViewController, perform action: CallAction)
    func infoRootViewController(_ viewController: CallInfoRootViewController, contextDidChange context: CallInfoRootViewController.Context)
}

final class CallInfoRootViewController: UIViewController, UINavigationControllerDelegate, CallInfoViewControllerDelegate, CallDegradationControllerDelegate {
    
    enum Context {
        case overview, participants
    }

    weak var delegate: CallInfoRootViewControllerDelegate?
    private let contentController: CallInfoViewController
    private let contentNavigationController: UINavigationController
    private let callDegradationController: CallDegradationController
    
    var context: Context = .overview {
        didSet {
            delegate?.infoRootViewController(self, contextDidChange: context)
        }
    }
    
    var configuration: CallInfoViewControllerInput {
        didSet {
            guard !configuration.isEqual(toConfiguration: oldValue) else { return }
            updateConfiguration(animated: true)
        }
    }
    
    init(configuration: CallInfoViewControllerInput) {
        self.configuration = configuration
        contentController = CallInfoViewController(configuration: configuration)
        contentNavigationController = contentController.wrapInNavigationController()
        callDegradationController = CallDegradationController()
        
        super.init(nibName: nil, bundle: nil)
        
        callDegradationController.targetViewController = self
        callDegradationController.state = configuration.degradationState
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        createConstraints()
        updateConfiguration()
    }
        
    private func setupViews() {
        addToSelf(contentNavigationController)
        addToSelf(callDegradationController)
        contentController.delegate = self
        contentNavigationController.delegate = self
        callDegradationController.delegate = self
    }
    
    private func createConstraints() {
        contentNavigationController.view.fitInSuperview()
        callDegradationController.view.fitInSuperview()
    }
    
    private func updateConfiguration(animated: Bool = false) {
        callDegradationController.state = configuration.degradationState
        contentController.configuration = configuration
        contentNavigationController.navigationBar.tintColor = UIColor(scheme: .textForeground, variant: configuration.effectiveColorVariant)
        contentNavigationController.navigationBar.isTranslucent = true
        contentNavigationController.navigationBar.barTintColor = .clear
        contentNavigationController.navigationBar.setBackgroundImage(UIImage.singlePixelImage(with: .clear), for: .default)
        
        UIView.animate(withDuration: 0.2) { [view, configuration] in
            view?.backgroundColor = configuration.overlayBackgroundColor
        }
    }
    
    private func presentParticipantsList() {
        context = .participants
        let participantsList = CallParticipantsViewController(scrollableWithConfiguration: configuration)
        contentNavigationController.pushViewController(participantsList, animated: true)
    }
    
    // MARK: - Delegates
    
    func infoViewController(_ viewController: CallInfoViewController, perform action: CallAction) {
        switch (action, configuration.degradationState) {
        case (.showParticipantsList, _): presentParticipantsList()
        case (.acceptCall, .incoming): delegate?.infoRootViewController(self, perform: .acceptDegradedCall)
        default: delegate?.infoRootViewController(self, perform: action)
        }
    }
    
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        guard viewController is CallInfoViewController else { return }
        context = .overview
    }
    
    func continueDegradedCall() {
        delegate?.infoRootViewController(self, perform: .continueDegradedCall)
    }
    
    func cancelDegradedCall() {
        delegate?.infoRootViewController(self, perform: .terminateDegradedCall)
    }

}
