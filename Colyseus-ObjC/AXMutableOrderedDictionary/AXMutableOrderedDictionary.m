#import "AXMutableOrderedDictionary.h"

#define REMOVE_DUPES(keyList, aKey) if ([keyList containsObject:aKey]) { \
    [_keys removeObject:aKey]; \
}

// via [1] http://cocoawithlove.com/2008/12/ordereddictionary-subclassing-cocoa.html
NSString *DescriptionForObject(NSObject *object, id locale, NSUInteger indent)
{
	NSString *objectString;
	if ([object isKindOfClass:[NSString class]])
	{
		objectString = (NSString *)object;
	}
	else if ([object respondsToSelector:@selector(descriptionWithLocale:indent:)])
	{
		objectString = [(NSDictionary *)object descriptionWithLocale:locale indent:indent];
	}
	else if ([object respondsToSelector:@selector(descriptionWithLocale:)])
	{
		objectString = [(NSSet *)object descriptionWithLocale:locale];
	}
	else
	{
		objectString = [object description];
	}
	return objectString;
}

@interface AXMutableOrderedDictionary ()
@property (nonatomic, retain) NSMutableArray * _keys;
@property (nonatomic, retain) NSMutableDictionary * _dict;
@end

// TODO: Check standard classes for better assert error strings
@implementation AXMutableOrderedDictionary

@synthesize _keys;
@synthesize _dict;

+ (id)new
{
    return [[self alloc] init];
}

+ (id)newOrderedDictionaryWithCapacity:(NSUInteger)initialCapacity
{
    return [[self alloc] initWithCapacity:initialCapacity];
}

+ (id)newOrderedDictionaryWithOrderedDictionary:(AXMutableOrderedDictionary *)otherDictionary
{
    return [[self alloc] initWithOrderedDictionary:otherDictionary];
}

+ (id)newOrderedDictionaryWithObjects:(NSArray *)objects forKeys:(NSArray *)keys
{
    return [[self alloc] initWithObjects:objects forKeys:keys];
}

- (id)init
{
    if ((self = [super init])) {
        _keys = [[NSMutableArray alloc] init];
        _dict = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}

- (id)initWithCapacity:(NSUInteger)initialCapacity
{
    if ((self = [super init])) {
        _keys = [[NSMutableArray alloc] initWithCapacity:initialCapacity];
        _dict = [[NSMutableDictionary alloc] initWithCapacity:initialCapacity];
    }
    
    return self;
}

- (id)initWithOrderedDictionary:(AXMutableOrderedDictionary *)otherDictionary
{
    if ((self = [super init])) {
        _keys = [otherDictionary._keys mutableCopy];
        _dict = [otherDictionary._dict mutableCopy];
    }
    
    return self;
}

- (id)initWithObjects:(NSArray *)objects forKeys:(NSArray *)keys
{
    NSAssert([objects count] == [keys count], @"Cannot initialize with different number of keys and objects");
    
    if ((self = [super init])) {
        _keys = [keys mutableCopy];
        _dict = [[NSMutableDictionary alloc] initWithObjects:objects forKeys:keys];
    }
    
    return self;
}

- (void)dealloc
{
//    [_keys release];
//    [_dict release];
//
//    [super dealloc];
}

#pragma mark - Alternative representations

- (NSDictionary *)dictionaryRepresentation
{
    return [NSDictionary dictionaryWithDictionary:_dict];
}

- (NSArray *)arrayRepresentation
{
    return [_dict allValues];
}

- (NSArray *)keys
{
    return [NSArray arrayWithArray:_keys];
}

#pragma mark - Getting keys and indexes

- (id)keyForObject:(id)object
{
    __block id foundKey = nil;
    [_dict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL * stop) {
        if ([object isEqual:obj]) {
            foundKey = key;
            *stop = YES;
        }
    }];
    
    return foundKey;
}

- (id)keyForObjectAtIndex:(NSUInteger)index
{
    return [_keys objectAtIndex:index];
}

