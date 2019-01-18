// 
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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

@import UIKit;


static inline CGFloat CGMax(CGFloat const a, CGFloat const b)
{
#if CGFLOAT_IS_DOUBLE
    return fmax(a, b);
#else
    return fmaxf(a, b);
#endif
}

static inline CGFloat CGMin(CGFloat const a, CGFloat const b)
{
#if CGFLOAT_IS_DOUBLE
    return fmin(a, b);
#else
    return fminf(a, b);
#endif
}

static inline CGFloat CGClamp(CGFloat const min, CGFloat max, CGFloat const v)
{
    return CGMin(max, CGMax(min, v));
}

static inline CGFloat CGAbs(CGFloat const a)
{
#if CGFLOAT_IS_DOUBLE
    return fabs(a);
#else
    return fabsf(a);
#endif
}

static inline CGFloat CGRound(CGFloat const a)
{
#if CGFLOAT_IS_DOUBLE
    return round(a);
#else
    return roundf(a);
#endif
}
