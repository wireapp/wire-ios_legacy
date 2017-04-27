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

@objc public protocol ModalTopBarDelegate: class {
    func modelTopBarWantsToBeDismissed(_ topBar: ModalTopBar)
}

@objc final public class ModalTopBar: UIView {
    
    public let titleLabel = UILabel()
    public let dismissButton = IconButton()
    public let separatorView = UIView()
    fileprivate let showsStatusBar: Bool
    weak var delegate: ModalTopBarDelegate?
    
    var title: String? {
        didSet {
            titleLabel.text = title?.uppercased()
        }
    }
    
    required public init(forUseWithStatusBar statusBar: Bool = true) {
        showsStatusBar = statusBar
        super.init(frame: CGRect.zero)
        configureViews()
        createConstraints()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func configureViews() {
        [titleLabel, dismissButton, separatorView].forEach(addSubview)
        dismissButton.setIcon(.cancel, with: .tiny, for: UIControlState())
        dismissButton.addTarget(self, action: #selector(dismissButtonTapped), for: .touchUpInside)
        dismissButton.hitAreaPadding = CGSize(width: 20, height: 20)
    }

    fileprivate func createConstraints() {
        constrain(self, titleLabel, dismissButton, separatorView) { view, label, button, separator in
            label.centerX == view.centerX
            label.top == view.top + (showsStatusBar ? 20 : 0)
            label.bottom == view.bottom
            label.trailing <= button.leading - 12
            button.trailing == view.trailing - 16
            button.centerY == label.centerY
            separator.leading == view.leading
            separator.trailing == view.trailing
            separator.bottom == view.bottom
            separator.height == .hairline
        }
        
        dismissButton.setContentCompressionResistancePriority(1000, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(750, for: .horizontal)
    }
    
    @objc fileprivate func dismissButtonTapped(_ sender: IconButton) {
        delegate?.modelTopBarWantsToBeDismissed(self)
    }
    
    public override var intrinsicContentSize : CGSize {
        return CGSize(width: UIViewNoIntrinsicMetric, height: showsStatusBar ? 64 : 44)
    }
    
}
