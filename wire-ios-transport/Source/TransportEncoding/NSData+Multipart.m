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


@import WireUtilities;

#import "NSData+Multipart.h"


static NSRange ZMSubstractRange(NSRange fromRange, NSRange substractRange) {
    return NSMakeRange(NSMaxRange(substractRange), NSMaxRange(fromRange) - NSMaxRange(substractRange));
}

static NSRange ZMRangeInterval(NSRange fromRange, NSRange toRange) {
    if (NSIntersectionRange(fromRange, toRange).length > 0) {
        return NSMakeRange(0, 0);
    }
    if (NSMaxRange(fromRange) < NSMaxRange(toRange)) {
        return NSMakeRange(NSMaxRange(fromRange), toRange.location - NSMaxRange(fromRange));
    }
    else {
        return NSMakeRange(NSMaxRange(toRange), fromRange.location - NSMaxRange(toRange));
    }
}

@interface NSMutableData (Multipart)

- (void)appendNewLine;
- (void)appendString:(NSString *)string;
- (void)appendStringLine:(NSString *)string;
- (void)appendMultipartBodyItem:(ZMMultipartBodyItem *)item boundary:(NSString *)boundary;

@end

@implementation NSMutableData (Multipart)

- (void)appendNewLine
{
    [self appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
}

- (void)appendString:(NSString *)string
{
    [self appendData:[string dataUsingEncoding:NSUTF8StringEncoding]];
}

- (void)appendStringLine:(NSString *)string
{
    [self appendData:[string dataUsingEncoding:NSUTF8StringEncoding]];
    [self appendNewLine];
}

- (void)appendMultipartBodyItem:(ZMMultipartBodyItem *)item boundary:(NSString *)boundary
{
    [self appendStringLine:[NSString stringWithFormat:@"--%@", boundary]];
    [self appendStringLine:[NSString stringWithFormat:@"Content-Type: %@", item.contentType]];
    [self appendStringLine:[NSString stringWithFormat:@"Content-Length: %lu", (unsigned long)item.data.length]];
    for (NSString *key in item.headers) {
        [self appendStringLine:[NSString stringWithFormat:@"%@: %@", key, item.headers[key]]];
    }
    [self appendNewLine];
    [self appendData:item.data];
    [self appendNewLine];
}


@end

@implementation NSData (Multipart)

- (void)enumerateBytesByBoundary:(NSData *)boundary withBlock:(void(^)(NSData *dataPart, NSRange range, BOOL *stop))iteration
{
    NSRange boundaryRange = NSMakeRange(0, 0);
    NSRange fullRange = NSMakeRange(0, self.length);
    BOOL stop = false;
    do {
        NSRange subRange = [self subRangeFromFullRange:fullRange
                                              boundary:boundary
                                         boundaryRange:boundaryRange];
        if (subRange.length > 0) {
            iteration([self subdataWithRange:subRange], subRange, &stop);
        }
        boundaryRange = NSMakeRange(NSMaxRange(subRange), boundary.length);
    } while (!stop && boundaryRange.location != NSNotFound && NSMaxRange(boundaryRange) < self.length);
}

- (NSRange)subRangeFromFullRange:(NSRange)fullRange boundary:(NSData *)boundary boundaryRange:(NSRange)boundaryRange
{
    NSRange searchRange = ZMSubstractRange(fullRange, boundaryRange);
    NSRange nextBoundaryRange = [self rangeOfData:boundary options:0 range:searchRange];
    NSRange subRange = NSMakeRange(0, 0);
    if (nextBoundaryRange.location != NSNotFound) {
        subRange = ZMRangeInterval(boundaryRange, nextBoundaryRange);
    }
    else if (NSMaxRange(boundaryRange) < NSMaxRange(fullRange)) {
        subRange = ZMSubstractRange(fullRange, boundaryRange);
    }
    return subRange;
}

- (NSArray *)componentsSeparatedByData:(NSData *)boundary
{
    if (boundary == nil) {
        return nil;
    }

    NSMutableArray *components = [NSMutableArray new];
    [self enumerateBytesByBoundary:boundary withBlock:^(NSData *dataPart, NSRange __unused range, BOOL * __unused stop) {
        [components addObject:dataPart];
    }];
    return components;
}

- (NSArray *)lines
{
    return [self componentsSeparatedByData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
}

+ (NSData *)multipartDataWithItems:(NSArray *)items boundary:(NSString *)boundary
{
    NSMutableData *multipartData = [NSMutableData new];
    
    for (ZMMultipartBodyItem *item in items) {
        [multipartData appendMultipartBodyItem:item boundary:boundary];
    }
    [multipartData appendStringLine:[NSString stringWithFormat:@"--%@--", boundary]];
    
    return [multipartData copy];
}

- (NSArray *)multipartDataItemsSeparatedWithBoundary:(NSString *)boundary;
{
    NSData *boundaryData = [[NSString stringWithFormat:@"--%@", boundary] dataUsingEncoding:NSUTF8StringEncoding];
    return [[self componentsSeparatedByData:boundaryData] mapWithBlock:^id(NSData *obj) {
        if (![obj isEqual:[@"--\r\n" dataUsingEncoding:NSUTF8StringEncoding]]) {
            //last component is trailing "--\r\n"
            return [[ZMMultipartBodyItem alloc] initWithMultipartData:obj];
        }
        return nil;
    }];
}

@end

@implementation ZMMultipartBodyItem

- (instancetype)initWithData:(NSData *)data contentType:(NSString *)contentType headers:(NSDictionary *)headers;
{
    self = [super init];
    if (self) {
        _data = [data copy];
        _contentType = [contentType copy];
        _headers = [headers copy];
    }
    return self;
}

- (instancetype)initWithMultipartData:(NSData *)data 
{
    self = [super init];
    if (self) {
        NSArray *dataLines = [self multipartDataLines:data];
        
        NSMutableDictionary *headers = [NSMutableDictionary new];
        NSInteger contentLength = 0;
        NSString *contentType;
        
        for (NSData *lineData in dataLines) {
            NSString *line = [[NSString alloc] initWithData:lineData encoding:NSUTF8StringEncoding];
            if ([self contentTypeFromLine:line contentType:&contentType] ||
                [self contentLengthFromLine:line contentLength:&contentLength] ||
                [self headersFromLine:line headers:&headers]) {
                continue;
            }
        }
        _contentType = contentType;
        _headers = [headers copy];
        _data = [self contentDataFromData:data contentLength:contentLength];
    }
    return self;
}

static NSString *const ContentTypePrefix = @"Content-Type: ";

- (BOOL)contentTypeFromLine:(NSString *)line contentType:(NSString **)contentType
{
    if ([line hasPrefix:ContentTypePrefix]) {
        *contentType = [line stringByReplacingCharactersInRange:NSMakeRange(0, ContentTypePrefix.length) withString:@""];
        return YES;
    }
    return NO;
}

static NSString *const ContentLengthPrefix = @"Content-Length: ";

- (BOOL)contentLengthFromLine:(NSString *)line contentLength:(NSInteger *)contentLength
{
    if ([line hasPrefix:ContentLengthPrefix]) {
        NSScanner *scanner = [NSScanner scannerWithString:[line substringFromIndex:ContentLengthPrefix.length]];
        [scanner scanInteger:contentLength];
        return YES;
    }
    return NO;
}

- (BOOL)headersFromLine:(NSString *)line headers:(NSMutableDictionary **)headers
{
    if (line != nil) {
        NSRange colonRange = [line rangeOfString:@": "];
        if (colonRange.location != NSNotFound) {
            NSString *key = [line substringToIndex:colonRange.location];
            NSString *value = [line substringFromIndex:NSMaxRange(colonRange)];
            if (key != nil && value != nil) {
                [*headers setValue:value forKey:key];
            }
            return YES;
        }
    }
    return NO;
}

- (NSData *)contentDataFromData:(NSData *)data contentLength:(NSInteger)contentLength
{
    NSData *carriageReturn = [@"\r\n" dataUsingEncoding:NSUTF8StringEncoding];
    NSData *contentData = [data subdataWithRange:NSMakeRange(data.length - carriageReturn.length - (NSUInteger)contentLength, (NSUInteger)contentLength)];
    return contentData;
}

- (NSArray *)multipartDataLines:(NSData *)data
{
    NSMutableArray *dataLines = [[data lines] mutableCopy];
    [dataLines removeLastObject]; //last line is redundant
    return dataLines;
}

- (BOOL)isEqual:(id)object
{
    if (self == object) {
        return YES;
    }
    if (![object isKindOfClass:[self class]]) {
        return NO;
    }
    return [self isEqualToItem:object];
}

- (BOOL)isEqualToItem:(ZMMultipartBodyItem *)object
{
    BOOL equalData = [self.data isEqualToData:object.data];
    BOOL equalContentType = [self.contentType isEqualToString:object.contentType];
    BOOL equalHeaders = [self.headers isEqualToDictionary:object.headers];
    return equalData && equalContentType && equalHeaders;
}

- (NSUInteger)hash
{
    return self.data.hash ^ self.contentType.hash ^ self.headers.hash;
}

- (NSString *)description
{
    NSMutableString *description = [NSMutableString new];
    [description appendString:ContentTypePrefix];
    [description appendString:self.contentType];
    [description appendString:@"\n"];
    [description appendString:ContentLengthPrefix];
    [description appendString:[NSString stringWithFormat:@"%lu", (unsigned long)self.data.length]];
    [description appendString:@"\n"];
    
    //try json
    NSError *jsonError;
    id jsonData = [NSJSONSerialization JSONObjectWithData:self.data options:NSJSONReadingAllowFragments error:&jsonError];
    if (jsonError == nil && jsonData != nil) {
        [description appendString:@"Payload: "];
        [description appendString:[jsonData description]];
        [description appendString:@"\n"];
    }
    return [description copy];
}

@end
