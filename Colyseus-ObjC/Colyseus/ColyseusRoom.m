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
#import "AXMutableOrderedDictionary.h"
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
@property (assign) NSData *previousState;
@end

@implementation ColyseusRoom

-(id)initWithName:(NSString *)name options:(NSDictionary<NSString *,id> *)options {
    if(self = [super initWithState:[IndexedDictionary new]]) {
        _name = name;
        _options = options;
    }
    return self;
}

-(void)recv:(NSData *)data {
    if (data != nil)
    {
        [self parseMessage:data];
    }
}

-(void)connect {
    [self.connection connect];
}

-(void)setConnection:(ColyseusConnection *)connection {
    self.connection = connection;
    
    ColyseusRoom *weakself = self;
    [self.connection.onClose addObject:^(NSArray *args) {
        if([args count] < 2) return;
        //        NSObject *sender = args[0];
        for(ColyseusEventHandler h in weakself.onLeave) {
            h(args);
        }
    }];
    
    [self.connection.onError addObject:^(NSArray *args) {
        for(ColyseusEventHandler h in weakself.onError) {
            h(args);
        }
    }];
    
    for(ColyseusEventHandler h in weakself.onReadytoConnect) {
        h(@[self, [ColyseusEventArgs new]]);
    }
}

-(void)setState:(NSData *)encodedState remoteCurrentTime:(unsigned int)remoteCurrentTime remoteElapsedTime:(unsigned int)remoteElapsedTime {
    // Deserialize
    NSError *error;
    NSDictionary *state = [encodedState mp_dict:&error];
    if(error || !state) {
        NSLog(@"ERROR Decoding state : %@", [error description]);
        return;
    }
//    var state = MsgPack.Deserialize<IndexedDictionary<string, object>> (new MemoryStream(encodedState));
    IndexedDictionary *idxdict = [IndexedDictionary dictionaryWithDictionary:state];
    [self setState:idxdict];
//    this.Set(state);
    
    if (self.onStateChange != nil) {
        ColyseusRoomUpdateEventArgs *args = [[ColyseusRoomUpdateEventArgs alloc] initWithState:[IndexedDictionary dictionaryWithDictionary:state] isFirstState:YES];
        for(ColyseusEventHandler h in self.onStateChange) {
            h(@[self, args]);
        }
//        self.OnStateChange(self, new RoomUpdateEventArgs (state, true));
    }
    
    self.previousState = encodedState;
}

-(void)leave {
    if (self.ID != nil) {
        [self.connection close];
    } else {
        for(ColyseusEventHandler h in self.onLeave) {
            h(@[self, [ColyseusEventArgs new]]);
        }
//        this.OnLeave.Invoke (this, new EventArgs ());
    }
}

-(void)send:(NSObject *)data {
    [self.connection send:@[@(ColyseusProtocol_ROOM_DATA), self.ID, data]];
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
    switch (code) {
        case ColyseusProtocol_JOIN_ROOM: {
            self.sessionID = [message safeObjectAtIndex:1];
            for(ColyseusEventHandler h in self.onJoin) {
                h(@[self, [ColyseusEventArgs new]]);
            }
        } break;
        case ColyseusProtocol_JOIN_ERROR: {
            for(ColyseusEventHandler h in self.onError) {
                h(@[
                    self,
                    [ColyseusErrorEventArgs errorEventWithMessage:[message safeObjectAtIndex:1]]
                    ]
                  );
            }
        }break;
        case ColyseusProtocol_LEAVE_ROOM: {
            [self leave];
        }break;
        case ColyseusProtocol_ROOM_STATE: {
            //This is a message that has been sent from messagepack; therefore it must be already encoded.. probably a form of string
            NSData *encodedState = [message safeObjectAtIndex:1];
            if([encodedState isKindOfClass:[NSData class]]) {
                NSLog(@"ROOM_STATE is NSData!");
            }
            else if([encodedState isKindOfClass:[NSString class]]) {
                NSLog(@"ROOM_STATE is NSString!");
            }
            // TODO:
            // https://github.com/deniszykov/msgpack-unity3d/issues/8
            
            // var remoteCurrentTime = (double) message [2];
            // var remoteElapsedTime = (int) message [3];
            
            // this.SetState (state, remoteCurrentTime, remoteElapsedTime);
            [self setState:encodedState remoteCurrentTime:0 remoteElapsedTime:0];
        }break;
        case ColyseusProtocol_ROOM_STATE_PATCH: {
            //This is a message that has been sent from messagepack; therefore it must be already encoded.. probably a form of string
            //var data = (List<object>) message [1];
            NSData *data = [message safeObjectAtIndex:1];
            NSLog(@"ROOM_STATE_PATCH Data is of class %@", [[data class] description]);
            //TODO: Figure out what to do with this... Or if I'm even right
//            byte[] patches = new byte[data.Count];
//            uint i = 0;
//            foreach (var b in data) {
//                patches [i] = Convert.ToByte(b);
//                i++;
//            }
//
//            this.Patch (patches);
            [self patch:data];
        }break;
        case ColyseusProtocol_ROOM_DATA: {
            if ([self.onMessage count]) {
                for(ColyseusEventHandler h in self.onMessage) {
                    h(@[self, [ColyseusMessageEventArgs messageEventWithMessage:message[1]]]);
                }
            }
        }break;
        default:
            break;
    }
}



-(void)patch:(NSData *)delta {
    char *buffer = (char *)malloc(_previousState.length + delta.length);
    int newStateSize = delta_apply([_previousState bytes], (int)_previousState.length, [delta bytes], (int)delta.length, buffer);
//    _previousState = Fossil.Delta.Apply (this._previousState, delta);
    NSData *newStateData = [NSData dataWithBytes:buffer length:newStateSize];
    free(buffer);
    
    NSDictionary *newState = [newStateData mp_dict:nil];//MsgPack.Deserialize<IndexedDictionary<string, object>> (new MemoryStream(this._previousState));
    
//    this.Set(newState);
    [self set:[IndexedDictionary dictionaryWithDictionary:newState]];
    
    for(ColyseusEventHandler h in self.onStateChange) {
        h(@[self, [ColyseusRoomUpdateEventArgs roomUpdateEventWithState:self.state isFirstState:NO]]);
    }
//    if (this.OnStateChange)
//        this.OnStateChange.Invoke(this, new RoomUpdateEventArgs(this.state));

}
@end


@implementation ColyseusRoomAvailable
@end
