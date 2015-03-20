//
//  RSBucket.m
//  StoreKit
//
//  Created by closure on 3/21/15.
//  Copyright (c) 2015 closure. All rights reserved.
//

#import "RSBucket.h"
#import "RSStorage.h"

@interface RSBucket ()
@property (weak, nonatomic) RSStorage *storage;
@end

@implementation RSBucket
- (instancetype)initWithStorage:(RSStorage *)storage name:(NSString *)name {
    assert(storage);
    assert([name length]);
    if (self = [super init]) {
        _storage = storage;
        _name = name;
        _path = [[storage path] stringByAppendingPathComponent:name];
    }
    return self;
}

- (NSUInteger)hash {
    return [[self path] hash];
}

- (BOOL)isEqual:(id)object {
    return [object isKindOfClass:[self class]] && [_path isEqualToString:[object path]];
}


- (BOOL)setObject:(id<NSCoding>)object forKey:(id<RSPrimaryKey>)aKey {
    __block BOOL s = NO;
    [[self storage] commitStoreRequest:^{
        NSString *path = [[self path] stringByAppendingPathComponent:[aKey getInKey]];
        s = [[NSKeyedArchiver archivedDataWithRootObject:object] writeToFile:path atomically:YES];
    }];
    return s;
}

- (id<NSCoding>)objectForKey:(id<RSPrimaryKey>)key {
    __block id<NSCoding> o = nil;
    [[self storage] commitStoreRequest:^{
        NSString *path = [[self path] stringByAppendingPathComponent:[key getInKey]];
        o = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
    }];
    return o;
}

@end
