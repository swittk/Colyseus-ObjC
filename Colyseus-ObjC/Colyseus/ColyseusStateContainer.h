//
//  ColyseusStateContainer.h
//  Colyseus-ObjC
//
//  Created by Switt Kongdachalert on 13/5/18.
//  Copyright © 2018 Switt's Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ColyseusObjCCommons.h"
@class ColyseusListener;
@class ColyseusDataChange;
@class ColyseusPatchObject;

typedef ColyseusListener PatchListener; //should accept ColyseusDataChange as argument
typedef ColyseusListener FallbackPatchListener; //should accept ColyseusPatchObject as argument

@class ColyseusDataChange;
@class ColyseusListener;
@class ColyseusPatchObject;

@interface ColyseusStateContainer : NSObject
@property (retain) IndexedDictionary <NSString *, NSObject *>*state;
-(id)initWithState:(IndexedDictionary <NSString *, NSObject *>*)state;
-(NSArray <ColyseusPatchObject *>*)set:(IndexedDictionary <NSString *, NSObject *>*)newData;
-(void)registerPlaceholder:(NSString *)placeholder matcher:(NSRegularExpression *)matcher;

-(FallbackPatchListener *)listen:(ColyseusAction)callback;

/**
 Listens for changes to the state
 
 @param segments : The regex to match for the segment
 @param callback : Guaranteed array of length [1] for the callback, the object being a ColyseusDataChange object (Just cast (ColyseusDataChange *)(array[0])).
 */
-(PatchListener *)listen:(NSString *)segments
                callback:(ColyseusAction /*Action<DataChange>*/)callback;

-(void)removeListener:(PatchListener *)listener;
-(void)removeAllListeners;
@end



@interface ColyseusDataChange : NSObject
@property (retain) NSDictionary <NSString *, NSString *>*path;
@property (retain) NSString *operation; // : "add" | "remove" | "replace";
@property (retain) NSObject *value;
@end

@interface ColyseusListener : NSObject
@property (copy) ColyseusEventHandler callback;
@property (retain) NSArray <NSRegularExpression *>*rules;
@property (retain) NSArray <NSString *>*rawRules;
+(ColyseusListener *)defaultListener;
@end


