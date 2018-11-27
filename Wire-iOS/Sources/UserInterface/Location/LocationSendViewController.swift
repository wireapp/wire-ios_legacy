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

@objc public protocol LocationSendViewControllerDelegate: class {
    func locationSendViewControllerSendButtonTapped(_ viewController: LocationSendViewController)
}

@objcMembers public final class LocationSendViewController: UIViewController {
    
    public let sendButton = Button(style: .full)
    public let addressLabel: UILabel = {
        let label = UILabel()
        label.font = .normalFont
        label.textColor = .from(scheme: .textForeground)
        return label
    }()
    public let separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.from(scheme: .separator)
        return view
    }()
    fileprivate let containerView = UIView()
    
    weak var delegate: LocationSendViewControllerDelegate?
    
    var address: String? {
        didSet {
            addressLabel.text = address
        }
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
        createConstraints()

        view.backgroundColor = .from(scheme: .background)
    }
    
    fileprivate func configureViews() {
        sendButton.setTitle("location.send_button.title".localized.uppercased(), for: [])
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
            label.trailing <= button.leading - 12 ~ 1000.0
            label.top == container.top
            label.bottom == container.bottom - UIScreen.safeArea.bottom
            button.trailing == container.trailing
            button.centerY == label.centerY
            button.height == 28
            separator.leading == view.leading
            separator.trailing == view.trailing
            separator.top == container.top
            separator.height == .hairline
        }
        
        sendButton.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 1000), for: .horizontal)
        addressLabel.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 750), for: .horizontal)
    }
    
    @objc fileprivate func sendButtonTapped(_ sender: Button) {
        delegate?.locationSendViewControllerSendButtonTapped(self)
    }
}
