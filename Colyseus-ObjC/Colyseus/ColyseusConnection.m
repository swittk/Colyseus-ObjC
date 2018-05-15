//
//  ColyseusConnection.m
//  Colyseus-ObjC
//
//  Created by Switt Kongdachalert on 13/5/18.
//  Copyright © 2018 Switt's Software. All rights reserved.
//

#import "ColyseusConnection.h"
#import "MPMessagePack.h"
#import "ColyseusMessageEventArgs.h"

@implementation ColyseusConnection {
    NSMutableArray <NSData *>*enqueuedCalls;
}
-(id)initWithURL:(NSURL *)url {
    if(self = [super init]) {
        enqueuedCalls = [NSMutableArray new];
        _onOpen = [NSMutableArray new];
        _onClose = [NSMutableArray new];
        _onMessage = [NSMutableArray new];
        _onError = [NSMutableArray new];
        
        _url = url;
        _isOpen = NO;
        socket = [PSWebSocket clientSocketWithRequest:[NSURLRequest requestWithURL:url]];
        socket.delegate = self;
    }
    return self;
}

-(void)connect {
    if(socket.readyState != PSWebSocketReadyStateOpen) {
        [socket open];
    }
}
-(void)close {
    [socket close];
}
- (void)webSocketDidOpen:(PSWebSocket *)webSocket {
    NSLog(@"webSocketDidOpen");
    _isOpen = YES;
    if ([enqueuedCalls count] > 0) {
        do {
            [self send:[enqueuedCalls firstObject]];
            [enqueuedCalls removeObjectAtIndex:0];
        } while ([enqueuedCalls count]);
    }
    for(void (^e)(ColyseusConnection *, ColyseusEventArgs *) in _onOpen) {
        e(self, [ColyseusEventArgs event]);
    }
}
- (void)webSocket:(PSWebSocket *)webSocket didFailWithError:(NSError *)error {
    for(void (^e)(ColyseusConnection *, ColyseusErrorEventArgs *) in _onError) {
        e(self, [ColyseusErrorEventArgs errorEventWithMessage:[error description]]);
    }
//    NSLog(@"didFailWithError %@", [error description]);
}
- (void)webSocket:(PSWebSocket *)webSocket didReceiveMessage:(id)message {
    for(void (^e)(ColyseusConnection *, ColyseusMessageEventArgs *) in _onMessage) {
        e(self, [ColyseusMessageEventArgs messageEventWithMessage:message]);
    }
//    NSLog(@"didReceiveMessage %@", message);
}
- (void)webSocket:(PSWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
    _isOpen = NO;
    for(void (^e)(ColyseusConnection *, ColyseusErrorEventArgs *) in _onClose) {
        e(self, [ColyseusErrorEventArgs errorEventWithMessage:reason]);
    }
//    NSLog(@"Socket closed with code %d, reason %@, wasClean %d", code, reason, wasClean);
}


-(void)send:(id)data {
    NSData *packedData;
    if(![data isKindOfClass:[NSData class]]) {
        packedData = [data mp_messagePack];
    }
    else {
        packedData = data;
    }
    
    if (!self.isOpen) {
        NSLog(@"I am not open yet");
        [enqueuedCalls addObject:packedData];
    } else {
        NSLog(@"sending data %@, packed %@ of length %d", data, [[NSString alloc] initWithData:packedData encoding:nil], [packedData length]);
        [socket send:packedData];
    }
}


@end
