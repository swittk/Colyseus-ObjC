//
//  ColyseusCompare.m
//  Colyseus-ObjC
//
//  Created by Switt Kongdachalert on 13/5/18.
//  Copyright © 2018 Switt's Software. All rights reserved.
//

#import "ColyseusCompare.h"

@implementation ColyseusCompare
+(NSArray <ColyseusPatchObject *>*)getPatchListWithTree1:(IndexedDictionary<NSString *, NSObject *>*)tree1 tree2:(IndexedDictionary<NSString *, NSObject *>*)tree2 {
    NSMutableArray <ColyseusPatchObject *>*patches = [NSMutableArray new];
    NSMutableArray <NSString *>*path = [NSMutableArray new];
    
    [self generateWithDictionaryMirror:tree1 objDict:tree2 patches:patches path:path];
    
    return patches;
}
+(void)generateWithArrayMirror:(NSArray <NSObject *>*)mirror
                      objArray:(NSArray <NSObject *>*)objArray
                       patches:(NSMutableArray <ColyseusPatchObject *>*)patches
                          path:(NSArray <NSString *>*)path {
    IndexedDictionary <NSString *, NSObject *>*mirrorDict = [IndexedDictionary new];
    for (int i = 0; i < [mirror count]; i++) {
        [mirrorDict setObject:mirror[i] forKey:@(i).stringValue];
    }
    IndexedDictionary <NSString *, NSObject *>*objDict = [IndexedDictionary new];
    for (int i = 0; i < [objArray count]; i++) {
        [objDict setObject:objArray[i] forKey:@(i).stringValue];
    }
    
    [self generateWithDictionaryMirror:mirrorDict objDict:objDict patches:patches path:path];
}

