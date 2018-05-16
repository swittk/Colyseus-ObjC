//
//  ColyseusRoom.m
//  Colyseus-ObjC
//
//  Created by Switt Kongdachalert on 13/5/18.
//  Copyright © 2018 Switt's Software. All rights reserved.
//

#import "ColyseusRoom.h"
#import "ColyseusObjCCommons.h"
#import "MPMessagePack.h"
#import "ColyseusConnection.h"
#import "ColyseusMessageEventArgs.h"
#import "fossilize.h"

@interface NSArray (SafeGet)
-(id)safeObjectAtIndex:(NSUInteger)index;
@end
@implementation NSArray (SafeGet)
-(id)safeObjectAtIndex:(NSUInteger)index {
    if([self count] <= index) return nil;
    return [self objectAtIndex:index];
}
@end

@interface ColyseusRoom ()
@property (retain, nonatomic) ColyseusConnection *connection;
@property (retain) NSData *previousState;
@end

@implementation ColyseusRoom

-(id)initWithName:(NSString *)name options:(NSDictionary<NSString *,id> *)options {
    if(self = [super initWithState:[IndexedDictionary new]]) {
        _name = name;
        _options = options;
        
        _onReadytoConnect = [NSMutableArray new];
        _onJoin = [NSMutableArray new];
        _onError = [NSMutableArray new];
        _onLeave = [NSMutableArray new];
        _onMessage = [NSMutableArray new];
        _onStateChange = [NSMutableArray new];
    }
    return self;
}

-(void)recv:(NSData *)data {
    if (data != nil)
    {
//        NSLog(@"Data is type %@", [data class]);
        [self parseMessage:data];
    }
}

-(void)connect {
    [self.connection connect];
}

-(void)setConnection:(ColyseusConnection *)connection {
    _connection = connection;
    
    ColyseusRoom *weakself = self;
    
    [connection.onMessage addObject:^void(ColyseusConnection *c, ColyseusMessageEventArgs *e) {
        [weakself recv:(NSData *)e.message];
    }];
    
    [connection.onClose addObject:^void(ColyseusConnection *c, ColyseusErrorEventArgs *e) {
        for(void (^h)(ColyseusRoom *, ColyseusErrorEventArgs *) in weakself.onLeave) {
            h(self, e);
        }
    }];
    
    [connection.onError addObject:^void(ColyseusConnection *c, ColyseusErrorEventArgs *e) {
        for(void (^h)(ColyseusRoom *, ColyseusErrorEventArgs *) in weakself.onError) {
            h(self, e);
        }
    }];
    
    for(void (^h)(ColyseusRoom *, ColyseusEventArgs *) in weakself.onReadytoConnect) {
        h(self, [ColyseusEventArgs new]);
    }
}

-(void)setState:(NSData *)encodedState remoteCurrentTime:(unsigned int)remoteCurrentTime remoteElapsedTime:(unsigned int)remoteElapsedTime {
    // Deserialize
    NSError *error;
    NSDictionary *state = [encodedState mp_dict:&error];
    if(error || !state) {
        NSLog(@"ERROR Decoding state : %@", [error description]);
    }
    else {
        //    var state = MsgPack.Deserialize<IndexedDictionary<string, object>> (new MemoryStream(encodedState));
        IndexedDictionary *idxdict = [IndexedDictionary dictionaryWithDictionary:state];
        [self setState:idxdict];
        //    this.Set(state);
        
        if ([self.onStateChange count]) {
            ColyseusRoomUpdateEventArgs *args = [[ColyseusRoomUpdateEventArgs alloc] initWithState:[IndexedDictionary dictionaryWithDictionary:state] isFirstState:YES];
            for(void (^h)(ColyseusRoom *room, ColyseusRoomUpdateEventArgs *u) in self.onStateChange) {
                h(self, args);
            }
            //        self.OnStateChange(self, new RoomUpdateEventArgs (state, true));
        }
    }
    
//    NSLog(@"set previous state %@", encodedState);
    self.previousState = encodedState;
}

