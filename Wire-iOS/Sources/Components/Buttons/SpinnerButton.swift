
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
        

        // the spinner covers the text with alpha BG
        // TODO: dark mode?
        progressSpinner.backgroundColor = UIColor(white: 1, alpha: 0.8)
        progressSpinner.color = .accent()
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
        let inset: CGFloat = 10
        if let titleLabel = titleLabel {
            titleLabel.lineBreakMode = .byWordWrapping
            titleLabel.numberOfLines = 0

            NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: inset),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: inset)])
        }
    }
    
    ///custom empty style with accent color for disabled state.
    override func updateEmptyStyle() {
        setBackgroundImageColor(.clear, for: .normal)
        layer.borderWidth = 1
        setTitleColor(.buttonEmptyText(variant: variant), for: .normal)
        setTitleColor(.buttonEmptyText(variant: variant), for: .highlighted)
        setTitleColor(.buttonEmptyText(variant: variant), for: .disabled)
        setBorderColor(.accent(), for: .normal)
        setBorderColor(.accentDarken, for: .highlighted)
        setBorderColor(.accent(), for: .disabled)
    }
}
