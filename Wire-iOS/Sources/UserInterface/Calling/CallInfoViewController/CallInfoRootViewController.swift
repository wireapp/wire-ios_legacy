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
}

final class CallInfoRootViewController: UIViewController, CallInfoViewControllerDelegate {

    weak var delegate: CallInfoRootViewControllerDelegate?
    private let contentController: CallInfoViewController
    private let contentNavigationController: UINavigationController
    
    var configuration: CallInfoConfiguration {
        didSet {
            updateConfiguration(animated: true)
        }
    }
    
    init(configuration: CallInfoConfiguration) {
        self.configuration = configuration
        contentController = CallInfoViewController(configuration: configuration)
        contentNavigationController = contentController.wrapInNavigationController()
        super.init(nibName: nil, bundle: nil)
        contentController.delegate = self
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
        addChildViewController(contentNavigationController)
        view.addSubview(contentNavigationController.view)
        contentNavigationController.didMove(toParentViewController: self)
    }
    
    private func createConstraints() {
        NSLayoutConstraint.activate([
            contentNavigationController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentNavigationController.view.topAnchor.constraint(equalTo: view.topAnchor),
            contentNavigationController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentNavigationController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
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

}
