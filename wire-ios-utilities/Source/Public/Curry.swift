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

public func curry<A, B>(
    _ f: @escaping (A) -> B
    ) -> (A) -> B {
    return { a in f(a) }
}

public func curry<A, B, C>(
    _ f: @escaping ((A, B)) -> C
    ) -> (A) -> (B) -> C {
    return { a in { b in f((a, b)) } }
}

public func curry<A, B, C, D>(
    _ f: @escaping ((A, B, C)) -> D
    ) -> (A) -> (B) -> (C) -> D {
    return { a in { b in { c in f((a, b, c)) } } }
}

public func curry<A, B, C, D, E>(
    _ f: @escaping ((A, B, C, D)) -> E
    ) -> (A) -> (B) -> (C) -> (D) -> E {
    return { a in { b in { c in { d in f((a, b, c, d)) } } } }
}

public func curry<A, B, C, D, E, F>(
    _ f: @escaping ((A, B, C, D, E)) -> F
    ) -> (A) -> (B) -> (C) -> (D) -> (E) -> F {
    return { a in { b in { c in { d in { e in f((a, b, c, d, e)) } } } } }
}

public func curry<A, B, C, D, E, F, G>(
    _ g: @escaping ((A, B, C, D, E, F)) -> G
    ) -> (A) -> (B) -> (C) -> (D) -> (E) -> (F) -> G {
    return { a in { b in { c in { d in { e in { f in g((a, b, c, d, e, f)) } } } } } }
}
