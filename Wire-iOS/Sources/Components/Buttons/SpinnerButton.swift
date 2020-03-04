
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

final class SpinnerButton: Button {
    private lazy var spinner: ProgressSpinner = {
        let progressSpinner = ProgressSpinner()
        
        progressSpinner.color = UIColor.from(scheme: .textDimmed, variant: .light)
        progressSpinner.iconSize = StyleKitIcon.Size.tiny.rawValue
        

        addSubview(progressSpinner)
        
        progressSpinner.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            //            progressSpinner.widthAnchor.constraint(equalToConstant: StyleKitIcon.Size.tiny.rawValue), ///TODO: needed?
//            progressSpinner.heightAnchor.constraint(equalTo: progressSpinner.widthAnchor),
            
            progressSpinner.centerYAnchor.constraint(equalTo: centerYAnchor),
            progressSpinner.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10), ///TODO: get it from design
            ])

        layoutIfNeeded()
        return progressSpinner
    }()
    
    var showSpinner: Bool = false {
        didSet {
            spinner.isHidden = !showSpinner
            isEnabled = !showSpinner
            
            showSpinner ? spinner.startAnimation() : spinner.stopAnimation()
        }
    }
}
