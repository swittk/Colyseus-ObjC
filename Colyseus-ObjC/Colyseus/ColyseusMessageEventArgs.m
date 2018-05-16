//
//  ColyseusMessageEventArgs.m
//  Colyseus-ObjC
//
//  Created by Switt Kongdachalert on 14/5/18.
//  Copyright © 2018 Switt's Software. All rights reserved.
//

#import "ColyseusMessageEventArgs.h"

@implementation ColyseusEventArgs
+(ColyseusEventArgs *)event {
    return [ColyseusEventArgs new];
}
@end

@implementation ColyseusMessageEventArgs
+(ColyseusMessageEventArgs *)messageEventWithMessage:(NSObject *)message {
    ColyseusMessageEventArgs *e = [ColyseusMessageEventArgs new];
    e.message = message;
    return e;
}
@end

@implementation ColyseusErrorEventArgs
+(ColyseusErrorEventArgs *)errorEventWithMessage:(NSString *)message {
    ColyseusErrorEventArgs *e = [ColyseusErrorEventArgs new];
    e.message = message;
    return e;
}
@end

@implementation ColyseusRoomUpdateEventArgs
-(id)initWithState:(IndexedDictionary <NSString *,NSObject *>*)state isFirstState:(BOOL)isFirst {
    if(self = [super init])
    {
        _state = state;
        _isFirstState = isFirst;
    }
    return self;
}
+(ColyseusRoomUpdateEventArgs *)roomUpdateEventWithState:(id)state isFirstState:(BOOL)isFirst {
    return [[self alloc] initWithState:state isFirstState:isFirst];
}
@end
