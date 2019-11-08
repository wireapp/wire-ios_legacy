//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

private let MaxFileSize: UInt64 = 25 * 1024 * 1024 // 25 megabytes
private let MaxTeamFileSize: UInt64 = 100 * 1024 * 1024 // 100 megabytes

private let MaxAudioLength: TimeInterval = 25 * 60.0 // 25 minutes
private let MaxTeamAudioLength: TimeInterval = 100 * 60.0 // 100 minutes

private let MaxVideoLength: TimeInterval = 4.0 * 60.0 // 4 minutes
private let MaxTeamVideoLength: TimeInterval = 16.0 * 60.0 // 16 minutes

extension ZMUserSession {
    @objc(sharedSession)
    static func shared() -> ZMUserSession? {
        return SessionManager.shared?.activeUserSession
    }
    
    private var selfUserHasTeam: Bool {
        return ZMUser.selfUser(inUserSession: self).hasTeam
    }
    
    @objc
    func maxUploadFileSize() -> UInt64 {
        return selfUserHasTeam ? MaxTeamFileSize : MaxFileSize
    }
    
    func maxAudioLength() -> TimeInterval {
        return selfUserHasTeam ? MaxTeamAudioLength : MaxAudioLength
    }
    
    func maxVideoLength() -> TimeInterval {
        return selfUserHasTeam ? MaxTeamVideoLength : MaxVideoLength
    }
}
