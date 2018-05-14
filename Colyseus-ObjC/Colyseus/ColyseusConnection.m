//
//  ColyseusConnection.m
//  Colyseus-ObjC
//
//  Created by Switt Kongdachalert on 13/5/18.
//  Copyright © 2018 Switt's Software. All rights reserved.
//

#import "ColyseusConnection.h"
#import "MPMessagePack.h"

@implementation ColyseusConnection {
    NSMutableArray <NSData *>*enqueuedCalls;
}
-(id)initWithURL:(NSURL *)url {
    if(self = [super init]) {
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
    [socket open];
}
-(void)close {
    [socket close];
}
- (void)webSocketDidOpen:(PSWebSocket *)webSocket {
    _isOpen = YES;
    if ([enqueuedCalls count] > 0) {
        do {
            [self send:[enqueuedCalls firstObject]];
            [enqueuedCalls removeObjectAtIndex:0];
        } while ([enqueuedCalls count]);
    }
    for(ColyseusEventHandler e in _onOpen) {
        e(@[self]);
    }
}
- (void)webSocket:(PSWebSocket *)webSocket didFailWithError:(NSError *)error {
    for(ColyseusEventHandler e in _onError) {
        e(@[self, error]);
    }
}
- (void)webSocket:(PSWebSocket *)webSocket didReceiveMessage:(id)message {
    for(ColyseusEventHandler e in _onMessage) {
        e(@[self, message]);
    }
}
- (void)webSocket:(PSWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
    _isOpen = NO;
    for(ColyseusEventHandler e in _onClose) {
        e(@[self, @(code), reason, @(wasClean)]);
    }
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
        [enqueuedCalls addObject:packedData];
    } else {
        [socket send:packedData];
    }
}


@end
