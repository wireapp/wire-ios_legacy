//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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


extension ZClientViewController {
    
    public func updateTopOverlayView(to newView: UIView?) {
        topOverlayView?.removeFromSuperview()
        
        topOverlayView = newView
        
        guard let newView = topOverlayView else {
            return
        }
        
        newView.translatesAutoresizingMaskIntoConstraints = false
        topOverlayContainer.addSubview(newView)
        NSLayoutConstraint.activate([
            newView.topAnchor.constraint(equalTo: topOverlayContainer.topAnchor),
            newView.leadingAnchor.constraint(equalTo: topOverlayContainer.leadingAnchor),
            newView.bottomAnchor.constraint(equalTo: topOverlayContainer.bottomAnchor),
            newView.trailingAnchor.constraint(equalTo: topOverlayContainer.trailingAnchor),
            ])
    }
    
    func createTopViewConstraints() {
        topOverlayContainer = UIView()
        topOverlayContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(topOverlayContainer)
        
        NSLayoutConstraint.activate([
            topOverlayContainer.topAnchor.constraint(equalTo: view.topAnchor),
            topOverlayContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topOverlayContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topOverlayContainer.bottomAnchor.constraint(equalTo: splitViewController.view.topAnchor),
            splitViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            splitViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            splitViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            ])
        
        let heightConstraint = topOverlayContainer.heightAnchor.constraint(equalToConstant: 0)
        heightConstraint.priority = UILayoutPriorityDefaultLow
        heightConstraint.isActive = true
    }
}
