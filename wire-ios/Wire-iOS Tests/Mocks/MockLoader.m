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


#import "MockLoader.h"
#import "MockUser.h"
#import "MockConversation.h"

@implementation MockLoader

+ (NSArray *)mockObjectsOfClass:(Class)aClass fromFile:(NSString *)fileName
{
    NSString *path = [[NSBundle bundleForClass:self.class] pathForResource:fileName.stringByDeletingPathExtension
                                                                    ofType:fileName.pathExtension];
    
    NSError *error = nil;
    NSData *data = [NSData dataWithContentsOfFile:path options:0 error:&error];
    if (data == nil) {
        NSLog(@"Mock file: %@ reading failed: %@", path, error);
        return nil;
    }
    
    NSArray *jsonObjects = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if (jsonObjects == nil) {
        NSLog(@"Mock file: %@ JSON parsing failed: %@", path, error);
        return nil;
    }
    
    NSMutableArray *mockedObjects = [NSMutableArray new];
    for (NSDictionary *jsonObject in jsonObjects) {
        
        NSAssert([aClass conformsToProtocol:@protocol(Mockable)], @"Mockable class must conform to Mockable!");
        
        id object = [[aClass alloc] initWithJSONObject:jsonObject];
        [mockedObjects addObject:object];
    }
    
    return mockedObjects;
}

@end
