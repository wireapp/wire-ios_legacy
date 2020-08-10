//
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

extension Bundle {
    static var clipboardEnabled: Bool {
        return Bundle.appMainBundle.infoForKey("ClipboardEnabled") == "1"
    }
    
    static var saveMessageEnabled: Bool {
        return Bundle.appMainBundle.infoForKey("SaveMessageEnabled") == "1"
    }
    
    static var profileCemeraRollEnabled: Bool {
        return Bundle.appMainBundle.infoForKey("ProfileCemeraRollEnabled") == "1"
    }
}

public enum FeatureFlag {
  case clipboard
  case save
  case profileCamera
  
  public var isEnabled: Bool {
    switch self {
      case .clipboard:
        return Bundle.clipboardEnabled
    case .save:
        return Bundle.saveMessageEnabled
    case .profileCamera:
        return Bundle.profileCemeraRollEnabled
    }
  }
}
