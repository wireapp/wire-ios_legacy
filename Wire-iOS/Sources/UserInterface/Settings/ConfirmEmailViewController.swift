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
import ZMCDataModel

final class ShortLabelTableViewCell: UITableViewCell {
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        let clearView = UIView()
        clearView.backgroundColor = UIColor(white: 0, alpha: 0.2)
        selectedBackgroundView = clearView
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class ConfirmEmailDescriptionView: UIView {
    let descriptionLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        descriptionLabel.text = "self.settings.account_section.email.change.verify.description".localized
        descriptionLabel.numberOfLines = 0
        descriptionLabel.lineBreakMode = .byWordWrapping
        addSubview(descriptionLabel)
        
        constrain(self, descriptionLabel) { container, label in
            label.trailing <= container.trailing - 16
            label.leading >= container.leading + 16
            label.top == container.top + 24
            label.bottom == container.bottom - 24
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

protocol ConfirmEmailDelegate: class {
    func resendVerification(inController controller: ConfirmEmailViewController)
    func didConfirmEmail(inController controller: ConfirmEmailViewController)
}

final class ConfirmEmailViewController: SettingsBaseTableViewController {
    fileprivate weak var userProfile = ZMUserSession.shared()?.userProfile
    weak var delegate: ConfirmEmailDelegate?
    let newEmail: String
    fileprivate var observer: UserCollectionObserverToken?

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
        let context = ZMUserSession.shared()?.managedObjectContext
        observer = UserCollectionObserverToken(observer: self, users: [ZMUser.selfUser()], managedObjectContext: context!)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        observer?.tearDown()
    }

    internal func setupViews() {
        ShortLabelTableViewCell.register(in: tableView)
        
        title = "self.settings.account_section.email.change.verify.title".localized
        view.backgroundColor = .clear
        tableView.isScrollEnabled = false
        
        tableView.sectionHeaderHeight = UITableViewAutomaticDimension
        tableView.estimatedSectionHeaderHeight = 60;
        tableView.contentInset = UIEdgeInsets(top: -32, left: 0, bottom: 0, right: 0)
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let description = ConfirmEmailDescriptionView()
        return description
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ShortLabelTableViewCell.zm_reuseIdentifier, for: indexPath)
        let format = "self.settings.account_section.email.change.verify.resend".localized
        let text = String(format: format, newEmail)
        cell.textLabel?.text = text
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.resendVerification(inController: self)
        tableView.deselectRow(at: indexPath, animated: false)
    }
}

extension ConfirmEmailViewController: ZMUserObserver {
    func userDidChange(_ note: ZMCDataModel.UserChangeInfo!) {
        if note.user.isSelfUser {
            // we need to check if the notification really happened because 
            // the email got changed to what we expected
            if let currentEmail = ZMUser.selfUser().emailAddress, currentEmail == newEmail {
                delegate?.didConfirmEmail(inController: self)
            }
        }
    }
}
