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
        NSLog(@"My endpoint is %@", self.endpoint);
        self.connection = [self createConnectionWithPath:nil options:nil];
        
        __block ColyseusClient *weakself = self;
        [self.connection.onMessage addObject:^void(ColyseusConnection *c, ColyseusMessageEventArgs *e) {
            [weakself recv:e.message];
        }];
        
        [self.connection.onClose addObject:^void(ColyseusConnection *c, ColyseusErrorEventArgs *e) {
            for(void (^h)(ColyseusClient *, ColyseusErrorEventArgs *) in weakself.onClose) {
                h(weakself, e);
            }
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
        for(ColyseusRoom *room in self.rooms.allValues) {
            [room recv:data];
        }
    }
}

-(ColyseusRoom *)join:(NSString *)roomName options:(nullable NSDictionary <NSString *, id>*)opts {
    NSMutableDictionary *options;
    if (opts == nil) {
        options = [NSMutableDictionary new];
    }
    if(![opts isKindOfClass:[NSMutableDictionary class]]) {
        options = [opts mutableCopy];
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
    NSString *fixedPath;
    if([path length]) {
        if([path characterAtIndex:0] == '/') fixedPath = path;
        else fixedPath = [NSString stringWithFormat:@"/%@", path];
    }
    else {
        fixedPath = @"/";
    }
    comps.path = fixedPath;
    comps.query = [list componentsJoinedByString:@"&"];
//    NSLog(@"connectionComps is %@", comps);
    NSLog(@"Created connectionComps yields URL of %@", [comps URL]);
    
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
//    NSLog(@"client received message of code %d, msg %@", code, message);
    switch (code) {
        case ColyseusProtocol_USER_ID: {
            self.ID = [self stringifyData:[message safeObjectAtIndex:1]];
            for(void (^h)(ColyseusClient *, ColyseusEventArgs *) in self.onOpen) {
                h(self, [ColyseusEventArgs event]);
            }
        } break;
        case ColyseusProtocol_JOIN_ROOM: {
            int requestId = [message [2] intValue];
            
            ColyseusRoom *room;
            room = self.connectingRooms[@(requestId)];
            if(room) {
                room.ID = [self stringifyData:message[1]];
                self.endpoint.path = [NSString stringWithFormat:@"/%@", room.ID];
                self.endpoint.query = [NSString stringWithFormat:@"colyseusid=%@",self.ID];
                
                [room setConnection:[self createConnectionWithPath:room.ID options:[room.options mutableCopy]]];
                __block ColyseusClient *weakself = self;
                [room.onLeave addObject:^void(ColyseusRoom *room, ColyseusEventArgs *e) {
                    [weakself onLeaveRoom:room];
                }];
//                room.OnLeave += OnLeaveRoom;
                
                [self.rooms setObject:room forKey:room.ID];
//                this.rooms.Add (room.id, room);
                [self.connectingRooms removeObjectForKey:@(requestId)];
//                this.connectingRooms.Remove (requestId);
            }
            else {
                NSLog(@"Can't Join Room Using RequestID : %d", requestId);
//                throw new Exception ("can't join room using requestId " + requestId.ToString());
            }
        }break;
        case ColyseusProtocol_JOIN_ERROR: {
            for(void (^h)(ColyseusClient *, ColyseusErrorEventArgs *) in self.onError) {
                h(self, [ColyseusErrorEventArgs errorEventWithMessage:message[2]]);
            }
        }break;
        default: {
            for(void (^h)(ColyseusClient *, ColyseusMessageEventArgs *) in self.onMessage) {
                h(self, [ColyseusMessageEventArgs messageEventWithMessage:message[1]]);
            }
        }break;
    }
}

-(void)onLeaveRoom:(ColyseusRoom *)sender
{
    NSLog(@"Left room %@", sender.ID);
    [self.rooms removeObjectForKey:sender.ID];
}

-(NSString *)stringifyData:(id)data {
    if([data isKindOfClass:[NSData class]]) {
        return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    else if([data isKindOfClass:[NSString class]]) {
        return data;
    }
    return nil;
}


@end
