//
//  ImageMessageCell+Configure.swift
//  Wire-iOS
//
//  Created by Jacob Persson on 03.07.18.
//  Copyright © 2018 Zeta Project Germany GmbH. All rights reserved.
//

import Foundation

extension ImageMessageCell {
    
    @objc
    func fetchImage() {
        message.fetchImage { (image) in
            self.setImage(image)
        }
        
    }
    
}
