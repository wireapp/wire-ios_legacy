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


@import WireTransport;
@import WireTesting;
@import WireProtos;
#import "MockTransportSession+assets.h"
#import "MockTransportSession+OTR.h"
#import "MockAsset.h"
#import <WireMockTransport/WireMockTransport-Swift.h>



@implementation MockTransportSession (Assets)

#pragma mark - Asset v2 downloading

- (ZMTransportResponse *)processAssetRequest:(ZMTransportRequest *)request;
{
    if([request matchesWithPath:@"/conversations/*/assets/*" method:ZMMethodGET]) {
        return [self processAssetGetRequestInConversation:[request RESTComponentAtIndex:1] asset:[request RESTComponentAtIndex:3] apiVersion:request.apiVersion];
    }
    else if([request matchesWithPath:@"/assets/*" method:ZMMethodGET]) {
        return [self processAssetGetRequestInConversation:request.queryParameters[@"conv_id"] asset:[request RESTComponentAtIndex:1] apiVersion:request.apiVersion];
    }
    else if ([request matchesWithPath:@"/conversations/*/otr/assets/*" method:ZMMethodGET]) {
        return [self processAssetGetRequestInConversation:[request RESTComponentAtIndex:1] asset:[request RESTComponentAtIndex:4] apiVersion:request.apiVersion];
    }
    return [ZMTransportResponse responseWithPayload:nil HTTPStatus:404 transportSessionError:nil apiVersion:request.apiVersion];
}

- (ZMTransportResponse *)sampleImageResponseWithApiVersion:(APIVersion)apiVersion {
    NSData *data =  [NSData dataWithContentsOfURL:[[NSBundle bundleForClass:self.class] URLForResource:@"medium"withExtension:@"jpg"]];
    return [[ZMTransportResponse alloc ] initWithImageData:data HTTPStatus:200 transportSessionError:nil headers:nil apiVersion:apiVersion];
}

- (ZMTransportResponse *)processAssetGetRequestInConversation:(NSString *)conversationID asset:(NSString *)identifier apiVersion:(APIVersion)apiVersion
{
    MockAsset *asset = [MockAsset assetInContext:self.managedObjectContext forID:identifier];
    if([asset.conversation isEqualToString:conversationID]) {
        return [[ZMTransportResponse alloc ] initWithImageData:asset.data HTTPStatus:200 transportSessionError:nil headers:nil apiVersion:apiVersion];
    }
    else {
        return [ZMTransportResponse responseWithPayload:@{@"error":@"mismatching conversation"} HTTPStatus:404 transportSessionError:nil apiVersion:apiVersion];
    }
        
    return [ZMTransportResponse responseWithPayload:@{@"error":@"not found"} HTTPStatus:404 transportSessionError:nil apiVersion:apiVersion];
}

#pragma mark - Asset v3

- (ZMTransportResponse *)processAssetV3Request:(ZMTransportRequest *)request
{
    if ([request matchesWithPath:@"/assets/v3" method:ZMMethodPOST]) {
        return [self processAssetV3PostWithMultipartData:[request multipartBodyItemsFromRequestOrFile] apiVersion:request.apiVersion];
    } else if ([request matchesWithPath:@"/assets/v3/*" method:ZMMethodGET]) {
        return [self processAssetV3GetWithKey:[request RESTComponentAtIndex:2] apiVersion:request.apiVersion];
    } else if ([request matchesWithPath:@"/assets/v3/*" method:ZMMethodDELETE]) {
        return [self processAssetV3DeleteWithKey:[request RESTComponentAtIndex:2] apiVersion:request.apiVersion];
    }
    return nil;
}

- (ZMTransportResponse *)processAssetV3PostWithMultipartData:(NSArray *)multipart apiVersion:(APIVersion)apiVersion;
{    
    if (multipart.count == 2) {
        
        ZMMultipartBodyItem *jsonObject = [multipart firstObject];
        ZMMultipartBodyItem *imageData  = [multipart lastObject];
        
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:jsonObject.data options:NSJSONReadingAllowFragments error:nil];
        BOOL isPublic = [json[@"public"] boolValue];
        
        NSData *data        = imageData.data;
        NSString *mimeType  = imageData.contentType;
        
        MockAsset *asset = [MockAsset insertIntoManagedObjectContext:self.managedObjectContext];
        asset.data = data;
        asset.contentType = mimeType;
        asset.identifier = [NSUUID createUUID].transportString;
        if (!isPublic) {
            asset.token = [NSUUID createUUID].transportString;
        }
        
        NSMutableDictionary *payload = [NSMutableDictionary dictionaryWithDictionary:@{@"key" : asset.identifier, @"expires" : [[NSDate date] dateByAddingTimeInterval:1000000].transportString}];
        if (asset.token) {
            payload[@"token"] = asset.token;
        }
        
        return [[ZMTransportResponse alloc] initWithPayload:[payload copy] HTTPStatus:201 transportSessionError:nil headers:@{@"Location" : [NSString stringWithFormat:@"/asset/v3/%@", asset.identifier]} apiVersion:apiVersion];
    }
    
    return [ZMTransportResponse responseWithPayload:nil HTTPStatus:400 transportSessionError:nil apiVersion:apiVersion];
}

- (ZMTransportResponse *)processAssetV3GetWithKey:(NSString *)key apiVersion:(APIVersion)apiVersion;
{
    MockAsset *asset = [MockAsset assetInContext:self.managedObjectContext forID:key];
    if (asset != nil) {
        
        return [[ZMTransportResponse alloc] initWithImageData:asset.data HTTPStatus:200 transportSessionError:nil headers:nil apiVersion:apiVersion];
    }
    return [ZMTransportResponse responseWithPayload:nil HTTPStatus:404 transportSessionError:nil apiVersion:apiVersion];
}

#pragma mark - Asset v4

- (ZMTransportResponse *)processAssetV4Request:(ZMTransportRequest *)request
{
    if ([request matchesWithPath:@"/assets/v4/*" method:ZMMethodPOST]) {
        return [self processAssetV4PostWithDomain:[request RESTComponentAtIndex:2] multipart:[request multipartBodyItemsFromRequestOrFile] apiVersion:request.apiVersion];
    } else if ([request matchesWithPath:@"/assets/v4/*/*" method:ZMMethodGET]) {
        return [self processAssetV4GetWithDomain:[request RESTComponentAtIndex:2] key:[request RESTComponentAtIndex:3] apiVersion:request.apiVersion];
    } else if ([request matchesWithPath:@"/assets/v4/*/*" method:ZMMethodDELETE]) {
        return [self processAssetV4DeleteWithDomain:[request RESTComponentAtIndex:2] key:[request RESTComponentAtIndex:3] apiVersion:request.apiVersion];
    }
    return nil;
}

@end
