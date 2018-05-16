//
//  ColyseusMessageEventArgs.h
//  Colyseus-ObjC
//
//  Created by Switt Kongdachalert on 14/5/18.
//  Copyright © 2018 Switt's Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ColyseusObjCCommons.h"

@interface ColyseusEventArgs : NSObject
+(ColyseusEventArgs *)event;
@end

@interface ColyseusErrorEventArgs : ColyseusEventArgs
@property (retain) NSString *message;
+(ColyseusErrorEventArgs *)errorEventWithMessage:(NSString *)message;
@end

@interface ColyseusMessageEventArgs : ColyseusEventArgs
@property (retain) NSObject *message;
+(ColyseusMessageEventArgs *)messageEventWithMessage:(NSObject *)message;
@end

@interface ColyseusRoomUpdateEventArgs : ColyseusEventArgs
@property (retain) IndexedDictionary <NSString *,NSObject *>*state;
@property (assign) BOOL isFirstState;
-(id)initWithState:(IndexedDictionary <NSString *,NSObject *>*)state isFirstState:(BOOL)isFirst;
+(ColyseusRoomUpdateEventArgs *)roomUpdateEventWithState:(IndexedDictionary <NSString *,NSObject *>*)state isFirstState:(BOOL)isFirst;
@end
