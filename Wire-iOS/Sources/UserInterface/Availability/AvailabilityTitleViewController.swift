//
// Wire
// Copyright (C) 2010 Wire Swiss GmbH
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

class AvailabilityTitleViewController: UIViewController {
    
    let options: AvailabilityTitleView.Options
    let user: GenericUser
    
    var availabilityTitleView: AvailabilityTitleView? {
        return view as? AvailabilityTitleView
    }
    
    init(user: GenericUser, options: AvailabilityTitleView.Options) {
        self.user = user
        self.options = options
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = AvailabilityTitleView(user: user, options: options)
    }
    
}
