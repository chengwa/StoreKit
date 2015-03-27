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
@end

@implementation NSNumber (PK)
- (NSString *)getInKey {
    return [self description];
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

@end
