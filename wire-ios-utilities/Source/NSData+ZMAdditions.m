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


@import WireSystem;

#import "NSData+ZMAdditions.h"
#import <zlib.h>
#import <CommonCrypto/CommonCrypto.h>


@implementation NSData (ZMSorting)

// We need this for the Core Data to be able to compare NSData / sort NSData
- (NSComparisonResult)compare:(NSData *)otherData
{
    NSInteger r = memcmp(self.bytes, otherData.bytes, MIN(self.length, otherData.length));
    if (r == 0) {
        r = ((NSInteger) self.length) - ((NSInteger) otherData.length);
    }
    if (r < 0) {
        return NSOrderedAscending;
    } else if (r == 0) {
        return NSOrderedSame;
    }
    
    return NSOrderedDescending;
}

@end



@implementation NSData (ZMHTTPCompression)

- (NSData *)zm_gzipCompressedHTTPBody;
{
    if (self.length <= 1) {
        return self;
    }
    
    __block z_stream stream = {};
    Require(deflateInit2(&stream, 8, Z_DEFLATED, 15 + 16, 8, Z_DEFAULT_STRATEGY) == Z_OK);
    
    NSMutableData *result = [NSMutableData dataWithLength:self.length + 100];
    __block size_t resultLength = 0;
    
    [self enumerateByteRangesUsingBlock:^(const void *bytes, NSRange byteRange, BOOL *stop) {
        NOT_USED(stop);
        
        stream.next_in = (Bytef *) bytes;
        stream.avail_in = (uInt) byteRange.length;
        
        stream.next_out = (Bytef *) (result.mutableBytes + resultLength);
        uInt available = (uInt) (result.length - resultLength);
        stream.avail_out = available;
        
        int r = deflate(&stream, Z_NO_FLUSH);
        Require(r != Z_STREAM_ERROR);
        resultLength += available - stream.avail_out;
        
        while (stream.avail_out == 0) {
            // Not enought space in output. Increase:
            result.length = result.length + 1024;
            stream.next_out = (Bytef *) (result.mutableBytes + resultLength);
            available = (uInt) (result.length - resultLength);
            stream.avail_out = available;
            r = deflate(&stream, Z_NO_FLUSH);
            Require(r != Z_STREAM_ERROR);
            resultLength += available - stream.avail_out;
        }
    }];
    
    stream.next_in = NULL;
    stream.avail_in = 0;
    
    stream.next_out = (Bytef *) (result.mutableBytes + resultLength);
    uInt available = (uInt) (result.length - resultLength);
    stream.avail_out = available;
    int rFinish = deflate(&stream, Z_FINISH);
    Require(rFinish != Z_STREAM_ERROR);
    resultLength += available - stream.avail_out;
    
    while (stream.avail_out == 0) {
        // Not enought space in output. Increase:
        result.length = result.length + 1024;
        stream.next_out = (Bytef *) (result.mutableBytes + resultLength);
        available = (uInt) (result.length - resultLength);
        stream.avail_out = available;
        rFinish = deflate(&stream, Z_NO_FLUSH);
        Require(rFinish != Z_STREAM_ERROR);
        resultLength += available - stream.avail_out;
    }
    
    Require(rFinish == Z_STREAM_END);
    
    result.length = resultLength;
    
    return result;
}

@end



@implementation NSData (DispatchDataTesting)

- (dispatch_data_t)dispatchData;
{
    CFDataRef cfdata = CFBridgingRetain(self);
    return dispatch_data_create(self.bytes, self.length, dispatch_get_global_queue(0, 0), ^{
        CFRelease(cfdata);
    });
}

@end



@implementation NSData (Test_ZMHTTPDecompression)

- (NSData *)zm_gzipDecompressedHTTPBody;
{
    if (self.length <= 1) {
        return self;
    }
    
    __block z_stream stream = {};
    Require(inflateInit2(&stream, 15 + 16) == Z_OK);
    
    NSMutableData *result = [NSMutableData dataWithLength:self.length * 2];
    __block size_t resultLength = 0;
    
    [self enumerateByteRangesUsingBlock:^(const void *bytes, NSRange byteRange, BOOL *stop) {
        NOT_USED(stop);
        
        stream.next_in = (Bytef *) bytes;
        stream.avail_in = (uInt) byteRange.length;
        
        stream.next_out = (Bytef *) (result.mutableBytes + resultLength);
        uInt available = (uInt) (result.length - resultLength);
        stream.avail_out = available;
        
        int r = inflate(&stream, Z_NO_FLUSH);
        Require(r != Z_STREAM_ERROR);
        resultLength += available - stream.avail_out;
        
        while (stream.avail_out == 0) {
            // Not enought space in output. Increase:
            result.length = result.length + 1024;
            stream.next_out = (Bytef *) (result.mutableBytes + resultLength);
            available = (uInt) (result.length - resultLength);
            stream.avail_out = available;
            r = inflate(&stream, Z_NO_FLUSH);
            Require(r != Z_STREAM_ERROR);
            resultLength += available - stream.avail_out;
        }
    }];
    
    stream.next_in = NULL;
    stream.avail_in = 0;
    
    stream.next_out = (Bytef *) (result.mutableBytes + resultLength);
    uInt available = (uInt) (result.length - resultLength);
    stream.avail_out = available;
    int rFinish = inflate(&stream, Z_FINISH);
    Require(rFinish != Z_STREAM_ERROR);
    resultLength += available - stream.avail_out;
    
    while (stream.avail_out == 0) {
        // Not enought space in output. Increase:
        result.length = result.length + 1024;
        stream.next_out = (Bytef *) (result.mutableBytes + resultLength);
        available = (uInt) (result.length - resultLength);
        stream.avail_out = available;
        rFinish = inflate(&stream, Z_NO_FLUSH);
        Require(rFinish != Z_STREAM_ERROR);
        resultLength += available - stream.avail_out;
    }
    
    Require(rFinish == Z_STREAM_END);
    
    result.length = resultLength;
    
    return result;
}

@end


