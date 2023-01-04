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
import UIKit
import WireSyncEngine

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

protocol ChangeHandleTableViewCellDelegate: AnyObject {
    func tableViewCell(cell: ChangeHandleTableViewCell, shouldAllowEditingText text: String) -> Bool
    func tableViewCellDidChangeText(cell: ChangeHandleTableViewCell, text: String)
}

final class ChangeHandleTableViewCell: UITableViewCell, UITextFieldDelegate {

    weak var delegate: ChangeHandleTableViewCellDelegate?
    let prefixLabel: UILabel = {
        let label = UILabel()
        label.font = .normalSemiboldFont
        label.textColor = SemanticColors.Label.textDefault

        return label
    }()

    let handleTextField: UITextField = {
        let textField = UITextField()
        textField.font = .normalFont
        textField.textColor = SemanticColors.Label.textDefault

        return textField
    }()

    let domainLabel: UILabel = {
        let label = UILabel()
        label.font = .normalSemiboldFont
        label.textColor = .gray
        label.setContentCompressionResistancePriority(.required, for: .horizontal)

        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        createConstraints()

        setupStyle()
    }

    func setupStyle() {
        backgroundColor = .clear
    }

    @available(*, unavailable)
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
        handleTextField.textAlignment = .right
        prefixLabel.text = "@"
        [prefixLabel, handleTextField, domainLabel].forEach(addSubview)
    }

    private func createConstraints() {
        [prefixLabel, handleTextField, domainLabel].prepareForLayout()

        NSLayoutConstraint.activate([
            prefixLabel.topAnchor.constraint(equalTo: topAnchor),
            prefixLabel.widthAnchor.constraint(equalToConstant: 16),
            prefixLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
            prefixLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            prefixLabel.trailingAnchor.constraint(equalTo: handleTextField.leadingAnchor, constant: -4),
            handleTextField.topAnchor.constraint(equalTo: topAnchor),
            handleTextField.bottomAnchor.constraint(equalTo: bottomAnchor),
            handleTextField.trailingAnchor.constraint(equalTo: domainLabel.leadingAnchor, constant: -4),
            domainLabel.topAnchor.constraint(equalTo: topAnchor),
            domainLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
            domainLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -16)
        ])
    }

    func performWiggleAnimation() {
        [handleTextField, prefixLabel].forEach {
            $0.wiggle()
        }
    }

    // MARK: - UITextField

    @objc func editingChanged(textField: UITextField) {
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
        return CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz_-.").union(.decimalDigits)
    }()

    private static var allowedLength: CountableClosedRange<Int> {
        return 2...256
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
    private typealias HandleChange = L10n.Localizable.Self.Settings.AccountSection.Handle.Change

    var footerFont: UIFont = .smallFont
    var state: HandleChangeState
    private var footerLabel = UILabel()
    fileprivate weak var userProfile = ZMUserSession.shared()?.userProfile
    private var observerToken: Any?
    var popOnSuccess = true
    private var federationEnabled: Bool

    convenience init() {
        self.init(state: HandleChangeState(currentHandle: SelfUser.current.handle ?? nil, newHandle: nil, availability: .unknown))
    }

    convenience init(suggestedHandle handle: String) {
        self.init(state: .init(currentHandle: nil, newHandle: handle, availability: .unknown))
        setupViews()
        checkAvailability(of: handle)
    }

    /// Used to inject a specific `HandleChangeState` in tests. See `ChangeHandleViewControllerTests`.
    init(state: HandleChangeState, federationEnabled: Bool = BackendInfo.isFederationEnabled) {
        self.state = state
        self.federationEnabled = federationEnabled
        super.init(style: .grouped)

        setupViews()
    }

    @available(*, unavailable)
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
        navigationItem.setupNavigationBarTitle(title: HandleChange.title.capitalized)
        view.backgroundColor = .clear
        ChangeHandleTableViewCell.register(in: tableView)
        tableView.allowsSelection = false
        tableView.isScrollEnabled = false
        tableView.separatorStyle = .singleLine
        tableView.separatorColor = SemanticColors.View.backgroundSeparatorCell
        footerLabel.numberOfLines = 0
        updateUI()

        let saveButtonItem: UIBarButtonItem = .createNavigationRightBarButtonItem(title: HandleChange.save.capitalized,
                                                                                  systemImage: false,
                                                                                  target: self,
                                                                                  action: #selector(saveButtonTapped))
        saveButtonItem.tintColor = .accent()
        navigationItem.rightBarButtonItem = saveButtonItem
    }

    @objc func saveButtonTapped(sender: UIBarButtonItem) {
        guard let handleToSet = state.newHandle else { return }
        userProfile?.requestSettingHandle(handle: handleToSet)
        isLoadingViewVisible = true
    }

    fileprivate var attributedFooterTitle: NSAttributedString? {
        let infoText = HandleChange.footer.attributedString && SemanticColors.Label.textSectionFooter
        let alreadyTakenText = HandleChange.Footer.unavailable && SemanticColors.Label.textErrorDefault
        let prefix = state.availability == .taken ? alreadyTakenText + "\n\n" : "\n\n".attributedString
        return (prefix + infoText) && footerFont
    }

    private func updateFooter() {
        footerLabel.attributedText = attributedFooterTitle
        let size = footerLabel.sizeThatFits(CGSize(width: view.frame.width - 32, height: UIView.noIntrinsicMetric))
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
        cell.domainLabel.isHidden = !federationEnabled
        cell.domainLabel.text = federationEnabled ? SelfUser.current.domainString : ""
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 56
    }
}

extension ChangeHandleViewController: ChangeHandleTableViewCellDelegate {

    func tableViewCell(cell: ChangeHandleTableViewCell, shouldAllowEditingText text: String) -> Bool {
        do {
            // We validate the new handle and only allow the edit if
            // the new handle neither contains invalid characters nor is too long.
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
        isLoadingViewVisible = false
        state.availability = .taken
        guard popOnSuccess else { return }
        _ = navigationController?.popViewController(animated: true)
    }

    func didFailToSetHandle() {
        presentFailureAlert()
        isLoadingViewVisible = false
    }

    func didFailToSetHandleBecauseExisting() {
        state.availability = .taken
        updateUI()
        isLoadingViewVisible = false
    }

    private func presentFailureAlert() {
        let alert = UIAlertController(
            title: HandleChange.FailureAlert.title,
            message: HandleChange.FailureAlert.message,
            preferredStyle: .alert
        )

        alert.addAction(.init(title: L10n.Localizable.General.ok, style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}

fileprivate extension String {

    var isEqualToUnicodeName: Bool {
        return applyingTransform(.toUnicodeName, reverse: false) == self
    }

}
