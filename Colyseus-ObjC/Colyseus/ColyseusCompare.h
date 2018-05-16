//
//  ColyseusCompare.h
//  Colyseus-ObjC
//
//  Created by Switt Kongdachalert on 13/5/18.
//  Copyright © 2018 Switt's Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ColyseusObjCCommons.h"

@interface ColyseusPatchObject : NSObject
@property (retain) NSMutableArray <NSString *>*path;
@property (retain) NSString *operation;
@property (retain) NSObject *value;
-(NSString *)description;
@end

@interface ColyseusCompare : NSObject
+(NSArray <ColyseusPatchObject *>*)getPatchListWithTree1:(IndexedDictionary<NSString *, NSObject *>*)tree1 tree2:(IndexedDictionary<NSString *, NSObject *>*)tree2;
+(void)generateWithArrayMirror:(NSArray <NSObject *>*)mirror
                      objArray:(NSArray <NSObject *>*)objArray
                       patches:(NSMutableArray <ColyseusPatchObject *>*)patches
                          path:(NSArray <NSString *>*)path;

+(void)generateWithDictionaryMirror:(IndexedDictionary<NSString *,NSObject *> *)mirror
                            objDict:(IndexedDictionary<NSString *,NSObject *> *)objDict
                            patches:(NSMutableArray <ColyseusPatchObject *> *)patches
                               path:(NSArray<NSString *> *)path;
@end
