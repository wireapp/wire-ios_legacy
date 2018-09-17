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

@objcMembers final public class ModalTopBar: UIView {
    
    public let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .textForeground
        label.font = .mediumSemiboldFont

        return label
    }()

    public let dismissButton = IconButton()
    public let separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(scheme: .separator)
        return view
    }()

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
        backgroundColor = .background

        createConstraints()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func configureViews() {
        [titleLabel, dismissButton, separatorView].forEach(addSubview)
        dismissButton.setIcon(.cancel, with: .tiny, for: [])
        dismissButton.setIconColor(.iconNormal, for: .normal)
        dismissButton.addTarget(self, action: #selector(dismissButtonTapped), for: .touchUpInside)
        dismissButton.hitAreaPadding = CGSize(width: 20, height: 20)
    }

    fileprivate func createConstraints() {
        let insets = UIScreen.safeArea
        constrain(self, titleLabel, dismissButton, separatorView) { view, label, button, separator in
            label.centerX == view.centerX
            label.top == view.top + (showsStatusBar ? insets.top : 0) + (showsStatusBar && insets.top == 0 ? 20 : 0)
            label.bottom == view.bottom
            label.trailing <= button.leading - 12
            button.trailing == view.trailing - 16
            button.centerY == label.centerY
            separator.leading == view.leading
            separator.trailing == view.trailing
            separator.bottom == view.bottom
            separator.height == .hairline
        }
        
        dismissButton.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 1000), for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 750), for: .horizontal)
    }
    
    @objc fileprivate func dismissButtonTapped(_ sender: IconButton) {
        delegate?.modelTopBarWantsToBeDismissed(self)
    }
    
    public override var intrinsicContentSize : CGSize {
        let insets = UIScreen.safeArea
        if insets.top > 20 {
            return CGSize(width: UIView.noIntrinsicMetric, height: 44 + insets.top)
        }
        return CGSize(width: UIView.noIntrinsicMetric, height: showsStatusBar ? 64 : 44)
    }
    
}
