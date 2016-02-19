//
//  RSPrimaryKey.m
//  StoreKit
//
//  Created by closure on 3/20/15.
//  Copyright (c) 2015 closure. All rights reserved.
//

#import "RSPrimaryKey.h"

@implementation NSString (PK)
- (NSString *)getInKey {
    return self;
}

- (RSIDType)numbericIDKey {
    return [[self getInKey] longLongValue];
}
@end

@implementation NSNumber (PK)
- (NSString *)getInKey {
    return [self description];
}

- (RSIDType)numbericIDKey {
    return [self longLongValue];
}
@end

@implementation RSIntPK
- (instancetype)initWithID:(RSIDType)ID {
    if (self = [super init]) {
        _ID = ID;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        _ID = [aDecoder decodeInt64ForKey:@"ID"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeInt64:_ID forKey:@"ID"];
}

- (NSUInteger)hash {
    return _ID >> 32;
}

- (NSString *)getInKey {
    return [NSString stringWithFormat:@"%lld", _ID];
}

- (RSIDType)numbericIDKey {
    return _ID;
}

- (BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[self class]]) {
        return [((RSIntPK *)object) ID] == _ID;
    }
    return NO;
}
@end

@implementation RSStringPK

- (instancetype)initWithToken:(NSString *)token {
    if (self = [super init]) {
        _token = token;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        _token = [aDecoder decodeObjectForKey:@"token"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:_token forKey:@"token"];
}

- (NSUInteger)hash {
    return [_token hash];
}

- (NSString *)getInKey {
    return _token;
}

- (BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[self class]]) {
        return [((RSStringPK *)object) token] == _token;
    }
    return NO;
}

- (RSIDType)numbericIDKey {
    return [_token numbericIDKey];
}

@end

@implementation NSArray (PrimaryIDs)

- (NSString *)ids {
    if (![self count]) {
        return @"";
    }
    NSMutableArray *ids = [[NSMutableArray alloc] initWithCapacity:[self count]];
    for (id <RSPrimaryKey> key in self) {
        if ([key isKindOfClass:[RSIntPK class]]) {
            [ids addObject:@([(RSIntPK *)key ID])];
        } else if ([key isKindOfClass:[NSNumber class]]) {
            [ids addObject:key];
        } else if ([key isKindOfClass:[RSStringPK class]] || [key isKindOfClass:[NSString class]]) {
            [ids addObject:[key getInKey]];
        } else {
            return @"";
        }
    }
    if ([ids count]) {
        NSString *result = @"";
        NSError *error = nil;
        NSData *json = [NSJSONSerialization dataWithJSONObject:ids options:NSJSONWritingPrettyPrinted error:&error];
        if (error) {
            NSLog(@"%@", error);
            return result;
        }
        result = [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding];
        return result;
    }
    return @"";
}

@end

@implementation NSString (RSJSONModel)

- (id)jsonObject {
    return self;
}

@end

@implementation NSNumber (RSJSONModel)

- (id)jsonObject {
    return self;
}

@end

@implementation NSArray (RSJSONModel)

- (id)jsonObject {
    NSMutableArray *jsonObjects = [[NSMutableArray alloc] initWithCapacity:[self count]];
    for (id<RSJSONModel> obj in self) {
        [jsonObjects addObject:[obj jsonObject]];
    }
    return jsonObjects;
}

@end

@implementation NSDictionary (RSJSONModel)

- (id)jsonObject {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithCapacity:[self count]];
    for (id<RSJSONModel> key in self) {
        dict[[key jsonObject]] = [dict[key] jsonObject];
    }
    return dict;
}

@end