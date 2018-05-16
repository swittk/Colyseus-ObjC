# Colyseus-ObjC
Implementation of Colyseus client using Objective C.


**This is still a work in progress, it seems to work, but more testing needs to be done**
*Please report any bugs, and pull requests are very welcome*


## Why?

Because I stumbled upon [Colyseus](http://colyseus.io) and, after fiddling with it in Unity for a while, I found that it was a library that provides one of the easiest ways to set up state synchronization and messaging, two important things for multiplayer games.

But I think normal apps should be able to use Colyseus too, and since I code mainly on iOS, and love Objective-C dearly. I decided why not try and implement a client in Objective-C?

This code is mainly based on Colyseus's Unity C# client implementation and partly on the Cocos2D C++ client (only the fossilize.h delta_apply function).


## Installation
Copy the whole Colyseus-ObjC folder into your project, import headers as you need. Main ones would be ColyseusRoom.h, ColyseusClient.h, and ColyseusMessageEventArgs.h


## Usage

### ColyseusClient

#### -(id)initWithEndpoint:(NSString *)endPoint ID:(NSString *)ID;
Creates a client with a connection to the specified endpoint.
* endPoint : Usually, this is the url to your server
* ID : This parameter is useful for rejoining rooms after a disconnection. If this parameter is specified, the specified ID is used for subsequent connections.

#### -(void)connect;
Starts the client connection

#### -(void)close;
Closes the client connection

#### -(ColyseusRoom *)join:(NSString *)roomName options:(nullable NSDictionary <NSString \*, id>\*)options;
Joins the room of the specified name using the provided options


### ColyseusRoom

#### -(id)initWithName:(NSString *)name options:(NSDictionary <NSString \*, id>\*)options;

#### -(void)connect;

#### -(void)leave;

#### -(void)send:(NSObject \*)data;
data : The data to send.



### Example Usage
```
ColyseusClient *client = [[ColyseusClient alloc] initWithEndpoint:@"ws://localhost:4000" ID:nil];

__block MyClientClass *weakself = self;
[client.onOpen addObject:^void(ColyseusClient *c, ColyseusEventArgs *e) {
    NSLog(@"Connection open");
    
    //Once the connection is open, join a room
    ColyseusRoom *room = [client join:@"mine" options:@{@"name" : @"MyAwesomeName"}];
    
    __block ColyseusRoom *weakroom = room;
    [room.onJoin addObject:^void(ColyseusRoom *r, ColyseusMessageEventArgs *m) {
        NSLog(@"Joined with SessionID: %@",[m message]);
        [weakroom connect];
        [weakroom send:@{@"type":@"nameset", @"name" : @"switt", @"ts" : @([[NSDate date] timeIntervalSince1970])}];
    }];
    [room.onMessage addObject:^void(ColyseusRoom *r, ColyseusMessageEventArgs *m) {
        NSLog(@"Room: Message received %@",[m message]);
    }];
    [room.onStateChange addObject:^void(ColyseusRoom *ro, ColyseusRoomUpdateEventArgs *r) {
        NSLog(@"State Change; IsFirst %d, Data : %@", r.isFirstState, [r state]);
    }];
    [room.onError addObject:^void(ColyseusRoom *r, ColyseusErrorEventArgs *e) {
        NSLog(@"Error; %@",[e message]);
    }];
    
    // Listen for changes at players.playerName.position.(x or y or z)
    // Here, ":string" will capture playerName, and ":axis" will capture the axis.
    // The @path property in ColyseusDataChange will store strings corresponding to our capture blocks
    [room listen:@"players/:string/position/:axis" callback:^(NSArray *arguments) {
        ColyseusDataChange *change = [arguments firstObject];
        NSLog(@"Axis:%@ changed for player:%@, operation:%@, value:%@", change.path[@"axis"], change.path[@"string"], change.operation, change.value);
    }];
    [room listen:@"players/:*" callback:^(NSArray *arguments) {
        ColyseusDataChange *change = [arguments firstObject];
        NSLog(@"Mutated players, operation:%@, player info is %@", change.operation, change.value);
        [players setObject:change.value forKey:change.path[@"*"]];
    }];
}];
[client connect];
```




## TODOs
* Proper header exports (I am still pretty ignorant about framework header exports in XCode after years)
* Test some more, cleanup more code
