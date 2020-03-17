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

import XCTest
@testable import Wire

extension MockUser: ProfileImageFetchable {
    public func fetchProfileImage(session: ZMUserSessionInterface,
                                  cache: ImageCache<UIImage> = UIImage.defaultUserImageCache,
                                  sizeLimit: Int? = nil,
                                  desaturate: Bool = false,
                                  completion: @escaping (_ image: UIImage?, _ cacheHit: Bool) -> Void ) -> Void {

        completion(profileImage, false)
    }
}
