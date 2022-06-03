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

public func flip<A, B>(
    _ f: @escaping (A) -> B
    ) -> (A) -> B {
    return f
}

public func flip<A, B, C>(
    _ f: @escaping ((A, B)) -> C
    ) -> (B, A) -> C {
    return { b, a in
        f((a, b))
    }
}

public func flip<A, B, C, D>(
    _ f: @escaping ((A, B, C)) -> D
    ) -> (C, B, A) -> D {
    return { c, b, a in
        f((a, b, c))
    }
}

public func flip<A, B, C, D, E>(
    _ f: @escaping ((A, B, C, D)) -> E
    ) -> (D, C, B, A) -> E {
    return { d, c, b, a in
        f((a, b, c, d))
    }
}
