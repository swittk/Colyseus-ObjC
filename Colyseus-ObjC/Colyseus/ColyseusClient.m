//
//  ColyseusClient.m
//  Colyseus-ObjC
//
//  Created by Switt Kongdachalert on 13/5/18.
//  Copyright © 2018 Switt's Software. All rights reserved.
//

#import "ColyseusClient.h"
#import "ColyseusRoom.h"
#import "MPMessagePack.h"
#import "ColyseusObjCCommons.h"
#import "ColyseusConnection.h"
#import "ColyseusMessageEventArgs.h"

@interface NSArray (SafeGet)
-(id)safeObjectAtIndex:(NSUInteger)index;
@end
@implementation NSArray (SafeGet)
-(id)safeObjectAtIndex:(NSUInteger)index {
    if([self count] <= index) return nil;
    return [self objectAtIndex:index];
}
@end

@interface ColyseusClient ()
@property (retain) NSURLComponents *endpoint;
@property (retain) ColyseusConnection *connection;

@property (retain) NSMutableDictionary <NSString *, ColyseusRoom *>*rooms;
// = new Dictionary<string, Room> ();
@property (retain) NSMutableDictionary <NSNumber */*int*/, ColyseusRoom *>*connectingRooms;
// = new Dictionary<int, Room> ();

@property (assign) int requestId;
@property (retain) NSMutableDictionary<NSNumber *, ColyseusAction>* roomsAvailableRequests;
// = new Dictionary<int, Action<RoomAvailable[]>();

@property (retain) NSMutableArray <ColyseusRoomAvailable *>*roomsAvailableResponse;


@end
@implementation ColyseusClient

-(id)initWithEndpoint:(NSString *)endPoint ID:(NSString *)ID {
    if(self = [super init]) {
        _rooms = [NSMutableDictionary new];
        _connectingRooms = [NSMutableDictionary new];
        _roomsAvailableRequests = [NSMutableDictionary new];
        _roomsAvailableResponse = [NSMutableArray arrayWithObject:[ColyseusRoomAvailable new]];
        
        _onOpen = [NSMutableArray new];
        _onClose = [NSMutableArray new];
        _onError = [NSMutableArray new];
        _onMessage = [NSMutableArray new];
        
        self.ID = ID;
        self.endpoint = [NSURLComponents componentsWithString:endPoint];
        self.connection = [self createConnectionWithPath:nil options:nil];
        
        __block ColyseusClient *weakself = self;
        [self.connection.onMessage addObject:^(NSArray *args) {
            if([args count] < 2) return;
//            ColyseusConnection *connection = args[0];
            id message = args[1];
            
            [weakself recv:message];
        }];
//        self.connection.onClose += (object sender, EventArgs e) => this.OnClose.Invoke(sender, e);
    }
    return self;
}

-(void)connect {
    [self.connection connect];
}
-(void)close {
    [self.connection close];
}
-(void)recv:(id)data {
    if (data != nil && [data isKindOfClass:[NSData class]])
    {
        [self parseMessage:data];
        
        // TODO: this may not be a good idea?
        for(ColyseusRoom *room in self.rooms) {
            [room recv:data];
        }
    }
}

-(ColyseusRoom *)join:(NSString *)roomName options:(nullable NSMutableDictionary <NSString *, id>*)options {
    if (options == nil) {
        options = [NSMutableDictionary new];
    }
    
    int requestId = ++self.requestId;
    [options setObject:@(requestId) forKey:@"requestId"];
    
    ColyseusRoom *room = [[ColyseusRoom alloc] initWithName:roomName options:options];
    [self.connectingRooms setObject:room forKey:@(requestId)];

    [self.connection send:@[@(ColyseusProtocol_JOIN_ROOM), roomName, options]];
//    this.connection.Send (new object[]{Protocol.JOIN_ROOM, roomName, options});
    
    return room;
}

-(ColyseusConnection *)createConnectionWithPath:(nullable NSString *)path
                                        options:(nullable NSMutableDictionary <NSString *, id>*)options {
    if(options == nil) {
        options = [NSMutableDictionary new];
    }
    if(self.ID != nil) {
        [options setObject:self.ID forKey:@"colyseusid"];
    }
    
    NSMutableArray *list = [NSMutableArray new];
    for(NSString *key in options) {
        [list addObject:[NSString stringWithFormat:@"%@=%@",key, options[key]]];
    }
    
    NSURLComponents *comps = [self.endpoint copy];
    comps.path = path;
    comps.query = [list componentsJoinedByString:@"&"];
    
    return [[ColyseusConnection alloc] initWithURL:[comps URL]];
}

-(void)parseMessage:(NSData *)recv
{
    NSError *arrayError;
    NSArray *message = [recv mp_array:&arrayError];
    if(arrayError) {
        NSLog(@"Array creation error : %@", arrayError);
    }
    int code = [[message safeObjectAtIndex:0] intValue];
    
    switch (code) {
        case ColyseusProtocol_USER_ID: {
            self.ID = [message safeObjectAtIndex:1];
            for(ColyseusEventHandler h in self.onOpen) {
                h(@[self, [ColyseusEventArgs event]]);
            }
        } break;
        case ColyseusProtocol_JOIN_ROOM: {
            int requestId = [message [2] intValue];
            
            ColyseusRoom *room;
            room = self.connectingRooms[@(requestId)];
            if(room) {
                room.ID = message[1];
                self.endpoint.path = [NSString stringWithFormat:@"/%@", room.ID];
                self.endpoint.query = [NSString stringWithFormat:@"colyseusid=%@",self.ID];
                
                [room setConnection:[self createConnectionWithPath:room.ID options:[room.options mutableCopy]]];
                __block ColyseusClient *weakself = self;
                [room.onLeave addObject:^(NSArray *args) {
                    if([args count] < 2) {NSLog(@"args < 2"); return;}
                    [weakself onLeaveRoom:args[0] arguments:args[1]];
                }];
//                room.OnLeave += OnLeaveRoom;
                
                [self.rooms setObject:room forKey:room.ID];
//                this.rooms.Add (room.id, room);
                [self.connectingRooms removeObjectForKey:@(requestId)];
//                this.connectingRooms.Remove (requestId);
            }
            else {
                NSLog(@"Can't Join Room Using RequestID : %d", @(requestId));
//                throw new Exception ("can't join room using requestId " + requestId.ToString());
            }
        }break;
        case ColyseusProtocol_JOIN_ERROR: {
            for(ColyseusEventHandler h in self.onError) {
                h(@[self, [ColyseusErrorEventArgs errorEventWithMessage:message[2]]]);
            }
        }break;
        default: {
            for(ColyseusEventHandler h in self.onMessage) {
                h(@[self, [ColyseusMessageEventArgs messageEventWithMessage:message]]);
            }
        }break;
    }
}

-(void)onLeaveRoom:(ColyseusRoom *)sender arguments:(NSArray *)arguments
{
    [self.rooms removeObjectForKey:sender.ID];
}


@end
