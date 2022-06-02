//
//  String+NilEmpty.swift
//  WireDataModel
//
//  Created by Jacob Persson on 22.10.21.
//  Copyright © 2021 Wire Swiss GmbH. All rights reserved.
//

import Foundation

extension String {

    var selfOrNilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
