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
@import XCTest;
@import OCMock;

@interface ZMTransportCodecTests : XCTestCase


@end

@implementation ZMTransportCodecTests {
    
    id _URLResponse;
    NSData *_validJson;

}

- (void)setUp
{
    [super setUp];
    
    _URLResponse = [OCMockObject niceMockForClass:[NSHTTPURLResponse class]];
    [[[_URLResponse stub] andReturn:@{@"Content-Type": @"application/json; charset=UTF-8"}] allHeaderFields];
    
    _validJson = [@"{\"name\" : \"boo\"}" dataUsingEncoding:NSUTF8StringEncoding];
}

- (void)tearDown
{
    [super tearDown];
}

- (void)testThatItReturnsNilFromAnEmptyNSURLResponse
{
    id<ZMTransportData> parsed = [ZMTransportCodec interpretResponse:_URLResponse data:[NSData data] error:nil];
    XCTAssertNil(parsed);
}

- (void)testThatItReturnsADictionaryWithJSONDictionary
{
    
    id<ZMTransportData> parsed = [ZMTransportCodec interpretResponse:_URLResponse data:_validJson error:nil];
    XCTAssertEqualObjects(parsed, @{@"name" : @"boo"});
}

-(void)testThatItReturnsNilFromANSURLResponseWithAErrorStatusCode
{

    for (int status = 500; status <= 599; ++status) {
        [[[_URLResponse expect] andReturnValue:[NSNumber numberWithInteger:status]] statusCode];
        
        id<ZMTransportData> parsed = [ZMTransportCodec interpretResponse:_URLResponse data:_validJson error:nil];
        XCTAssertNil(parsed);
        [_URLResponse verify];
    }

}

- (void)testThatItReturnsNilIfTheJSONIsMalformed
{
    NSString *json = @"{\"name\" : \"boo\"  ";
    id<ZMTransportData> parsed = [ZMTransportCodec interpretResponse:_URLResponse data:[json dataUsingEncoding:NSUTF8StringEncoding] error:nil];
    XCTAssertNil(parsed);
}

- (void)testThatItReturnsNilIfItReceivesAnErrorObject
{

    NSError *actualError = [NSError errorWithDomain:@"Test" code:-1 userInfo:@{}];
    id<ZMTransportData> parsed = [ZMTransportCodec interpretResponse:_URLResponse data:_validJson error:actualError];
    XCTAssertNil(parsed);
}


- (void)testThatItReturnsNilIfTheContentTypeIsNotJSON
{
    id htmlURLResponse = [OCMockObject niceMockForClass:[NSHTTPURLResponse class]];
    [[[htmlURLResponse stub] andReturn:@{@"Content-Type": @"text/html; charset=UTF-8"}] allHeaderFields];
    id<ZMTransportData> parsed = [ZMTransportCodec interpretResponse:htmlURLResponse data:_validJson error:nil];
    XCTAssertNil(parsed);
}

-(void)testThatItGeneratesNSDataFromNSDictionary
{
    NSDictionary *dict = @{
                           @"name" : @"Marco",
                           @"age" : @30,
                           @"family" : @{
                                   @"father" : @"Luca",
                                   @"mother" : @"Alina",
                                   },
                           @"cars": @[@312, @32131]
                           };
    NSData *output = [ZMTransportCodec encodedTransportData:dict];
    NSError *err;
    id<ZMTransportData> dictOutput = [NSJSONSerialization JSONObjectWithData:output options:0 error:&err];
    XCTAssertEqualObjects(dict, dictOutput);
    
}

-(void)testThatItGeneratesNSDataFromNSArray
{
    NSArray *arr = @[
                        @{
                           @"name" : @"Marco",
                        },
                        @{
                            @"name" : @"Arne",
                        }
                     ];
    NSData *output = [ZMTransportCodec encodedTransportData:arr];
    NSError *err;
    id<ZMTransportData> arrOutput = [NSJSONSerialization JSONObjectWithData:output options:0 error:&err];
    XCTAssertEqualObjects(arr, arrOutput);
}

-(void)testThatItAssertsOnUnserializableData
{
    NSArray *arr = @[ [[NSError alloc] init] ];
    XCTAssertThrows([ZMTransportCodec encodedTransportData:arr]);
}

@end
