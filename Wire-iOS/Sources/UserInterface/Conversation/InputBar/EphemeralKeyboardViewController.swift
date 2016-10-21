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
import Cartography


protocol EphemeralKeyboardViewControllerDelegate: class {
    func ephemeralKeyboardWantsToBeDismissed(_ keyboard: EphemeralKeyboardViewController)

    func ephemeralKeyboard(
        _ keyboard: EphemeralKeyboardViewController,
        didSelectMessageTimeout timeout: ZMConversationMessageDestructionTimeout
    )
}


fileprivate let longStyleFormatter: DateComponentsFormatter = {
    let formatter = DateComponentsFormatter()
    formatter.unitsStyle = .full
    formatter.allowedUnits = [.day, .hour, .minute, .second]
    formatter.zeroFormattingBehavior = .dropAll
    return formatter
}()


extension ZMConversationMessageDestructionTimeout {

    var displayString: String? {
        guard .none != self else { return "input.ephemeral.timeout.none".localized }
        return longStyleFormatter.string(from: TimeInterval(rawValue))
    }

    var shortDisplayString: String? {
        if isSeconds { return String(Int(rawValue)) }
        if isMinutes { return String(Int(rawValue / 60)) }
        if isHours { return String(Int(rawValue / 3600)) }
        if isDays { return String(Int(rawValue / 86400)) }
        return nil
    }

}


extension ZMConversationMessageDestructionTimeout {

    var isSeconds: Bool {
        return rawValue < 60
    }

    var isMinutes: Bool {
        return 60..<3600 ~= rawValue
     }

    var isHours: Bool {
        return 3600..<86400 ~= rawValue
    }

    var isDays: Bool {
        return rawValue >= 86400
    }

}

public extension ZMConversation {

    var timeoutImage: UIImage? {
        if destructionTimeout.isDays { return WireStyleKit.imageOfDay() }
        if destructionTimeout.isHours { return WireStyleKit.imageOfHour() }
        if destructionTimeout.isMinutes { return WireStyleKit.imageOfMinute() }
        if destructionTimeout.isSeconds { return WireStyleKit.imageOfSecond() }
        return nil
    }

}


@objc public final class EphemeralKeyboardViewController: UIViewController {

    weak var delegate: EphemeralKeyboardViewControllerDelegate?

    fileprivate let timeouts = ZMConversationMessageDestructionTimeout.all

    public let titleLabel = UILabel()
    public var pickerFont: UIFont?
    public var pickerColor: UIColor?
    public var separatorColor: UIColor?

    private let conversation: ZMConversation
    private let picker = PickerView()


    public init(conversation: ZMConversation) {
        self.conversation = conversation
        super.init(nibName: nil, bundle: nil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        createConstraints()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        guard let index = timeouts.index(of: conversation.destructionTimeout) else { return }
        picker.selectRow(index, inComponent: 0, animated: false)
    }

    private func setupViews() {
        CASStyler.default().styleItem(self)
        picker.delegate = self
        picker.dataSource = self
        picker.tintColor = .red
        picker.showsSelectionIndicator = true
        picker.selectorColor = separatorColor
        picker.didTapViewClosure = dismissKeyboardIfNeeded

        titleLabel.textAlignment = .center
        titleLabel.text = "input.ephemeral.title".localized.uppercased()
        [titleLabel, picker].forEach(view.addSubview)
    }

    func dismissKeyboardIfNeeded() {
        delegate?.ephemeralKeyboardWantsToBeDismissed(self)
    }

    private func createConstraints() {
        let inset = CGPoint(x: 32, y: 16)
        constrain(view, picker, titleLabel) { view, picker, label in
            label.leading == view.leading
            label.trailing == view.trailing
            label.top == view.top + inset.y
            picker.top == label.bottom + inset.y
            picker.bottom <= view.bottom - inset.y
            picker.leading == view.leading + inset.x
            picker.trailing == view.trailing - inset.x
        }
    }

}


/// This class is a workaround to make the selector color
/// of a `UIPickerView` changeable. It relies on the height of the selector
/// views, which means that the behaviour could break in future iOS updates.
class PickerView: UIPickerView, UIGestureRecognizerDelegate {

    var selectorColor: UIColor? = nil
    var tapRecognizer: UIGestureRecognizer! = nil
    var didTapViewClosure: (() -> Void)? = nil

    init() {
        super.init(frame: .zero)
        tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapView))
        tapRecognizer.delegate = self
        addGestureRecognizer(tapRecognizer)
    }
    
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
        guard let font = pickerFont, let color = pickerColor, let title = timeouts[row].displayString else { return nil }
        return title && font && color
    }

    public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        delegate?.ephemeralKeyboard(self, didSelectMessageTimeout: timeouts[row])
    }
    
}
