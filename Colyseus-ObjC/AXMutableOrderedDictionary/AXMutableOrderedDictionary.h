#import <Foundation/Foundation.h>
@class AXMutableOrderedDictionary;

typedef AXMutableOrderedDictionary IndexedDictionary;

@class AXMutableOrderedDictionaryEnumerator;

// TODO: Is this class KVO compliant?
@interface AXMutableOrderedDictionary<KeyType, ObjectType> : NSMutableDictionary<KeyType, ObjectType> <NSMutableCopying> {
@private
    NSMutableArray * _keys;
    NSMutableDictionary * _dict;
}

+ (id)new;
+ (id)newOrderedDictionaryWithCapacity:(NSUInteger)initialCapacity;
+ (id)newOrderedDictionaryWithOrderedDictionary:(AXMutableOrderedDictionary *)otherDictionary;
+ (id)newOrderedDictionaryWithObjects:(NSArray *)objects forKeys:(NSArray *)keys;

- (id)initWithCapacity:(NSUInteger)initialCapacity;
- (id)initWithOrderedDictionary:(AXMutableOrderedDictionary *)otherDictionary;
- (id)initWithObjects:(NSArray *)objects forKeys:(NSArray *)keys;

- (NSDictionary *)dictionaryRepresentation;
- (NSArray *)arrayRepresentation;
- (NSArray *)keys;

- (id)keyForObject:(id)object;
- (id)keyForObjectAtIndex:(NSUInteger)index;
- (NSUInteger)indexOfObject:(id)object;
- (NSUInteger)indexOfObjectWithKey:(id)aKey;

- (id)objectForKey:(id)aKey;
- (id)objectAtIndex:(NSUInteger)index;
- (id)lastObject;

- (void)addObject:(id)object withKey:(id)aKey;
- (void)addObjects:(NSArray *)objects withKeys:(NSArray *)keys;
- (void)insertObject:(id)object withKey:(id)aKey atIndex:(NSUInteger)index;
- (void)insertObject:(id)object withKey:(id)aKey afterObject:(id)anotherObject;
- (void)insertObject:(id)object withKey:(id)aKey beforeObject:(id)anotherObject;
- (void)insertObject:(id)object withKey:(id)aKey afterObjectWithKey:(id)anotherKey;
- (void)insertObject:(id)object withKey:(id)aKey beforeObjectWithKey:(id)anotherKey;

- (void)setObject:(id)object forKey:(id)aKey;
- (void)setObject:(id)object atIndex:(NSUInteger)index;

- (void)removeObject:(id)object;
- (void)removeObjectForKey:(id)aKey;
- (void)removeObjectsForKeys:(NSArray *)keys;
- (void)removeObjectAtIndex:(NSUInteger)index;
- (void)removeObjectsAtIndexes:(NSArray *)indexes;
- (void)removeAllObjects;
- (void)removeLastObject;

- (NSUInteger)count;
- (BOOL)isEqualToOrderedDictionary:(AXMutableOrderedDictionary *)dictionary;

- (void)exchangeObjectAtIndex:(NSUInteger)fromIndex withObjectAtIndex:(NSUInteger)toIndex;

- (NSEnumerator *)keyEnumerator;
- (NSEnumerator *)reverseKeyEnumerator;
- (void)enumerateObjectsUsingBlock:(void (^)(id key, id obj, BOOL * stop))block;
- (void)enumerateKeysAndObjectsUsingBlock:(void (^)(id key, id obj, NSUInteger idx, BOOL * stop))block;

// NSMutableCopying
// - (id)mutableCopyWithZone:(NSZone *)zone;
// - (id)mutableCopy;

@end