// Dirty check if obj is different from mirror, generate patches and update mirror
+(void)generateWithDictionaryMirror:(IndexedDictionary<NSString *,NSObject *> *)mirror objDict:(IndexedDictionary<NSString *,NSObject *> *)objDict patches:(NSMutableArray <ColyseusPatchObject *> *)patches path:(NSArray<NSString *> *)path {
    NSArray <NSString *>*newKeys = [objDict allKeys];
    NSArray <NSString *>*oldKeys = [mirror allKeys];
    BOOL deleted = NO;
    
    for (int i = 0; i < [oldKeys count]; i++)
    {
        NSString *key = oldKeys[i];
        if (
            (objDict[key] != nil) &&
            (objDict[key] != [NSNull null]) &&
            !(!objDict[key] && mirror[key] && !([objDict isKindOfClass:[NSArray class]]))
        ) {
            NSObject *oldVal = mirror[key];
            NSObject *newVal = objDict[key];
            
            if (
                oldVal != [NSNull null] && newVal != [NSNull null] &&
                ![oldVal isKindOfClass:[NSNumber class]] && ![oldVal isKindOfClass:[NSString class]] &&
                //!oldVal.GetType ().IsPrimitive && oldVal.GetType () != typeof(string) &&
                ![newVal isKindOfClass:[NSNumber class]] && ![newVal isKindOfClass:[NSString class]] &&
                //!newVal.GetType ().IsPrimitive && newVal.GetType () != typeof(string) &&
                [[newVal class] isEqual:[oldVal class]]
//                Object.ReferenceEquals(oldVal.GetType (), newVal.GetType ())
                )
            {
                NSMutableArray <NSString *>*deeperPath = [path mutableCopy];
//                List<string> deeperPath = new List<string>(path);
                [deeperPath addObject:key];
//                deeperPath.Add((string) key);
                
                if([oldVal isKindOfClass:[IndexedDictionary class]]) {
//                if (oldVal is IndexedDictionary<string, object>) {
                    [self generateWithDictionaryMirror:(IndexedDictionary *)oldVal objDict:(IndexedDictionary *)newVal patches:patches path:deeperPath];
//                    Generate(
//                             (IndexedDictionary<string, object>) oldVal,
//                             (IndexedDictionary<string, object>) newVal,
//                             patches,
//                             deeperPath
//                             );
                } else if ([oldVal isKindOfClass:[NSArray class]]) {
//                } else if (oldVal is List<object>) {
                    [self generateWithArrayMirror:(NSArray *)oldVal objArray:(NSArray *)newVal patches:patches path:deeperPath];
//                    Generate(
//                             ((List<object>) oldVal),
//                             ((List<object>) newVal),
//                             patches,
//                             deeperPath
//                             );
                }
                
            } else {
                if (
                    (oldVal == [NSNull null] && newVal != [NSNull null]) ||
                    ![oldVal isEqual:newVal]
                    )
                {
                    NSMutableArray <NSString *>*replacePath = [NSMutableArray new];
//                    List<string> replacePath = new List<string>(path);
                    [replacePath addObject:key];
//                    replacePath.Add((string) key);
                    
                    ColyseusPatchObject *po = [ColyseusPatchObject new];
                    po.operation = @"replace";
                    po.path = replacePath;
                    po.value = newVal;
                    [patches addObject:po];
                }
            }
        }
        else {
            NSMutableArray <NSString *>*removePath = [NSMutableArray new];
//            List<string> removePath = new List<string>(path);
            [removePath addObject:key];
//            removePath.Add((string) key);
            
            ColyseusPatchObject *po = [ColyseusPatchObject new];
            po.operation = @"remove";
            po.path = removePath;
            
            [patches addObject:po];
//            patches.Add(new PatchObject
//                        {
//                            operation = "remove",
//                            path = removePath.ToArray()
//                        });
            
            deleted = YES; // property has been deleted
        }
    }
    
    if (!deleted && [newKeys count] == [oldKeys count]) {
        return;
    }
    
//    foreach (var key in newKeys)
    for(NSString *key in newKeys)
    {
//        if (!mirror.ContainsKey(key) && obj.ContainsKey(key))
        if(!mirror[key] && objDict[key])
        {
            NSMutableArray <NSString *>*addPath = [path mutableCopy];
//            List<string> addPath = new List<string>(path);
            [addPath addObject:key];
//            addPath.Add((string) key);
            
            NSObject *newVal = objDict[key];
//            var newVal = obj [key];
            
            if (newVal != nil) {
                Class newValType = [newVal class];
//                var newValType = newVal.GetType ();
                
                // compare deeper additions
                if (
                    ![newValType isEqual:[NSNumber class]] && //!newValType.IsPrimitive &&
                    ![newValType isEqual:[NSString class]]//newValType != typeof(string)
                    ) {
//                    if (newVal is IDictionary) {
                    if([newVal isKindOfClass:[IndexedDictionary class]]) {
                        [self generateWithDictionaryMirror:[IndexedDictionary new] objDict:(IndexedDictionary *)newVal patches:patches path:addPath];
//                        Generate(new IndexedDictionary<string, object>(), newVal as IndexedDictionary<string, object>, patches, addPath);
                        
//                    } else if (newVal is IList) {
                    }
                    else if ([newVal isKindOfClass:[NSArray class]]) {
                        [self generateWithArrayMirror:[NSArray new] objArray:(NSArray <NSObject *>*)newVal patches:patches path:addPath];
//                        Generate(new List<object>(), newVal as List<object>, patches, addPath);
                    }
                }
            }
            
            ColyseusPatchObject *po = [ColyseusPatchObject new];
            po.operation = @"add";
            po.path = addPath;
            po.value = newVal;
            [patches addObject:po];
//            patches.Add(new PatchObject
//                        {
//                            operation = "add",
//                            path = addPath.ToArray(),
//                            value = newVal
//                        });
        }
    }
    
}
@end

@implementation ColyseusPatchObject
-(NSString *)description {
    return [NSString stringWithFormat:@"path : %@,operation : %@,value: %@", self.path, self.operation, self.value];
}
@end
