
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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


/// A button with spinner at the trailing side. Title text is non trancated.
final class SpinnerButton: Button {
    private static let iconSize = StyleKitIcon.Size.tiny.rawValue
    private static let iconInset: CGFloat = 10 ///TODO: get it from design
    private static let textInset: CGFloat = 5

    private lazy var spinner: ProgressSpinner = {
        let progressSpinner = ProgressSpinner()
        
        progressSpinner.color = UIColor.from(scheme: .textDimmed, variant: .light) ///TODO: from design
        progressSpinner.iconSize = SpinnerButton.iconSize

        addSubview(progressSpinner)
        
        progressSpinner.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            progressSpinner.centerYAnchor.constraint(equalTo: centerYAnchor),
            progressSpinner.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -SpinnerButton.iconInset)])

        return progressSpinner
    }()
    
    var showSpinner: Bool = false {
        didSet {
            spinner.isHidden = !showSpinner
            isEnabled = !showSpinner
            
            showSpinner ? spinner.startAnimation() : spinner.stopAnimation()
        }
    }
    
    override init() {
        super.init()
        titleLabel?.lineBreakMode = .byWordWrapping
        titleLabel?.textAlignment = .center
        titleLabel?.numberOfLines = 0
        
//        titleLabel?.setContentHuggingPriority(.required, for: .vertical)
//        titleLabel?.setContentHuggingPriority(.required, for: .horizontal)

//        setContentHuggingPriority(.required, for: .vertical)
//        setContentHuggingPriority(.required, for: .horizontal)

        let iconInset = SpinnerButton.iconSize + SpinnerButton.iconInset
        contentEdgeInsets = UIEdgeInsets(top: contentEdgeInsets.top, left: contentEdgeInsets.left+iconInset, bottom: contentEdgeInsets.bottom, right: contentEdgeInsets.right+iconInset)
        titleEdgeInsets = UIEdgeInsets(top: titleEdgeInsets.top, left: titleEdgeInsets.left+iconInset, bottom: titleEdgeInsets.bottom, right: titleEdgeInsets.right+iconInset)
        
        if let titleLabel = titleLabel {

//            addConstraints([
//                .init(item: titleLabel,
//                      attribute: .top,
//                      relatedBy: .greaterThanOrEqual,
//                      toItem: self,
//                      attribute: .top,
//                      multiplier: 1.0,
//                      constant: contentEdgeInsets.top),
//                .init(item: titleLabel,
//                      attribute: .bottom,
//                      relatedBy: .greaterThanOrEqual,
//                      toItem: self,
//                      attribute: .bottom,
//                      multiplier: 1.0,
//                      constant: contentEdgeInsets.bottom),
//                .init(item: titleLabel,
//                      attribute: .left,
//                      relatedBy: .greaterThanOrEqual,
//                      toItem: self,
//                      attribute: .left,
//                      multiplier: 1.0,
//                      constant: contentEdgeInsets.left + 30),
//                .init(item: titleLabel,
//                      attribute: .right,
//                      relatedBy: .greaterThanOrEqual,
//                      toItem: self,
//                      attribute: .right,
//                      multiplier: 1.0,
//                      constant: contentEdgeInsets.right)
//                ])
//        addConstraints([
//            titleLabel.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: SpinnerButton.textInset),
//            titleLabel.bottomAnchor.constraint(greaterThanOrEqualTo: bottomAnchor, constant: SpinnerButton.textInset),
//            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: iconInset),
//            titleLabel.trailingAnchor.constraint(greaterThanOrEqualTo: trailingAnchor, constant: iconInset),
//            ])
        }

//        let insets = titleEdgeInsets
//
//
    }
    
//    override func setTitle(_ title: String?, for state: UIControl.State) {
//        super.setTitle(title, for: state)
//        setNeedsLayout()
//    }
}
