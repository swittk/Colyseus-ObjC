//
//  ColyseusClient.h
//  Colyseus-ObjC
//
//  Created by Switt Kongdachalert on 13/5/18.
//  Copyright © 2018 Switt's Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ColyseusObjCCommons.h"

@class ColyseusRoom;
@class ColyseusConnection;
@class RoomAvailable;

@interface ColyseusClient : NSObject
@property (retain) NSString *ID;

@property (retain) NSMutableArray <ColyseusEventHandler>*onOpen;
@property (retain) NSMutableArray <ColyseusEventHandler>*onClose;
@property (retain) NSMutableArray <ColyseusEventHandler>*onError;
@property (retain) NSMutableArray <ColyseusEventHandler>*onMessage; //MessageEventArgs
-(id)initWithEndpoint:(NSString *)endPoint ID:(NSString *)ID;
-(void)recv:(id)data;
-(void)connect;
-(void)close;
-(ColyseusRoom *)join:(NSString *)roomName options:(nullable NSMutableDictionary <NSString *, id>*)options;
@end
