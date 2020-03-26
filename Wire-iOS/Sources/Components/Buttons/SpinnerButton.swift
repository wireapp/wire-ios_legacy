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

/// A button with spinner at the trailing side. Title text is non truncated.
final class SpinnerButton: Button {

    private lazy var spinner: ProgressSpinner = {
        let progressSpinner = ProgressSpinner()

        // the spinner covers the text with alpha BG
        progressSpinner.backgroundColor = variant == .light
            ? UIColor.from(scheme: .contentBackground).withAlphaComponent(CGFloat.SpinnerButton.spinnerBackgroundAlpha)
            : UIColor(white: 0, alpha: CGFloat.SpinnerButton.spinnerBackgroundAlpha)
        progressSpinner.color = .accent()
        progressSpinner.iconSize = CGFloat.SpinnerButton.iconSize

        addSubview(progressSpinner)

        progressSpinner.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            progressSpinner.centerYAnchor.constraint(equalTo: centerYAnchor),
            progressSpinner.trailingAnchor.constraint(equalTo: trailingAnchor),
            progressSpinner.widthAnchor.constraint(equalToConstant: 48),
            progressSpinner.topAnchor.constraint(equalTo: topAnchor),
            progressSpinner.bottomAnchor.constraint(equalTo: bottomAnchor)])

        return progressSpinner
    }()

    var isLoading: Bool = false {
        didSet {
            spinner.isHidden = !isLoading

            isLoading ? spinner.startAnimation() : spinner.stopAnimation()
        }
    }

    override init() {
        super.init()

        configureTitleLabel()
    }

    /// multi line support of titleLabel
    private func configureTitleLabel() {
        guard let titleLabel = titleLabel else { return }

        // title is always align to left
        contentHorizontalAlignment = .left

        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.numberOfLines = 0

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: CGFloat.SpinnerButton.contentInset),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: CGFloat.SpinnerButton.contentInset)])
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

    // MARK: - factory method
    static func alarmButton() -> SpinnerButton {
        return SpinnerButton(style: .empty, cornerRadius: 6, titleLabelFont: .smallSemiboldFont)
    }
    
}