- (NSUInteger)indexOfObject:(id)object
{
    return [_keys indexOfObject:[self keyForObject:object]];
}

- (NSUInteger)indexOfObjectWithKey:(id)aKey
{
    return [_keys indexOfObject:aKey];
}

#pragma mark - Getting objects

- (id)objectForKey:(id)aKey
{
    return [_dict objectForKey:aKey];
}

- (id)objectAtIndex:(NSUInteger)index
{
    return [_dict objectForKey:[_keys objectAtIndex:index]];
}

- (id)lastObject
{
    return [_dict objectForKey:[_keys lastObject]];
}

#pragma mark - Adding objects

- (void)addObject:(id)object withKey:(id)aKey
{
    REMOVE_DUPES(_keys, aKey);
    
    [_keys addObject:aKey];
    [_dict setObject:object forKey:aKey];
}

- (void)addObjects:(NSArray *)objects withKeys:(NSArray *)keys
{
    NSAssert([objects count] == [keys count], @"Cannot add objects if all arrays are not of equal length.");
    
    NSUInteger index;
    for (index = 0; index < [objects count]; index++) {
        [self addObject:[objects objectAtIndex:index] withKey:[keys objectAtIndex:index]];
    }
}

- (void)insertObject:(id)object withKey:(id)aKey atIndex:(NSUInteger)index
{
    REMOVE_DUPES(_keys, aKey);
    
    [_keys insertObject:aKey atIndex:index];
    [_dict setObject:object forKey:aKey];
}

- (void)insertObject:(id)object withKey:(id)aKey afterObject:(id)anotherObject
{
    NSUInteger index = [self indexOfObject:anotherObject];
    if (index != NSNotFound) {
        [self insertObject:object withKey:aKey atIndex:index+1];
    }
}

- (void)insertObject:(id)object withKey:(id)aKey beforeObject:(id)anotherObject
{
    NSUInteger index = [self indexOfObject:anotherObject];
    if (index != NSNotFound) {
        [self insertObject:object withKey:aKey atIndex:index];
    }
}

- (void)insertObject:(id)object withKey:(id)aKey afterObjectWithKey:(id)anotherKey
{
    NSUInteger index = [_keys indexOfObject:anotherKey];
    if (index != NSNotFound) {
        [self insertObject:object withKey:aKey atIndex:index+1];
    }
}

- (void)insertObject:(id)object withKey:(id)aKey beforeObjectWithKey:(id)anotherKey
{
    NSUInteger index = [_keys indexOfObject:anotherKey];
    if (index != NSNotFound) {
        [self insertObject:object withKey:aKey atIndex:index];
    }
}

#pragma mark - Setting objects

- (void)setObject:(id)object forKey:(id)aKey
{
    [_dict setObject:object forKey:aKey];
}

- (void)setObject:(id)object atIndex:(NSUInteger)index
{
    [self setObject:object forKey:[_keys objectAtIndex:index]];
}

- (void)setDictionary:(AXMutableOrderedDictionary *)dictionary
{
//    [_keys release];
    _keys = dictionary._keys;
//    [_dict release];
    _dict = dictionary._dict;
}

#pragma mark - Removing objects

- (void)removeObject:(id)object
{
    NSString * aKey = [self keyForObject:object];
    [_keys removeObject:aKey];
    [_dict removeObjectForKey:aKey];
}

- (void)removeObjectForKey:(id)aKey
{
    [_keys removeObject:aKey];
    [_dict removeObjectForKey:aKey];
}

- (void)removeObjectsForKeys:(NSArray *)keys
{
    for (id aKey in keys) {
        [self removeObjectForKey:aKey];
    }
}

- (void)removeObjectAtIndex:(NSUInteger)index
{
    NSString * aKey = [_keys objectAtIndex:index];
    [_dict removeObjectForKey:aKey];
    [_keys removeObjectAtIndex:index];
}

