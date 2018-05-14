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
@class ColyseusConnection;

@interface ColyseusConnection : NSObject <PSWebSocketDelegate>
{
    PSWebSocket *socket;
}
@property (readonly) NSURL *url;
@property (retain) NSMutableArray <ColyseusEventHandler>*onOpen;
@property (retain) NSMutableArray <ColyseusEventHandler>*onClose;
@property (retain) NSMutableArray <ColyseusEventHandler>*onMessage;
@property (retain) NSMutableArray <ColyseusEventHandler>*onError;

@property (readonly) BOOL isOpen;

-(id)initWithURL:(NSURL *)url;
-(void)send:(id)data; /*Accepts NSDictionary, NSArray, and NSData (NSData should already be packed by MessagePack)*/
-(void)connect;
-(void)close;
@end
