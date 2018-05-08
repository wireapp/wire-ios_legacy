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

final class CallInfoRootViewController: UIViewController, UINavigationControllerDelegate, CallInfoViewControllerDelegate {
    
    enum Context {
        case overview, participants
    }

    weak var delegate: CallInfoRootViewControllerDelegate?
    private let contentController: CallInfoViewController
    private let contentNavigationController: UINavigationController

    var context: Context = .overview {
        didSet {
            delegate?.infoRootViewController(self, contextDidChange: context)
        }
    }
    
    var configuration: CallInfoViewControllerInput {
        didSet {
            updateConfiguration(animated: true)
        }
    }
    
    init(configuration: CallInfoViewControllerInput) {
        self.configuration = configuration
        contentController = CallInfoViewController(configuration: configuration)
        contentNavigationController = contentController.wrapInNavigationController()
        super.init(nibName: nil, bundle: nil)
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
        contentController.delegate = self
        contentNavigationController.delegate = self
    }
    
    private func createConstraints() {
        contentNavigationController.view.fitInSuperview()
    }
    
    private func updateConfiguration(animated: Bool = false) {
        contentController.configuration = configuration
        contentNavigationController.navigationBar.tintColor = .wr_color(fromColorScheme: ColorSchemeColorTextForeground, variant: configuration.effectiveColorVariant)
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
        switch action {
        case .showParticipantsList: presentParticipantsList()
        default: delegate?.infoRootViewController(self, perform: action)
        }
    }
    
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        guard viewController is CallInfoViewController else { return }
        context = .overview
    }

}
