//
//  ColyseusStateContainer.m
//  Colyseus-ObjC
//
//  Created by Switt Kongdachalert on 13/5/18.
//  Copyright © 2018 Switt's Software. All rights reserved.
//

#import "ColyseusStateContainer.h"
#import "ColyseusCompare.h"


@interface ColyseusStateContainer () {
    NSMutableDictionary <NSString *, NSRegularExpression *>*matcherPlaceholders;
}
@property (retain) NSMutableArray <PatchListener *>*listeners;
@property (retain) FallbackPatchListener *defaultListener;
@end
@implementation ColyseusStateContainer
-(id)initWithState:(IndexedDictionary<NSString *,NSObject *> *)state {
    if(self = [super init]) {
        matcherPlaceholders =
        [@{
          @":id" :
              [NSRegularExpression regularExpressionWithPattern:@"^([a-zA-Z0-9\\-_]+)$" options:0 error:nil],
          @":number" :
              [NSRegularExpression regularExpressionWithPattern:@"^([0-9]+)$" options:0 error:nil],
          @":string" : [NSRegularExpression regularExpressionWithPattern:@"^(\\w+)$"options:0 error:nil],
          @":axis" : [NSRegularExpression regularExpressionWithPattern:@"^([xyz])$"options:0 error:nil],
          @":*" : [NSRegularExpression regularExpressionWithPattern:@"(.*)"options:0 error:nil]
          } mutableCopy];
        
        self.state = state;
        [self reset];
    }
    return self;
}

-(NSArray <ColyseusPatchObject *>*)set:(IndexedDictionary <NSString *, NSObject *>*)newData {
    NSArray <ColyseusPatchObject *>*patches =
    [ColyseusCompare getPatchListWithTree1:self.state tree2:newData];
//    var patches = Compare.GetPatchList(this.state, newData);
    
    [self checkPatches:patches];
    self.state = newData;
//    this.CheckPatches(patches);
//    this.state = newData;
    
    return patches;
}

-(void)registerPlaceholder:(NSString *)placeholder matcher:(NSRegularExpression *)matcher {
    matcherPlaceholders[placeholder] = matcher;
}

-(FallbackPatchListener *)listen:(ColyseusAction)callback {
    FallbackPatchListener *listener = [FallbackPatchListener new];
    listener.callback = callback;
    listener.rules = @[[NSRegularExpression new]];
    self.defaultListener = listener;
    
    return listener;
}

-(PatchListener *)listen:(NSString *)segments callback:(ColyseusAction /*Action<DataChange>*/)callback
{
    NSArray <NSString *>*rawRules = [segments componentsSeparatedByString:@"/"];
    NSArray <NSRegularExpression *>*regexpRules = [self parseRegexRules:rawRules];
    PatchListener *listener = [PatchListener new];
    listener.callback = callback;
    listener.rules = regexpRules;
    listener.rawRules = rawRules;
    [self.listeners addObject:listener];
    return listener;
}
-(void)removeListener:(PatchListener *)listener {
    [self.listeners removeObject:listener];
}
-(void)removeAllListeners {
    [self reset];
}

-(NSArray <NSRegularExpression *>*)parseRegexRules:(NSArray <NSString *>*)rules
{
    NSMutableArray <NSRegularExpression *>*regexpRules = [NSMutableArray new];
    
    for (int i = 0; i < [rules count]; i++)
    {
        NSString *segment = rules[i];
        if([segment rangeOfString:@":"].location == 0)//if (segment indexof(':') == 0)
        {
            NSRegularExpression *matcher = matcherPlaceholders[segment];
            if (matcher)
            {
                [regexpRules addObject:matcher];
            }
            else {
                [regexpRules addObject:matcherPlaceholders[@":*"]];
            }
        } else {
            NSString *pattern = [NSString stringWithFormat:@"^%@$", segment];
            [regexpRules addObject:[NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil]];
            //regexpRules[i] = new Regex("^" + segment + "$");
        }
    }
    
    return regexpRules;
}

-(void)checkPatches:(NSArray <ColyseusPatchObject *>*)patches {
    NSLog(@"checking patches %@", patches);
    for (long i = [patches count] - 1; i >= 0; i--)
    {
        BOOL matched = NO;
        
        for (int j = 0; j < [self.listeners count]; j++)
        {
            ColyseusListener *listener = self.listeners[j];
            NSDictionary <NSString *, NSString *>* pathVariables = [self getPathVariables:patches[i] listener:listener];
            if (pathVariables != nil)
            {
                ColyseusDataChange *dataChange = [ColyseusDataChange new];
//                var dataChange = new DataChange ();
                dataChange.path = pathVariables;
                dataChange.operation = patches[i].operation;
                dataChange.value = patches[i].value;
                
                listener.callback(@[dataChange]);
//                listener.callback.Invoke (dataChange);
                matched = YES;
            }
        }
        
        // check for fallback listener
//        if (!matched && !object.Equals(this.defaultListener, default(FallbackPatchListener)))
        if(!matched
           && ![self.defaultListener isEqual:[FallbackPatchListener defaultListener]])
        {
            self.defaultListener.callback(@[patches[i]]);
//            this.defaultListener.callback.Invoke (patches [i]);
        }
        
    }
}

-(NSDictionary <NSString *, NSString *>*)getPathVariables:(ColyseusPatchObject *)patch
                                                 listener:(PatchListener *)listener
{
    NSMutableDictionary <NSString *, NSString *>*result = [NSMutableDictionary new];
//    var result = new Dictionary<string, string> ();
    
    // skip if rules count differ from patch
    if ([patch.path count] != [listener.rules count]) {
        return nil;
    }
    
    for (int i = 0; i < [listener.rules count]; i++) {
        NSString *stringToCheck = patch.path[i];
        NSArray<NSTextCheckingResult *>*matches = [listener.rules[i] matchesInString:stringToCheck options:0 range:NSMakeRange(0, stringToCheck.length)];
//        var matches = listener.rules[i].Matches(patch.path[i]);
        
        if ([matches count] == 0 || [matches count] > 2) {
            return nil;
        } else if ([listener.rawRules[i] characterAtIndex:0] == ':') {
            NSString *matchedString = [stringToCheck substringWithRange:matches[0].range];
            [result setObject:matchedString forKey:[listener.rawRules[i] substringFromIndex:1]];
//            result.Add ( listener.rawRules[i].Substring(1), matches[0].ToString() );
        }
    }
    
    return result;
}

-(void)reset {
    self.listeners = [NSMutableArray new];
    self.defaultListener = [FallbackPatchListener defaultListener];
}


@end



@implementation ColyseusDataChange
@end

@implementation ColyseusListener
ColyseusListener *sharedDefaultListener = nil;
+(ColyseusListener *)defaultListener {
    if(!sharedDefaultListener) {
        sharedDefaultListener = [ColyseusListener new];
    }
    return sharedDefaultListener;
}
@end
