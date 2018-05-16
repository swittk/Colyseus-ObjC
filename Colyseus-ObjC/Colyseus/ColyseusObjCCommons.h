//
//  ColyseusObjCCommons.h
//  Colyseus-ObjC
//
//  Created by Switt Kongdachalert on 13/5/18.
//  Copyright © 2018 Switt's Software. All rights reserved.
//

#ifndef ColyseusObjCCommons_h
#define ColyseusObjCCommons_h

typedef NSMutableDictionary IndexedDictionary;

typedef void(^ColyseusEventHandler)(NSArray *arguments);
typedef ColyseusEventHandler ColyseusAction;

typedef enum
{
    ColyseusProtocol_USER_ID = 1,
    
    //
    // Room-related (10~20)
    //
    
    /// <summary>When JOIN request is accepted.</summary>
    ColyseusProtocol_JOIN_ROOM = 10,
    
    /// <summary>When JOIN request is not accepted.</summary>
    ColyseusProtocol_JOIN_ERROR = 11,
    
    /// <summary>When server explicitly removes <see cref="Client"/> from the <see cref="Room"/></summary>
    ColyseusProtocol_LEAVE_ROOM = 12,
    
    /// <summary>When server sends data to a particular <see cref="Room"/></summary>
    ColyseusProtocol_ROOM_DATA = 13,
    
    /// <summary>When server sends <see cref="Room"/> state to its clients.</summary>
    ColyseusProtocol_ROOM_STATE = 14,
    
    /// <summary>When server sends <see cref="Room"/> state to its clients.</summary>
    ColyseusProtocol_ROOM_STATE_PATCH = 15,
    
    //
    // Matchmaking messages (20~30)
    //
    ColyseusProtocol_ROOM_LIST = 20,
    
    //
    // Generic messages (50~60)
    //
    
    /// <summary>When server doesn't understand a request, it returns <see cref="BAD_REQUEST"/> to the <see cref="Client"/></summary>
    ColyseusProtocol_BAD_REQUEST = 50
    
    // public Protocol (){}
} ColyseusProtocol;


#endif /* ColyseusObjCCommons_h */
