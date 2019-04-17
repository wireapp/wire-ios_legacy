//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

class AvailabilityTitleViewController: UIViewController {
    
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let options: AvailabilityTitleView.Options
    private let user: GenericUser
    
    var availabilityTitleView: AvailabilityTitleView? {
        return view as? AvailabilityTitleView
    }
    
    init(user: GenericUser, options: AvailabilityTitleView.Options) {
        self.user = user
        self.options = options
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = AvailabilityTitleView(user: user, options: options)
    }
    
    override func viewDidLoad() {
        availabilityTitleView?.tapHandler = { [weak self] button in
            self?.presentAvailabilityPicker()
        }
    }
    
    func presentAvailabilityPicker() {
        let alertViewController = UIAlertController.availabilityPicker { [weak self] (availability) in
            self?.didSelectAvailability(availability)
        }
        alertViewController.popoverPresentationController?.sourceView = view
        alertViewController.popoverPresentationController?.sourceRect = view.frame
        
        self.present(alertViewController, animated: true)
    }
    
    private func didSelectAvailability(_ availability: Availability) {
        let changes = { [weak self] in
            self?.user.availability = availability
            self?.provideHapticFeedback()
        }
        
        if let session = ZMUserSession.shared() {
            session.performChanges(changes)
        } else {
            changes()
        }
        
        if Settings.shared()?.shouldRemindUserWhenChanging(availability) == true {
            present(UIAlertController.availabilityExplanation(availability), animated: true)
        }
    }
    
    private func provideHapticFeedback() {
        feedbackGenerator.prepare()
        feedbackGenerator.impactOccurred()
    }
    
}
