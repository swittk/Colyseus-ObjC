//
//  MPMessagePack.h
//  MPMessagePack
//
//  Created by Gabriel on 7/3/14.
//  Copyright (c) 2014 Gabriel Handford. All rights reserved.
//

#import <Foundation/Foundation.h>

//! Project version number for MPMessagePack.
FOUNDATION_EXPORT double MPMessagePackVersionNumber;

//! Project version string for MPMessagePack.
FOUNDATION_EXPORT const unsigned char MPMessagePackVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import "PublicHeader.h"

#import "MPDefines.h"
#import "MPMessagePackWriter.h"
#import "MPMessagePackReader.h"

#import "MPLog.h"
//#import "MPRPCProtocol.h"

#import "NSDictionary+MPMessagePack.h"
#import "NSArray+MPMessagePack.h"
#import "NSData+MPMessagePack.h"

#ifdef __MAC_OS_X_VERSION_MAX_ALLOWED
#import "MPXPCProtocol.h"
#import "MPXPCService.h"
#import "MPXPCClient.h"
#endif


