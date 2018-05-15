//
//  ColyseusRoom.h
//  Colyseus-ObjC
//
//  Created by Switt Kongdachalert on 13/5/18.
//  Copyright © 2018 Switt's Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ColyseusObjCCommons.h"
#import "ColyseusStateContainer.h"
#import "ColyseusMessageEventArgs.h"

@class ColyseusConnection;

@interface ColyseusRoom : ColyseusStateContainer
@property (retain) NSString *ID;
@property (retain) NSString *name;
@property (retain) NSString *sessionID;

@property (retain) NSDictionary <NSString *, NSDictionary *>*options;

/// <summary>
/// Occurs when <see cref="Room"/> is able to connect to the server.
/// </summary>
@property (retain) NSMutableArray <void (^)(ColyseusRoom *, ColyseusEventArgs *)>* onReadytoConnect;

/// <summary>
/// Occurs when the <see cref="Client"/> successfully connects to the <see cref="Room"/>.
/// </summary>
@property (retain) NSMutableArray <void (^)(ColyseusRoom *, ColyseusMessageEventArgs *)>* onJoin;

/// <summary>
/// Occurs when some error has been triggered in the room.
/// </summary>
@property (retain) NSMutableArray <void (^)(ColyseusRoom *, ColyseusErrorEventArgs *)>* onError;

/// <summary>
/// Occurs when <see cref="Client"/> leaves this room.
/// </summary>
@property (retain) NSMutableArray <void (^)(ColyseusRoom *, ColyseusEventArgs *)>* onLeave;

/// <summary>
/// Occurs when server sends a message to this <see cref="Room"/>
/// </summary>
@property (retain) NSMutableArray <void (^)(ColyseusRoom *, ColyseusMessageEventArgs *)>* onMessage;

/// <summary>
/// Occurs after applying the patched state on this <see cref="Room"/>.
/// </summary>
@property (retain) NSMutableArray <void (^)(ColyseusRoom *, ColyseusRoomUpdateEventArgs *)>* onStateChange;

/// <summary>
/// Initializes a new instance of the <see cref="Room"/> class.
/// It synchronizes state automatically with the server and send and receive messaes.
/// </summary>
/// <param name="client">
/// The <see cref="Client"/> client connection instance.
/// </param>
/// <param name="name">The name of the room</param>
-(id)initWithName:(NSString *)name options:(NSDictionary <NSString *, id>*)options;

-(void)recv:(NSData *)data;

-(void)connect;

-(void)setConnection:(ColyseusConnection *)connection;

-(void)setState:(NSData *)encodedState remoteCurrentTime:(unsigned int)remoteCurrentTime remoteElapsedTime:(unsigned int)remoteElapsedTime;

-(void)leave;

/// <summary>
/// Send data to this room.
/// </summary>
/// <param name="data">Data to be sent</param>
-(void)send:(NSObject *)data;
@end

@interface ColyseusRoomAvailable : NSObject {
}
@property (retain) NSString *roomId;
@property (assign) unsigned int clients;
@property (assign) unsigned int maxClients;
@property (retain) NSObject *metadata;
@end
