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


#import "NSString+ZMPersonName.h"





static NSString * const ArabicGodNames[] = {
    @"الله",
     @"الرحمن",
    @"الرحيم",
    @"الملك",
    @"القدوس",
    @"السلام",
    @"المؤمن",
    @"المهيمن",
    @"العزيز",
    @"الجبار",
    @"المتكبر",
    @"الخالق",
    @"البارئ",
    @"المصور",
    @"الغفار",
    @"القهار",
    @"الوهاب",
    @"الرزاق",
    @"الفتاح",
    @"العليم",
    @"القابض",
    @"الباسط",
    @"الخَافِض",
    @"الرافع",
    @"المعز",
    @"المذل",
    @"السميع",
    @"البصير",
    @"الحكم",
    @"العدل",
    @"اللطيف",
    @"الخبير",
    @"الحليم",
    @"العظيم",
    @"الغفور",
    @"الشكور",
    @"العلي",
    @"الكبير",
    @"الحفيظ",
    @"المقيت",
    @"الحسيب",
    @"الجليل",
    @"الكريم",
    @"الرقيب",
    @"المجيب",
    @"الواسع",
    @"الحكيم",
    @"الودود",
    @"المجيد",
    @"الباعث",
    @"الشهيد",
    @"الحق",
    @"الوكيل",
    @"القوي",
    @"المتين",
    @"الولي",
    @"الحميد",
    @"المحصي",
    @"المبدئ",
    @"المعيد",
    @"المحيي",
    @"المميت",
    @"الحي",
    @"القيوم",
    @"الواجد",
    @"الماجد",
    @"الواحد",
    @"الاحد",
    @"الصمد",
    @"القادر",
    @"المقتدر",
    @"المقدم",
    @"المؤخر",
    @"الأول",
    @"الأخر",
    @"الظاهر",
    @"الباطن",
    @"الوالي",
    @"المتعالي",
    @"البر",
    @"التواب",
    @"المنتقم",
    @"العفو",
    @"الرؤوف",
    @"مالك الملك",
    @"ذو الجلال والإكرام",
    @"المقسط",
    @"الجامع",
    @"الغني",
    @"المغني",
    @"المانع",
    @"الضار",
    @"النافع",
    @"النور",
    @"الهادي",
    @"البديع",
    @"الباقي",
    @"الوارث",
    @"الرشيد",
    @"الصبور",
};


@implementation NSString (ZMPersonName)

- (NSString *)zmLeadingNumberOrFirstComposedCharacter;
{
    return [self zmNumberPrefix] ?: [self zmFirstComposedCharacter];
}

- (NSString *)zmFirstComposedCharacter
{
    if (self.length == 0) {
        return nil;
    }
    NSRange composedCharacterRange =  [self rangeOfComposedCharacterSequenceAtIndex:0];
    NSString *firstComposedCharacter = [self substringWithRange:composedCharacterRange];
    return firstComposedCharacter;
}

- (NSString *)zmNumberPrefix
{
    NSScanner *scanner = [NSScanner scannerWithString:self];
    scanner.charactersToBeSkipped = nil;
    if ([scanner scanInteger:NULL]) {
        return [self substringToIndex:scanner.scanLocation];
    }
    return nil;
}

- (NSString *)zmSecondComposedCharacter
{
    if (self.length == 0) {
        return nil;
    }
    NSRange firstCharacterRange = [self rangeOfComposedCharacterSequenceAtIndex:0];
    if (firstCharacterRange.length < 1) {
        return nil;
    }
    NSUInteger secondCharacterIndex = NSMaxRange(firstCharacterRange);
    if (self.length <= secondCharacterIndex) {
        return nil;
    }
    NSRange range = [self rangeOfComposedCharacterSequenceAtIndex:secondCharacterIndex];

    NSString *firstTwoCharacters = [self substringWithRange:range];
    return firstTwoCharacters;
}

- (BOOL)zmIsGodName;
{
    // this is used for the composition of arabic first names, as they are often a combination of a "servant of" and one of the god names
    for (size_t i = 0; i < (sizeof(ArabicGodNames)/sizeof(*ArabicGodNames)); ++i) {
        NSString * name = ArabicGodNames[i];
        if ([self isEqualToString:name]) {
            return YES;
        }
    }
    return NO;
}

@end