-(void)leave {
    if (self.ID != nil) {
        [self.connection close];
    } else {
        for(void (^h)(ColyseusRoom *room, ColyseusEventArgs *e) in self.onLeave) {
            h(self, [ColyseusEventArgs new]);
        }
//        this.OnLeave.Invoke (this, new EventArgs ());
    }
}

-(void)send:(NSObject *)data {
    [self.connection send:@[@(ColyseusProtocol_ROOM_DATA), self.ID, data]];
    if(!self.connection) {
        NSLog(@"I have no connection :(");
    }
    else {
        NSLog(@"I sent data %@", data);
    }
//    this.connection.Send(new object[]{Protocol.ROOM_DATA, this.id, data});
}

-(void)parseMessage:(NSData *)recv {
    NSError *error;
    NSArray *message = [recv mp_array:&error];
    if(!message || error) {
        NSLog(@"ParseMessage Error : %@", error);
        return;
    }
    
    NSNumber *codeNumber = [message safeObjectAtIndex:0];
    if(![codeNumber isKindOfClass:[NSNumber class]]) {
        NSLog(@"First index (code) is not NSNumber; error"); return;
    }
    int code = [codeNumber intValue];
//    NSLog(@"Message with code of %d", code);
    switch (code) {
        case ColyseusProtocol_JOIN_ROOM: {
            self.sessionID = [self stringifyData:[message safeObjectAtIndex:1]];
            for(void (^h)(ColyseusRoom *, ColyseusMessageEventArgs *) in self.onJoin) {
                h(self, [ColyseusMessageEventArgs messageEventWithMessage:self.sessionID]);
            }
        } break;
        case ColyseusProtocol_JOIN_ERROR: {
            for(void (^h)(ColyseusRoom *, ColyseusErrorEventArgs *) in self.onError) {
                h(
                    self,
                    [ColyseusErrorEventArgs errorEventWithMessage:
                     [NSString stringWithFormat:@"Join Error : %@",
                     [self stringifyData:[message safeObjectAtIndex:2]]]
                     ]
                  );
            }
        }break;
        case ColyseusProtocol_LEAVE_ROOM: {
            [self leave];
        }break;
        case ColyseusProtocol_ROOM_STATE: {
            //This is a message that has been sent from messagepack; therefore it must be already encoded.. probably a form of string
            NSData *encodedState = [message safeObjectAtIndex:2]; //Original code was index 1, but somehow I received index of 2
//            NSLog(@"ROOM_STATE message is %@", message);
//            NSLog(@"try stringify [1] : %@", [self stringifyData:message[1]]); //As seen here, index 1 is simply the roomId or connectionId, something of that sort
            if([encodedState isKindOfClass:[NSData class]]) {
                NSLog(@"ROOM_STATE is NSData!");
            }
            else if([encodedState isKindOfClass:[NSString class]]) {
                NSLog(@"ROOM_STATE is NSString!");
                NSLog(@"it is %@", encodedState);
                encodedState = [(NSString *)encodedState dataUsingEncoding:NSUTF8StringEncoding];
            }
            // TODO:
            // https://github.com/deniszykov/msgpack-unity3d/issues/8
            
            unsigned int remoteCurrentTime = [self unsignintifyData:message[2]];// (double) message [2];
            unsigned int remoteElapsedTime = [self unsignintifyData:message[3]];//[message [3] intValue];
            
            NSLog(@"About to assign room state with time : %d, %d", remoteCurrentTime, remoteElapsedTime);
            // this.SetState (state, remoteCurrentTime, remoteElapsedTime);
            [self setState:encodedState remoteCurrentTime:remoteCurrentTime remoteElapsedTime:remoteElapsedTime];
        }break;
        case ColyseusProtocol_ROOM_STATE_PATCH: {
            //This is a message that has been sent from messagepack; therefore it must be already encoded.. probably a form of string
            //var data = (List<object>) message [1];
//            NSLog(@"ROOM_STATE_PATCH message is %@", message);
            id msg = [message safeObjectAtIndex:2]; //Original code was index 1, but somehow I received index of 2
            NSData *data = [self dataify:msg];
//            NSLog(@"ROOM_STATE_PATCH Data is of class %@", [[data class] description]);
            if([data isKindOfClass:[NSString class]]) {
                NSLog(@"ROOM_STATE is NSString!");
                NSLog(@"it is %@", data);
                data = [(NSString *)data dataUsingEncoding:NSUTF8StringEncoding];
            }
//            byte[] patches = new byte[data.Count];
//            uint i = 0;
//            foreach (var b in data) {
//                patches [i] = Convert.ToByte(b);
//                i++;
//            }
//
//            this.Patch (patches);
            //All this code made sense once I found that message[2] is an array of numbers
            //This number to byte loop code is implemented in patch:
            [self patch:data];
        }break;
        case ColyseusProtocol_ROOM_DATA: {
            //Again, message index of 1 is room ID
            NSObject *msg = [message safeObjectAtIndex:2];
            for(void (^h)(ColyseusRoom *, ColyseusMessageEventArgs *) in self.onMessage) {
                h(self, [ColyseusMessageEventArgs messageEventWithMessage:msg]);
            }
        }break;
        default:
            break;
    }
}



