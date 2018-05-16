//
//  ColyseusClient.h
//  Colyseus-ObjC
//
//  Created by Switt Kongdachalert on 13/5/18.
//  Copyright © 2018 Switt's Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ColyseusObjCCommons.h"
#import "ColyseusMessageEventArgs.h"

@class ColyseusRoom;
@class ColyseusConnection;
@class RoomAvailable;

@interface ColyseusClient : NSObject
@property (retain) NSString *ID;

@property (retain) NSMutableArray <void (^)(ColyseusClient *, ColyseusEventArgs *)>*onOpen;
@property (retain) NSMutableArray <void (^)(ColyseusClient *, ColyseusErrorEventArgs *)>*onClose;
@property (retain) NSMutableArray <void (^)(ColyseusClient *, ColyseusErrorEventArgs *)>*onError;
@property (retain) NSMutableArray <void (^)(ColyseusClient *, ColyseusMessageEventArgs *)>*onMessage; //MessageEventArgs
-(id)initWithEndpoint:(NSString *)endPoint ID:(NSString *)ID;
-(void)recv:(id)data;
-(void)connect;
-(void)close;
-(ColyseusRoom *)join:(NSString *)roomName options:(nullable NSDictionary <NSString *, id>*)options;
@end
