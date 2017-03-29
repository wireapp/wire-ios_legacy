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


import Cartography
import Classy

@objc public protocol LocationSendViewControllerDelegate: class {
    func locationSendViewControllerSendButtonTapped(_ viewController: LocationSendViewController)
}

@objc public final class LocationSendViewController: UIViewController {
    
    public var buttonFont: UIFont? = nil
    public let sendButton = Button(style: .full)
    public let addressLabel = UILabel()
    public let separatorView = UIView()
    fileprivate let containerView = UIView()
    
    weak var delegate: LocationSendViewControllerDelegate?
    
    var address: String? {
        didSet {
            addressLabel.text = address
        }
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        CASStyler.default().styleItem(self)
        configureViews()
        createConstraints()
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let font = buttonFont else { return }
        sendButton.titleLabel?.font = font
    }
    
    fileprivate func configureViews() {
        sendButton.setTitle("location.send_button.title".localized.uppercased(), for: UIControlState())
        sendButton.addTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)
        sendButton.accessibilityIdentifier = "sendLocation"
        addressLabel.accessibilityIdentifier = "selectedAddress"
        view.addSubview(containerView)
        [addressLabel, sendButton, separatorView].forEach(containerView.addSubview)
    }

    fileprivate func createConstraints() {
        constrain(view, containerView, separatorView, addressLabel, sendButton) { view, container, separator, label, button in
            container.edges == inset(view.edges, 24, 0)
            label.leading == container.leading
            label.trailing <= button.leading - 12 ~ LayoutPriority(1000)
            label.top == container.top
            label.bottom == container.bottom
            button.trailing == container.trailing
            button.centerY == container.centerY
            button.height == 28
            separator.leading == view.leading
            separator.trailing == view.trailing
            separator.top == container.top
            separator.height == .hairline
        }
        
        sendButton.setContentCompressionResistancePriority(1000, for: .horizontal)
        addressLabel.setContentCompressionResistancePriority(750, for: .horizontal)
    }
    
    @objc fileprivate func sendButtonTapped(_ sender: Button) {
        delegate?.locationSendViewControllerSendButtonTapped(self)
    }
}
