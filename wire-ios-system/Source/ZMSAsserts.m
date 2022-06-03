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


#import <Foundation/Foundation.h>
#import "ZMSAsserts.h"

void ZMAssertionDump_NSString(NSString *assertion, NSString *filename, int linenumber, NSString *message) {
    ZMAssertionDump(assertion.UTF8String, filename.UTF8String, linenumber, "%s", message.UTF8String);
}

void ZMAssertionDump(const char * const assertion, const char * const filename, int linenumber, char const * const format, ...) {

    // prepare content
    char * message = NULL;
    va_list ap;
    va_start(ap, format);
    if ((format == NULL) || (vasprintf(&message, format, ap) == 0)) {
        message = NULL;
    }
    va_end(ap);
    NSString *output = [NSString stringWithFormat:@"ASSERT: [%s:%d] <%s> %s",
                        filename ? filename : "",
                        linenumber,
                        assertion ? assertion : "",
                        message ? message : ""];
    
    // prepare file and exclude from backup
    NSURL *dumpFile = ZMLastAssertionFile();
    [[NSData data] writeToURL:dumpFile atomically:NO];
    [dumpFile setResourceValue:@YES forKey:NSURLIsExcludedFromBackupKey error:nil];
    
    // dump to file
    [[output dataUsingEncoding:NSUTF8StringEncoding] writeToURL:dumpFile atomically:YES];
}

NSURL* ZMLastAssertionFile() {
    
    NSURL* appSupportDir = [[NSFileManager defaultManager]
                            URLForDirectory:NSApplicationSupportDirectory
                            inDomain:NSUserDomainMask
                            appropriateForURL:nil
                            create:YES
                            error:nil];
    
    return [appSupportDir URLByAppendingPathComponent:@"last_assertion.log"];
}
