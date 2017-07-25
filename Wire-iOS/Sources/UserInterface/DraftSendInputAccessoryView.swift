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


import Cartography
import Classy


final class DraftSendInputAccessoryView: UIView {

    var onSend: (() -> Void)?

    public let sendButton = IconButton.iconButtonDefault()

    public var isEnabled: Bool = false {
        didSet {
            sendButton.isEnabled = isEnabled
        }
    }

    private let separator = UIView()

    init() {
        super.init(frame: .zero)
        setupViews()
        createConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupViews() {
        [sendButton, separator].forEach(addSubview)
        separator.backgroundColor = ColorScheme.default().color(withName: ColorSchemeColorSeparator)
        sendButton.cas_styleClass = "send-button"
        sendButton.adjustsImageWhenHighlighted = false
        sendButton.adjustBackgroundImageWhenHighlighted = true
        sendButton.hitAreaPadding = CGSize(width: 30, height: 30)
        sendButton.setIcon(.send, with: .tiny, for: .normal)

        sendButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
        sendButton.accessibilityIdentifier = "sendButton"

        CASStyler.default().styleItem(sendButton)
    }

    private dynamic  func sendTapped() {
        onSend?()
    }

    func createConstraints() {
        constrain(self, sendButton, separator) { view, sendButton, separator in
            separator.leading == view.leading
            separator.trailing == view.trailing
            separator.top == view.top
            separator.height == .hairline

            sendButton.trailing == view.trailing - 16
            sendButton.centerY == view.centerY
            sendButton.height == 28
            sendButton.width == sendButton.height
        }
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIViewNoIntrinsicMetric, height: 60)
    }

}
