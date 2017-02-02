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
import zmessaging

protocol ConfirmPhoneDelegate: class {
    func resendVerificationCode(inController controller: ConfirmPhoneViewController)
    func didConfirmPhone(inController controller: ConfirmPhoneViewController)
}

fileprivate enum Section: Int {
    static var count: Int {
        return 2
    }
    
    var itemCount: Int {
        switch self {
        case .verificationCode:
            return 1
        case .buttons:
            return 2
        }
    }
    
    case verificationCode = 0
    case buttons = 1
    
    enum Buttons: Int {
        case resend = 0
        case callMe = 1
    }
}

final class ConfirmPhoneViewController: SettingsBaseTableViewController {
    fileprivate weak var userProfile = ZMUserSession.shared()?.userProfile
    weak var delegate: ConfirmPhoneDelegate?
    let newNumber: String
    fileprivate var observer: UserCollectionObserverToken?
    var verificationCode: String?
    
    init(newNumber: String, delegate: ConfirmPhoneDelegate?) {
        self.newNumber = newNumber
        self.delegate = delegate
        super.init(style: .grouped)
        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let context = ZMUserSession.shared()?.managedObjectContext
        observer = UserCollectionObserverToken(observer: self, users: [ZMUser.selfUser()], managedObjectContext: context!)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        observer?.tearDown()
    }
    
    internal func setupViews() {
        ShortLabelTableViewCell.register(in: tableView)
        
        title = "self.settings.account_section.phone_number.change.verify.title".localized
        view.backgroundColor = .clear
        tableView.isScrollEnabled = false
        
        tableView.sectionHeaderHeight = UITableViewAutomaticDimension
        tableView.estimatedSectionHeaderHeight = 60;
        tableView.contentInset = UIEdgeInsets(top: -32, left: 0, bottom: 0, right: 0)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "self.settings.account_section.phone_number.change.verify.save".localized,
            style: .done,
            target: self,
            action: #selector(saveButtonTapped)
        )
    }
    
    func saveButtonTapped() {
        if let verificationCode = verificationCode {
            let credentials = ZMPhoneCredentials(phoneNumber: newNumber, verificationCode: verificationCode)
            userProfile?.requestPhoneNumberChange(credentials: credentials)
            showLoadingView = true
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return Section.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Section(rawValue: section)!.itemCount
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        switch Section(rawValue: section)! {
        case .verificationCode:
            let description = DescriptionHeaderView()
            let format = "self.settings.account_section.phone_number.change.verify.description".localized
            description.descriptionLabel.text = String(format: format, newNumber)
            return description
        case .buttons:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch Section(rawValue: indexPath.section)! {
        case .verificationCode:
            let cell = tableView.dequeueReusableCell(withIdentifier: ShortLabelTableViewCell.zm_reuseIdentifier, for: indexPath)
            
            let format = "self.settings.account_section.email.change.verify.resend".localized
            let text = String(format: format, newNumber)
            cell.textLabel?.text = text
            return cell
        case .buttons:
            let cell = tableView.dequeueReusableCell(withIdentifier: ShortLabelTableViewCell.zm_reuseIdentifier, for: indexPath)

            switch Section.Buttons(rawValue: indexPath.row)! {
            case .resend:
                cell.textLabel?.text = "self.settings.account_section.phone_number.change.verify.resend".localized
            case .callMe:
                cell.textLabel?.text = "self.settings.account_section.phone_number.change.verify.call".localized

            }

            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch Section(rawValue: indexPath.section)! {
        case .verificationCode:
            break
        case .buttons:
            switch Section.Buttons(rawValue: indexPath.row)! {
            case .resend:
                delegate?.resendVerificationCode(inController: self)
                let message = String(format: "self.settings.account_section.phone_number.change.resend.message".localized, newNumber)
                let alert = UIAlertController(
                    title: "self.settings.account_section.phone_number.change.resend.title".localized,
                    message: message,
                    preferredStyle: .alert
                )
                
                alert.addAction(.init(title: "general.ok".localized, style: .cancel, handler: nil))
                present(alert, animated: true, completion: nil)
            case .callMe:
                break
            }
        }
        tableView.deselectRow(at: indexPath, animated: false)
    }
}

extension ConfirmPhoneViewController: ZMUserObserver {
    
    func userDidChange(_ note: ZMCDataModel.UserChangeInfo!) {
        if note.user.isSelfUser {
            // we need to check if the notification really happened because
            // the phone got changed to what we expected
            if let currentPhoneNumber = ZMUser.selfUser().phoneNumber, currentPhoneNumber == newNumber {
                delegate?.didConfirmPhone(inController: self)
            }
        }
    }
}

extension ConfirmPhoneViewController: UserProfileUpdateObserver {
    func phoneNumberChangeDidFail(_ error: Error!) {
        
    }
}
