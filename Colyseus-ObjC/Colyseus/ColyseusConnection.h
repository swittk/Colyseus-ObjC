//
//  ColyseusConnection.h
//  Colyseus-ObjC
//
//  Created by Switt Kongdachalert on 13/5/18.
//  Copyright © 2018 Switt's Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PSWebSocket.h"
#import "ColyseusObjCCommons.h"
#import "ColyseusMessageEventArgs.h"

@class ColyseusConnection;

@interface ColyseusConnection : NSObject <PSWebSocketDelegate>
{
    PSWebSocket *socket;
}
@property (readonly) NSURL *url;
///@[ColyseusConnection, ColyseusEventArgs]
@property (retain) NSMutableArray <void (^)(ColyseusConnection *, ColyseusEventArgs *)>*onOpen;

///@[ColyseusConnection, ColyseusErrorEventArgs]
@property (retain) NSMutableArray <void (^)(ColyseusConnection *, ColyseusErrorEventArgs *)>*onClose;

///@[ColyseusConnection, ColyseusMessageEventArgs]
@property (retain) NSMutableArray <void (^)(ColyseusConnection *, ColyseusMessageEventArgs *)>*onMessage;

///@[ColyseusConnection, ColyseusErrorEventArgs]
@property (retain) NSMutableArray <void (^)(ColyseusConnection *, ColyseusErrorEventArgs *)>*onError;

@property (readonly) BOOL isOpen;

-(id)initWithURL:(NSURL *)url;
-(void)send:(id)data; /*Accepts NSDictionary, NSArray, and NSData (NSData should already be packed by MessagePack)*/
-(void)connect;
-(void)close;
@end
