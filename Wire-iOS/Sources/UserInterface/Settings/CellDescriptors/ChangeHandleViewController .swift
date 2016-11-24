//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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
import Cartography


struct WiggleAnimator {

    static func wiggle(views: UIView...) {
        let animation = CAKeyframeAnimation()
        animation.keyPath = "position.x"
        animation.duration = 0.3
        animation.isAdditive = true
        animation.values = [0, 4, -4, 2, 0]
        animation.keyTimes = [0, 0.166, 0.5, 0.833, 1]
        views.forEach {
            $0.layer.add(animation, forKey: "wiggle-animation")
        }
    }

}


protocol ChangeHandleTableViewCellDelegate: class {
    func tableViewCell(cell: ChangeHandleTableViewCell, shouldAllowEditingText text: String) -> Bool
    func tableViewCellDidChangeText(cell: ChangeHandleTableViewCell, text: String)
}


final class ChangeHandleTableViewCell: UITableViewCell, UITextFieldDelegate {

    weak var delegate: ChangeHandleTableViewCellDelegate?
    let prefixLabel = UILabel()
    let handleTextField = UITextField()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        createConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupViews() {
        handleTextField.delegate = self
        handleTextField.addTarget(self, action: #selector(editingChanged), for: .editingChanged)
        handleTextField.autocapitalizationType = .none
        prefixLabel.text = "@"
        [prefixLabel, handleTextField].forEach(addSubview)
    }

    func createConstraints() {
        constrain(self, prefixLabel, handleTextField) { view, prefixLabel, textField in
            prefixLabel.top == view.top
            prefixLabel.width == 16
            prefixLabel.bottom == view.bottom
            prefixLabel.leading == view.leading + 16
            prefixLabel.trailing == textField.leading - 4
            textField.top == view.top
            textField.bottom == view.bottom
            textField.trailing == view.trailing - 16
        }
    }

    func performWiggleAnimation() {
        WiggleAnimator.wiggle(views: handleTextField, prefixLabel)
    }

    // MARK: - UITextField

    func editingChanged(textField: UITextField) {
        let lowercase = textField.text?.lowercased() ?? ""
        textField.text = lowercase
        delegate?.tableViewCellDidChangeText(cell: self, text: lowercase)
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let delegate = delegate else { return false }
        let current = (textField.text ?? "") as NSString
        let replacement = current.replacingCharacters(in: range, with: string)
        if delegate.tableViewCell(cell: self, shouldAllowEditingText: replacement) {
            return true
        }

        performWiggleAnimation()
        return false
    }
}


struct HandleChangeState {

    private static var allowedCharacters: CharacterSet = {
        return CharacterSet.decimalDigits.union(.letters).union(CharacterSet(charactersIn: "_"))
    }()

    enum ValidationError: Error {
        case lessThanTwoCharacters, invalidCharacter, sameAsPrevious
    }

    let currentHandle: String
    private(set) var newHandle: String? {
        didSet {
            available = false
        }
    }

    var available: Bool

    var displayHandle: String {
        return newHandle ?? currentHandle
    }

    mutating func update(handle: String) throws {
        try validate(handle: handle)
        newHandle = handle
    }

    private func validate(handle: String) throws {
        let subset = CharacterSet(charactersIn: handle).isSubset(of: HandleChangeState.allowedCharacters)
        guard subset else { throw ValidationError.invalidCharacter }
        guard handle.characters.count > 1 else { throw ValidationError.lessThanTwoCharacters }
        guard handle != currentHandle else { throw ValidationError.sameAsPrevious }
    }

}


final class ChangeHandleViewController: SettingsBaseTableViewController {

    var state: HandleChangeState
    private var footerLabel = UILabel()
    fileprivate weak var updateStatus = ZMUserSession.shared().userProfileUpdateStatus
    private var observerToken: AnyObject?


    convenience init() {
        self.init(state: HandleChangeState(currentHandle: ZMUser.selfUser().handle, newHandle: nil, available: true))
    }

    init(state: HandleChangeState) {
        self.state = state
        super.init(style: .grouped)
        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateFooter()
        observerToken = updateStatus?.add(observer: self)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let token = observerToken else { return }
        updateStatus?.removeObserver(token: token)
    }

    private func setupViews() {
        title = "self.settings.account_section.handle.change.title".localized
        tableView.allowsSelection = false
        ChangeHandleTableViewCell.register(in: tableView)
        footerLabel.numberOfLines = 0
        updateUI()

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "self.settings.account_section.handle.change.save".localized,
            style: .done,
            target: self,
            action: #selector(saveButtonTapped)
        )
    }

    func saveButtonTapped(sender: UIBarButtonItem) {
        // TODO: Set handle
    }

    fileprivate var attributedFooterTitle: NSAttributedString {
        let infoText = "self.settings.account_section.handle.change.footer".localized.attributedString && UIColor(white: 1, alpha: 0.4)
        let alreadyTakenText = "self.settings.account_section.handle.change.footer.unavailable".localized && UIColor(for: .vividRed)
        let prefix = !state.available ? alreadyTakenText + "\n\n" : "\n\n".attributedString
        return prefix + infoText
    }

    private func updateFooter() {
        footerLabel.attributedText = attributedFooterTitle
        let size = footerLabel.sizeThatFits(CGSize(width: view.frame.width - 32, height: UIViewNoIntrinsicMetric))
        footerLabel.frame = CGRect(origin: CGPoint(x: 16, y: 0), size: size)
        tableView.tableFooterView = footerLabel
    }

    private func updateNavigationItem() {
        navigationItem.rightBarButtonItem?.isEnabled = state.available
    }

    fileprivate func updateUI() {
        updateNavigationItem()
        updateFooter()
    }

    // MARK: - UITableView

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? 1 : 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ChangeHandleTableViewCell.zm_reuseIdentifier, for: indexPath) as! ChangeHandleTableViewCell
        cell.delegate = self
        cell.handleTextField.text = state.displayHandle
        return cell
    }

}


extension ChangeHandleViewController: ChangeHandleTableViewCellDelegate {

    func tableViewCell(cell: ChangeHandleTableViewCell, shouldAllowEditingText text: String) -> Bool {
        do {
            try state.update(handle: text)
            return true
        } catch HandleChangeState.ValidationError.invalidCharacter {
            return false
        } catch {
            return true
        }
    }

    func tableViewCellDidChangeText(cell: ChangeHandleTableViewCell, text: String) {
        do {
            try state.update(handle: text)
            updateStatus?.requestCheckHandleAvailability(handle: text)
        } catch {
            // no-op
        }

        updateUI()
    }

}

extension ChangeHandleViewController: UserProfileUpdateObserver {

    func didCheckAvailiabilityOfHandle(handle: String, available: Bool) {
        guard handle == state.newHandle else { return }
        state.available = available
        updateUI()
    }

    func didFailToCheckAvailabilityOfHandle(handle: String) {
        guard handle == state.newHandle else { return }
        state.available = false
        updateUI()
    }

}

