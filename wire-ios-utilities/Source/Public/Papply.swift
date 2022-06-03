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

public func papply<A, B>(
    _ a2b: @escaping (A) -> B, _ a: A
    ) -> () -> B {
    return {
        a2b(a)
    }
}

public func papply<A, B, C>(
    _ ab2c: @escaping (A, B) -> C, _ a: A
    ) -> (B) -> C {
    return { b in
        ab2c(a, b)
    }
}

public func papply<A, B, C, D>(
    _ abc2d: @escaping (A, B, C) -> D, _ a: A
    ) -> (B, C) -> D {
    return { b, c in
        abc2d(a, b, c)
    }
}

public func papply<A, B, C, D, E>(
    _ abcd2e: @escaping (A, B, C, D) -> E, _ a: A
    ) -> (B, C, D) -> E {
    return { b, c, d in
        abcd2e(a, b, c, d)
    }
}

public func papply<A, B, C, D, E, F>(
    _ abcde2f: @escaping (A, B, C, D, E) -> F, _ a: A
    ) -> (B, C, D, E) -> F {
    return { b, c, d, e in
        abcde2f(a, b, c, d, e)
    }
}
