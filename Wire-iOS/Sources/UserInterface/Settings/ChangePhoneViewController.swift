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

final class ChangePhoneViewController: UIViewController {
    let phoneController: PhoneNumberViewController
    
    init() {
        phoneController = PhoneNumberViewController()
        super.init(nibName: nil, bundle: nil)
        setupViews()
        createConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews() {
        title = "self.settings.account_section.phone_number.change.title".localized
        
        phoneController.willMove(toParentViewController: self)
        view.addSubview(phoneController.view)
        addChildViewController(phoneController)
        
        view.backgroundColor = .clear
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "self.settings.account_section.phone_number.change.save".localized,
            style: .done,
            target: self,
            action: #selector(saveButtonTapped)
        )
    }
    
    func createConstraints() {
        constrain(view, phoneController.view) { view, phoneView in
            phoneView.top == view.top + 44 + 16
            phoneView.leading == view.leading + 16
            phoneView.trailing == view.trailing - 16
        }
        
    }
    
    func saveButtonTapped() {
        
    }
    

}
