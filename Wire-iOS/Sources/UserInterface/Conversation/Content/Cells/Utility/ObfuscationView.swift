//
//  ObfuscationView.swift
//  Wire-iOS
//
//  Created by Mihail Gerasimenko on 11/7/16.
//  Copyright © 2016 Zeta Project Germany GmbH. All rights reserved.
//

import Foundation

final class ObfuscationView: UIImageView {
    init(icon: ZetaIconType) {
        super.init(frame: .zero)
        self.backgroundColor = UIColor.wr_color(fromColorScheme: ColorSchemeColorAccentDimmedFlat)
        self.isOpaque = true
        self.contentMode = .center
        self.image = UIImage.init(for: icon, iconSize: .tiny, color: ColorScheme.default().color(withName: ColorSchemeColorBackground))
    }
    
    required init(coder: NSCoder) {
        fatal("initWithCoder: not implemented")
    }
}
