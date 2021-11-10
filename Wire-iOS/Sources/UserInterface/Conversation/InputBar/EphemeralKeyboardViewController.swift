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

import UIKit
import WireCommonComponents
import WireDataModel

protocol EphemeralKeyboardViewControllerDelegate: class {
    func ephemeralKeyboardWantsToBeDismissed(_ keyboard: EphemeralKeyboardViewController)

    func ephemeralKeyboard(
        _ keyboard: EphemeralKeyboardViewController,
        didSelectMessageTimeout timeout: TimeInterval
    )
}

extension InputBarConversation {

    var timeoutImage: UIImage? {
        guard let timeout = activeMessageDestructionTimeoutValue else { return nil }
        return timeoutImage(for: timeout)
    }

    var disabledTimeoutImage: UIImage? {
        guard let timeout = activeMessageDestructionTimeoutValue else { return nil }
        return timeoutImage(for: timeout, withColor: .lightGraphite)
    }

    private func timeoutImage(for timeout: MessageDestructionTimeoutValue, withColor color: UIColor = UIColor.accent()) -> UIImage? {
        guard timeout != .none else { return nil }
        if timeout.isYears { return StyleKitIcon.timeoutYear.makeImage(size: 64, color: color) }
        if timeout.isWeeks { return StyleKitIcon.timeoutWeek.makeImage(size: 64, color: color) }
        if timeout.isDays { return StyleKitIcon.timeoutDay.makeImage(size: 64, color: color) }
        if timeout.isHours { return StyleKitIcon.timeoutHour.makeImage(size: 64, color: color) }
        if timeout.isMinutes { return StyleKitIcon.timeoutMinute.makeImage(size: 64, color: color) }
        if timeout.isSeconds { return StyleKitIcon.timeoutSecond.makeImage(size: 64, color: color) }
        return nil
    }
}

extension UIAlertController {
    enum AlertError: Error {
        case userRejected
    }

    static func requestCustomTimeInterval(over controller: UIViewController,
                                          with completion: @escaping (Result<TimeInterval>) -> Void) {
        let alertController = UIAlertController(title: "Custom timer", message: nil, preferredStyle: .alert)
        alertController.addTextField { (textField: UITextField) in
            textField.keyboardType = .decimalPad
            textField.placeholder = "Time interval in seconds"
        }
        let confirmAction = UIAlertAction(title: "OK", style: .default) { [weak alertController] _ in
            guard let input = alertController?.textFields?.first,
                let inputText = input.text,
                let selectedTimeInterval = TimeInterval(inputText) else {
                    return
            }

            completion(.success(selectedTimeInterval))
        }

        alertController.addAction(confirmAction)

        let cancelAction = UIAlertAction.cancel {
            completion(.failure(AlertError.userRejected))
        }

        alertController.addAction(cancelAction)
        controller.present(alertController, animated: true) { [weak alertController] in
            guard let input = alertController?.textFields?.first else {
                return
            }

            input.becomeFirstResponder()
        }
    }
}

final class EphemeralKeyboardViewController: UIViewController {

    weak var delegate: EphemeralKeyboardViewControllerDelegate?

    fileprivate let timeouts: [MessageDestructionTimeoutValue?]

    public let titleLabel = UILabel()
    public var pickerFont: UIFont? = .normalSemiboldFont
    public var pickerColor: UIColor? = UIColor.from(scheme: .textForeground, variant: .dark)
    public var separatorColor: UIColor? = UIColor.from(scheme: .separator, variant: .light)

    private let conversation: ZMConversation!
    private let picker = PickerView()

    /// Allow conversation argument is nil for testing
    ///
    /// - Parameter conversation: nil for testing only
    public init(conversation: ZMConversation!) {
        self.conversation = conversation
        if Bundle.developerModeEnabled {
            timeouts = MessageDestructionTimeoutValue.all + [nil]
        }
        else {
            timeouts = MessageDestructionTimeoutValue.all
        }
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        createConstraints()

        view.backgroundColor = UIColor.from(scheme: .textForeground, variant: .light)
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let currentTimeout = conversation.messageDestructionTimeoutValue(for: .selfUser)
        guard let index = timeouts.firstIndex(of: currentTimeout) else { return }
        picker.selectRow(index, inComponent: 0, animated: false)
    }