-(void)patch:(NSData *)delta {
    NSInteger alloclen = _previousState.length + delta.length;
//    NSLog(@"allocating %d", alloclen);
    char *buffer = (char *)malloc(_previousState.length + delta.length);
    int newStateSize = delta_apply([_previousState bytes], (int)_previousState.length, [delta bytes], (int)delta.length, buffer);
    if(newStateSize == -1) {
        NSLog(@"ERROR; Invalid state size... %d", newStateSize);
        free(buffer);
        return;
    }
//    _previousState = Fossil.Delta.Apply (this._previousState, delta);
    NSData *newStateData = [NSData dataWithBytes:buffer length:newStateSize];
    self.previousState = newStateData;
    free(buffer);
    
    NSDictionary *newState = [newStateData mp_dict:nil];//MsgPack.Deserialize<IndexedDictionary<string, object>> (new MemoryStream(this._previousState));
    
//    this.Set(newState);
    [self set:[IndexedDictionary dictionaryWithDictionary:newState]];
    
    for(void (^h)(ColyseusRoom *, ColyseusRoomUpdateEventArgs *) in self.onStateChange) {
        h(self, [ColyseusRoomUpdateEventArgs roomUpdateEventWithState:self.state isFirstState:NO]);
    }
//    if (this.OnStateChange)
//        this.OnStateChange.Invoke(this, new RoomUpdateEventArgs(this.state));

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

-(unsigned int)unsignintifyData:(id)data {
    if([data isKindOfClass:[NSData class]]) {
        NSData *d = data;
        return [[[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding] intValue];
    }
    else if([data isKindOfClass:[NSNumber class]]) {
        return [data unsignedIntValue];
    }
    else if([data isKindOfClass:[NSString class]]) {
        return [data intValue];
    }
    return nil;
}

/*
 Now that this message in the second index is an array, this patch of code makes more sense
 //        patches = new byte[data.Count];
 //                    uint i = 0;
 //                    foreach (var b in data) {
 //                        patches [i] = Convert.ToByte(b);
 //                        i++;
 //                    }
 //
 //                    this.Patch (patches);

 */
-(NSData *)dataify:(id)message {
    if([message isKindOfClass:[NSData class]]) {
        return message;
    }
    else if([message isKindOfClass:[NSArray class]]) {
        NSArray *m = message;
        NSMutableData *d = [NSMutableData new];
        for(NSNumber *n in m) {
            char c = [n charValue];
            [d appendBytes:&c length:1];
        }
        return d;
    }
    return [NSData data];
}
@end


@implementation ColyseusRoomAvailable
@end
