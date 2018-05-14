//
//  ColyseusStateContainer.h
//  Colyseus-ObjC
//
//  Created by Switt Kongdachalert on 13/5/18.
//  Copyright © 2018 Switt's Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ColyseusObjCCommons.h"
#import "AXMutableOrderedDictionary.h"
@class ColyseusListener;
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