    private func setupViews() {

        picker.delegate = self
        picker.dataSource = self
        picker.backgroundColor = .clear
        picker.tintColor = .red
        picker.showsSelectionIndicator = true
        picker.selectorColor = separatorColor
        picker.didTapViewClosure = dismissKeyboardIfNeeded

        titleLabel.textAlignment = .center
        titleLabel.textColor = UIColor.from(scheme: .textForeground, variant: .dark)
        titleLabel.font = .smallSemiboldFont

        titleLabel.text = "input.ephemeral.title".localized(uppercased: true)
        titleLabel.numberOfLines = 0
        [titleLabel, picker].forEach(view.addSubview)
    }

    func dismissKeyboardIfNeeded() {
        delegate?.ephemeralKeyboardWantsToBeDismissed(self)
    }

    private func createConstraints() {
        [picker, titleLabel].prepareForLayout()
        NSLayoutConstraint.activate([
          titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
          titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
          titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
          picker.topAnchor.constraint(equalTo: titleLabel.bottomAnchor),
          picker.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -16),
          picker.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
          picker.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32)
        ])
    }

    fileprivate func displayCustomPicker() {
        delegate?.ephemeralKeyboardWantsToBeDismissed(self)

        UIAlertController.requestCustomTimeInterval(over: UIApplication.shared.topmostViewController(onlyFullScreen: true)!) { [weak self] result in

            guard let `self` = self else {
                return
            }

            switch result {
            case .success(let value):
                self.delegate?.ephemeralKeyboard(self, didSelectMessageTimeout: value)
            default:
                break
            }

        }
    }
}

/// This class is a workaround to make the selector color
/// of a `UIPickerView` changeable. It relies on the height of the selector
/// views, which means that the behaviour could break in future iOS updates.
class PickerView: UIPickerView, UIGestureRecognizerDelegate {

    var selectorColor: UIColor?
    var tapRecognizer: UIGestureRecognizer! = nil
    var didTapViewClosure: (() -> Void)?

    init() {
        super.init(frame: .zero)
        tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapView))
        tapRecognizer.delegate = self
        addGestureRecognizer(tapRecognizer)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        for subview in subviews where subview.bounds.height <= 1.0 {
            subview.backgroundColor = selectorColor
        }
    }

    @objc func didTapView(sender: UIGestureRecognizer) {
        guard recognizerInSelectedRow(sender) else { return }
        didTapViewClosure?()
    }

    /// Used to determine if the recognizers touches are in the area
    /// of the selected row of the `UIPickerView`, this is done by asking the
    /// delegate for the rowHeight and using it to caculate the rect 
    /// of the center (selected) row.
    private func recognizerInSelectedRow(_ recognizer: UIGestureRecognizer) -> Bool {
        guard selectedRow(inComponent: 0) != -1 else { return false }
        guard let height = delegate?.pickerView?(self, rowHeightForComponent: 0) else { return false }
        let rect = bounds.insetBy(dx: 0, dy: bounds.midY - height / 2)
        let location = recognizer.location(in: self)
        return rect.contains(location)
    }

    // MARK: - UIGestureRecognizerDelegate

    // We want the tapgesture recognizer to fire when the selected row is tapped,
    // but need to make sure the scrolling behaviour and taps outside the selected row still
    // get propagated (other wise the scroll-to behaviour would break when tapping on another row) etc.

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return gestureRecognizer == tapRecognizer && recognizerInSelectedRow(gestureRecognizer)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return otherGestureRecognizer == tapRecognizer && recognizerInSelectedRow(gestureRecognizer)
    }

}

extension EphemeralKeyboardViewController: UIPickerViewDelegate, UIPickerViewDataSource {

    public func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 35
    }

    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return timeouts.count
    }

    public func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        guard let font = pickerFont, let color = pickerColor else { return nil }
        let timeout = timeouts[row]
        if let actualTimeout = timeout, let title = actualTimeout.displayString {
            return title && font && color
        }
        else {
            return "Custom" && font && color
        }
    }

    public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let timeout = timeouts[row]

        if let actualTimeout = timeout {
            delegate?.ephemeralKeyboard(self, didSelectMessageTimeout: actualTimeout.rawValue)
        }
        else {
            displayCustomPicker()
        }
    }

}
