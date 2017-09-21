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
import Classy
import Cartography
import WireDataModel

protocol ConfirmEmailDelegate: class {
    func resendVerification(inController controller: ConfirmEmailViewController)
    func didConfirmEmail(inController controller: ConfirmEmailViewController)
}

final class ConfirmEmailViewController: SettingsBaseTableViewController {
    fileprivate weak var userProfile = ZMUserSession.shared()?.userProfile
    weak var delegate: ConfirmEmailDelegate?

    let newEmail: String
    fileprivate var observer: NSObjectProtocol?

    init(newEmail: String, delegate: ConfirmEmailDelegate?) {
        self.newEmail = newEmail
        self.delegate = delegate
        super.init(style: .grouped)
        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        observer = UserChangeInfo.add(observer: self, forBareUser: ZMUser.selfUser(), userSession: ZMUserSession.shared()!)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        observer = nil
    }

    internal func setupViews() {
        SettingsButtonCell.register(in: tableView)
        
        title = "self.settings.account_section.email.change.verify.title".localized
        view.backgroundColor = .clear
        tableView.isScrollEnabled = false
        
        tableView.sectionHeaderHeight = UITableViewAutomaticDimension
        tableView.estimatedSectionHeaderHeight = 60;
        tableView.contentInset = UIEdgeInsets(top: -32, left: 0, bottom: 0, right: 0)
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let description = DescriptionHeaderView()
        description.descriptionLabel.text = "self.settings.account_section.email.change.verify.description".localized

        return description
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SettingsButtonCell.zm_reuseIdentifier, for: indexPath) as! SettingsButtonCell
        let format = "self.settings.account_section.email.change.verify.resend".localized
        let text = String(format: format, newEmail)
        cell.titleText = text
        cell.titleColor = .white
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.resendVerification(inController: self)
        tableView.deselectRow(at: indexPath, animated: false)
        
        let message = String(format: "self.settings.account_section.email.change.resend.message".localized, newEmail)
        let alert = UIAlertController(
            title: "self.settings.account_section.email.change.resend.title".localized,
            message: message,
            preferredStyle: .alert
        )
        
        alert.addAction(.init(title: "general.ok".localized, style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}

extension ConfirmEmailViewController: ZMUserObserver {
    func userDidChange(_ note: WireDataModel.UserChangeInfo) {
        if note.user.isSelfUser {
            // we need to check if the notification really happened because 
            // the email got changed to what we expected
            if let currentEmail = ZMUser.selfUser().emailAddress, currentEmail == newEmail {
                delegate?.didConfirmEmail(inController: self)
            }
        }
    }
}