- (void)removeObjectsAtIndexes:(NSArray *)indexes
{
    for (NSNumber * index in indexes) {
        [self removeObjectAtIndex:[index unsignedIntegerValue]];
    }
}

- (void)removeAllObjects
{
    [_keys removeAllObjects];
    [_dict removeAllObjects];
}

- (void)removeLastObject
{
    NSString * aKey = [_keys lastObject];
    [_dict removeObjectForKey:aKey];
    [_keys removeLastObject];
}

#pragma mark - Structure info

- (NSUInteger)count
{
    NSAssert([_keys count] == [_dict count], @"Internal data stores are out of sync. Were the collections mutated direclty?");
    return [_keys count];
}

- (NSString *)description
{
    NSMutableString * description = [NSMutableString new];
    [description appendFormat:@"%@\t{\n", [super description]];
    
    [self enumerateKeysAndObjectsUsingBlock:^(id key, id obj, NSUInteger idx, BOOL * stop) {
        [description appendFormat:@"\t%@ = %@;\n", key, obj];
    }];
    
    [description appendFormat:@"}"];
    
    return [description copy];
}

// via [1]
- (NSString *)descriptionWithLocale:(id)locale indent:(NSUInteger)level
{
	NSMutableString *indentString = [NSMutableString string];
	NSUInteger i, count = level;
	for (i = 0; i < count; i++)
	{
		[indentString appendFormat:@"    "];
	}
	
	NSMutableString *description = [NSMutableString string];
	[description appendFormat:@"%@{\n", indentString];
	for (NSObject *key in self)
	{
		[description appendFormat:@"%@    %@ = %@;\n",
         indentString,
         DescriptionForObject(key, locale, level),
         DescriptionForObject([self objectForKey:key], locale, level)];
	}
	[description appendFormat:@"%@}\n", indentString];
	return description;
}

- (NSUInteger)hash
{
    return [_keys hash] + [_dict hash];
}

- (BOOL)isEqual:(id)object
{
    if (object == self) {
        return YES; // Early out
    }
    
    if ([object class] == [self class]) {
        return [self isEqualToOrderedDictionary:(AXMutableOrderedDictionary *)object];
    }
    
    return NO;
}

- (BOOL)isEqualToOrderedDictionary:(AXMutableOrderedDictionary *)dictionary
{
    if (dictionary == self) {
        return YES; // Early out
    }
    
    return [_keys isEqualToArray:dictionary._keys] && [_dict isEqualToDictionary:dictionary._dict];
}

#pragma mark - Reordering and sorting

- (void)exchangeObjectAtIndex:(NSUInteger)fromIndex withObjectAtIndex:(NSUInteger)toIndex
{
    [_keys exchangeObjectAtIndex:fromIndex withObjectAtIndex:toIndex];
}

- (void)sortKeysUsingDescriptors:(NSArray *)sortDescriptors
{
    [_keys sortUsingDescriptors:sortDescriptors];
}

#pragma mark - Enumeration

- (NSEnumerator *)keyEnumerator
{
    return [_keys objectEnumerator];
}

- (NSEnumerator *)reverseKeyEnumerator
{
	return [_keys reverseObjectEnumerator];
}

- (void)enumerateObjectsUsingBlock:(void (^)(id key, id obj, BOOL * stop))block
{
    [_dict enumerateKeysAndObjectsUsingBlock:block];
}

- (void)enumerateKeysAndObjectsUsingBlock:(void (^)(id key, id obj, NSUInteger idx, BOOL * stop))block
{
    [_keys enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL * stop) {
        block(obj, [_dict objectForKey:obj], idx, stop);
    }];
}

#pragma mark - Copying

- (id)mutableCopyWithZone:(NSZone *)zone
{
    return [[[self class] allocWithZone:zone] initWithOrderedDictionary:self];
}

- (id)copy
{
    return [self mutableCopy];
}

- (id)mutableCopy
{
    return [[[self class] alloc] initWithOrderedDictionary:self];
}

@end
