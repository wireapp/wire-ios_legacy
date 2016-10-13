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
    func ephemeralKeyboard(
        _ keyboard: EphemeralKeyboardViewController,
        didSelectMessageTimeout timeout: ZMConversationMessageDestructionTimeout
    )
}

fileprivate let longStyleFormatter: DateComponentsFormatter = {
    let formatter = DateComponentsFormatter()
    formatter.unitsStyle = .full
    formatter.allowedUnits = [.minute, .second]
    formatter.zeroFormattingBehavior = [.dropLeading, .dropTrailing]
    return formatter
}()

fileprivate let shortStyleFormatter: DateComponentsFormatter = {
    let formatter = DateComponentsFormatter()
    formatter.unitsStyle = .abbreviated
    formatter.allowedUnits = [.minute, .second]
    formatter.zeroFormattingBehavior = [.dropLeading, .dropTrailing]
    return formatter
}()

extension ZMConversationMessageDestructionTimeout {

    static var all: [ZMConversationMessageDestructionTimeout] {
        return [
            .none,
            .fiveSeconds,
            .fifteenSeconds,
            .oneMinute,
            .fiveMinutes,
            .fifteenMinutes
        ]
    }

    var displayString: String? {
        guard .none != self else { return "input.ephemeral.timeout.none".localized }
        return longStyleFormatter.string(from: TimeInterval(rawValue))
    }

    var shortDisplayString: String? {
        guard .none != self else { return nil }
        return shortStyleFormatter.string(from: TimeInterval(rawValue))
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

        titleLabel.textAlignment = .center
        titleLabel.text = "input.ephemeral.title".localized.uppercased()
        [titleLabel, picker].forEach(view.addSubview)
    }

    private func createConstraints() {
        let inset = CGPoint(x: 32, y: 16)
        constrain(view, picker, titleLabel) { view, picker, label in
            label.leading == view.leading
            label.trailing == view.trailing
            label.top == view.top + inset.y
            picker.top == label.bottom + inset.y
            picker.bottom == view.bottom - inset.y
            picker.leading == view.leading + inset.x
            picker.trailing == view.trailing - inset.x
        }
    }

}


/// This class is a workaround to make the selector color
/// of a `UIPickerView` changeable. It relies on the height of the selector
/// views, which means that the behaviour could break in future iOS updates.
class PickerView: UIPickerView {

    var selectorColor: UIColor? = nil

    override func layoutSubviews() {
        super.layoutSubviews()
        for subview in subviews where subview.bounds.height <= 1.0 {
            subview.backgroundColor = selectorColor
        }
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
