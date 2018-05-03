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

class GridView: UIStackView {
    
    let upperHorizontalStackerView: UIStackView! = UIStackView(arrangedSubviews: [])
    let lowerHorizontalStackerView: UIStackView! = UIStackView(arrangedSubviews: [])
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        lowerHorizontalStackerView.axis = .horizontal
        upperHorizontalStackerView.axis = .horizontal
        
        lowerHorizontalStackerView.distribution = .fillEqually
        upperHorizontalStackerView.distribution = .fillEqually
        
        self.distribution = .fillEqually
        self.axis = .vertical
        self.addArrangedSubview(upperHorizontalStackerView)
        self.addArrangedSubview(lowerHorizontalStackerView)
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func append(view: UIView) {
        if upperHorizontalStackerView.arrangedSubviews.count <= lowerHorizontalStackerView.arrangedSubviews.count {
            upperHorizontalStackerView.addArrangedSubview(view)
        } else {
            lowerHorizontalStackerView.addArrangedSubview(view)
        }
        
        updateVisibleStacksViews()
    }
    
    func remove(view: UIView) {
        if let view = upperHorizontalStackerView.arrangedSubviews.first(where: { $0 == view }) {
            upperHorizontalStackerView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        
        if let view = lowerHorizontalStackerView.arrangedSubviews.first(where: { $0 == view }) {
            lowerHorizontalStackerView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        
        updateVisibleStacksViews()
    }
    
    func updateVisibleStacksViews() {
        upperHorizontalStackerView.isHidden = upperHorizontalStackerView.arrangedSubviews.isEmpty
        lowerHorizontalStackerView.isHidden = lowerHorizontalStackerView.arrangedSubviews.isEmpty
    }
    
}
