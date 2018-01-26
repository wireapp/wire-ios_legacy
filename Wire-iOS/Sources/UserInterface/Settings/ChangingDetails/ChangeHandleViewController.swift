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
import Classy

fileprivate extension UIView {

    func wiggle() {
        let animation = CAKeyframeAnimation()
        animation.keyPath = "position.x"
        animation.duration = 0.3
        animation.isAdditive = true
        animation.values = [0, 4, -4, 2, 0]
        animation.keyTimes = [0, 0.166, 0.5, 0.833, 1]
        layer.add(animation, forKey: "wiggle-animation")
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
        handleTextField.accessibilityLabel = "handleTextField"
        handleTextField.autocorrectionType = .no
        handleTextField.spellCheckingType = .no
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
        [handleTextField, prefixLabel].forEach {
            $0.wiggle()
        }
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

/// This struct represents the current state of a handle
/// change operation and performs necessary validation steps of
/// a new handle. The `ChangeHandleViewController` uses this state 
/// to layout its interface.
struct HandleChangeState {

    enum ValidationError: Error {
        case tooShort, tooLong, invalidCharacter, sameAsPrevious
    }

    enum HandleAvailability {
        case unknown, available, taken
    }

    let currentHandle: String?
    private(set) var newHandle: String?
    var availability: HandleAvailability

    var displayHandle: String? {
        return newHandle ?? currentHandle
    }

    init(currentHandle: String?, newHandle: String?, availability: HandleAvailability) {
        self.currentHandle = currentHandle
        self.newHandle = newHandle
        self.availability = availability
    }

    private static var allowedCharacters: CharacterSet = {
        return CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz_").union(.decimalDigits)
    }()

    private static var allowedLength: CountableClosedRange<Int> {
        return 2...21
    }

    /// Validates the passed in handle and updates the state if
    /// no error occurs, otherwise a `ValidationError` will be thrown.
    mutating func update(_ handle: String) throws {
        availability = .unknown
        try validate(handle)
        newHandle = handle
    }

    /// Validation a new handle, if passed in handle
    /// is invalid, an error will be thrown.
    /// This function does not update the `HandleChangeState` itself.
    func validate(_ handle: String) throws {
        let subset = CharacterSet(charactersIn: handle).isSubset(of: HandleChangeState.allowedCharacters)
        guard subset && handle.isEqualToUnicodeName else { throw ValidationError.invalidCharacter }
        guard handle.count >= HandleChangeState.allowedLength.lowerBound else { throw ValidationError.tooShort }
        guard handle.count <= HandleChangeState.allowedLength.upperBound else { throw ValidationError.tooLong }
        guard handle != currentHandle else { throw ValidationError.sameAsPrevious }
    }

}


final class ChangeHandleViewController: SettingsBaseTableViewController {

    public var footerFont: UIFont?
    var state: HandleChangeState
    private var footerLabel = UILabel()
    fileprivate weak var userProfile = ZMUserSession.shared()?.userProfile
    private var observerToken: Any?
    var popOnSuccess = true

    convenience init() {
        self.init(state: HandleChangeState(currentHandle: ZMUser.selfUser().handle ?? nil, newHandle: nil, availability: .unknown))
    }

    convenience init(suggestedHandle handle: String) {
        self.init(state: .init(currentHandle: nil, newHandle: handle, availability: .unknown))
        setupViews()
        checkAvailability(of: handle)
    }

    /// Used to inject a specific `HandleChangeState` in tests. See `ChangeHandleViewControllerTests`.
    init(state: HandleChangeState) {
        self.state = state
        super.init(style: .grouped)
        CASStyler.default().styleItem(self)
        setupViews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateUI()
        observerToken = userProfile?.add(observer: self)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        observerToken = nil
    }

    private func setupViews() {
        title = "self.settings.account_section.handle.change.title".localized
        view.backgroundColor = .clear
        ChangeHandleTableViewCell.register(in: tableView)
        tableView.allowsSelection = false
        tableView.isScrollEnabled = false
        tableView.separatorStyle = .singleLine
        tableView.separatorColor = UIColor(white: 1, alpha: 0.08)
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
        guard let handleToSet = state.newHandle else { return }
        userProfile?.requestSettingHandle(handle: handleToSet)
        showLoadingView = true
    }

    fileprivate var attributedFooterTitle: NSAttributedString? {
        let infoText = "self.settings.account_section.handle.change.footer".localized.attributedString && UIColor(white: 1, alpha: 0.4)
        let alreadyTakenText = "self.settings.account_section.handle.change.footer.unavailable".localized && UIColor(for: .vividRed)
        let prefix = state.availability == .taken ? alreadyTakenText + "\n\n" : "\n\n".attributedString
        return (prefix + infoText) && footerFont
    }

    private func updateFooter() {
        footerLabel.attributedText = attributedFooterTitle
        let size = footerLabel.sizeThatFits(CGSize(width: view.frame.width - 32, height: UIViewNoIntrinsicMetric))
        footerLabel.frame = CGRect(origin: CGPoint(x: 16, y: 0), size: size)
        tableView.tableFooterView = footerLabel
    }

    private func updateNavigationItem() {
        navigationItem.rightBarButtonItem?.isEnabled = state.availability == .available
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
        cell.handleTextField.becomeFirstResponder()
        return cell
    }

}


extension ChangeHandleViewController: ChangeHandleTableViewCellDelegate {

    func tableViewCell(cell: ChangeHandleTableViewCell, shouldAllowEditingText text: String) -> Bool {
        do {
            /// We validate the new handle and only allow the edit if
            /// the new handle neither contains invalid characters nor is too long.
            try state.validate(text)
            return true
        } catch HandleChangeState.ValidationError.invalidCharacter {
            return false
        } catch HandleChangeState.ValidationError.tooLong {
            return false
        } catch {
            return true
        }
    }

    func tableViewCellDidChangeText(cell: ChangeHandleTableViewCell, text: String) {
        do {
            NSObject.cancelPreviousPerformRequests(withTarget: self)
            try state.update(text)
            perform(#selector(checkAvailability), with: text, afterDelay: 0.2)
        } catch {
            // no-op
        }

        updateUI()
    }

    @objc fileprivate func checkAvailability(of handle: String) {
        userProfile?.requestCheckHandleAvailability(handle: handle)
    }

}

extension ChangeHandleViewController: UserProfileUpdateObserver {

    func didCheckAvailiabilityOfHandle(handle: String, available: Bool) {
        guard handle == state.newHandle else { return }
        state.availability = available ? .available : .taken
        updateUI()
    }

    func didFailToCheckAvailabilityOfHandle(handle: String) {
        guard handle == state.newHandle else { return }
        // If we fail to check we let the user check again by tapping the save button
        state.availability = .available
        updateUI()
    }

    func didSetHandle() {
        showLoadingView = false
        state.availability = .taken
        Analytics.shared().tag(UserNameEvent.Settings.setUsername(withLength: state.newHandle?.count ?? 0))
        guard popOnSuccess else { return }
        _ = navigationController?.popViewController(animated: true)
    }

    func didFailToSetHandle() {
        presentFailureAlert()
        showLoadingView = false
    }

    func didFailToSetHandleBecauseExisting() {
        state.availability = .taken
        updateUI()
        showLoadingView = false
    }

    private func presentFailureAlert() {
        let alert = UIAlertController(
            title: "self.settings.account_section.handle.change.failure_alert.title".localized,
            message: "self.settings.account_section.handle.change.failure_alert.message".localized,
            preferredStyle: .alert
        )

        alert.addAction(.init(title: "general.ok".localized, style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}

fileprivate extension String {

    var isEqualToUnicodeName: Bool {
        if #available(iOS 9, *) {
            return applyingTransform(.toUnicodeName, reverse: false) == self
        } else {
            let ref = NSMutableString(string: self) as CFMutableString
            CFStringTransform(ref, nil, kCFStringTransformToUnicodeName, false)
            return ref as String == self
        }
    }
    
}
