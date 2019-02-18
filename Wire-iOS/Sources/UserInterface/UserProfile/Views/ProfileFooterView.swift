//
//  ProfileFooterView.swift
//  Wire-iOS
//
//  Created by Nicola Giancecchi on 18.02.19.
//  Copyright © 2019 Zeta Project Germany GmbH. All rights reserved.
//

import UIKit

class ProfileFooterView: ConversationDetailFooterView {

    override func setupButtons() {
        leftButton.accessibilityIdentifier = "left_button"
        rightButton.accessibilityIdentifier = "right_button"
        
        leftButton.setIcon(.plus, with: .tiny, for: .normal)
        leftButton.setTitle("participants.footer.add_title".localized.uppercased(), for: .normal)
        rightButton.setIcon(.ellipsis, with: .tiny, for: .normal)
    }
    
    
}
