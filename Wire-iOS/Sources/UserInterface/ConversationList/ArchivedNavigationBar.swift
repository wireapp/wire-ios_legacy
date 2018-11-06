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


@objcMembers final class ArchivedNavigationBar: UIView {
    
    let separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.from(scheme: .separator, variant: .light)

        return view
    }()

    let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .from(scheme: .textForeground, variant: .dark)
        label.font = .mediumSemiboldFont

        return label
    }()
    let dismissButton = IconButton()
    private let barHeight: CGFloat = 44
    private let statusbarHeight: CGFloat = 20

    var dismissButtonHandler: (()->())? = .none
    
    var showSeparator: Bool = false {
        didSet {
            separatorView.fadeAndHide(!showSeparator)
        }
    }
    
    init(title: String) {
        super.init(frame: CGRect.zero)
        titleLabel.text = title
        createViews()
        createConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func createViews() {
        separatorView.isHidden = true
        dismissButton.setIcon(.cancel, with: .tiny, for: [])
        dismissButton.addTarget(self, action: #selector(ArchivedNavigationBar.dismissButtonTapped(_:)), for: .touchUpInside)
        dismissButton.accessibilityIdentifier = "archiveCloseButton"
        dismissButton.setIconColor(.from(scheme: .textForeground, variant: .dark), for: .normal)
        [titleLabel, dismissButton, separatorView].forEach(addSubview)
    }
    
    func createConstraints() {
        constrain(self, separatorView, titleLabel, dismissButton) { view, separator, title, button in
            separator.height == .hairline
            separator.left == view.left
            separator.right == view.right
            separator.bottom == view.bottom
            
            title.centerX == view.centerX
            title.centerY == view.centerY
            
            button.centerY == title.centerY
            button.right == view.right - 16
            button.left >= title.right + 8
            
            view.height == barHeight
        }
    }
    
    @objc func dismissButtonTapped(_ sender: IconButton) {
        dismissButtonHandler?()
    }
    
    override var intrinsicContentSize : CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: barHeight + statusbarHeight)
    }
    
}
