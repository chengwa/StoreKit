//
//  RSBucket.m
//  StoreKit
//
//  Created by closure on 3/20/15.
//  Copyright (c) 2015 closure. All rights reserved.
//

#import "RSStorage.h"
#import "RSBucket.h"
#import "RSStoreKit.h"
#import "RSDatabaseConnector.h"

@interface RSStorage ()
@property (assign, nonatomic) RSStoreKit *kit;
@property (strong, nonatomic) NSMutableArray *buckets;
@end

@interface RSStoreKit ()
@property (strong, nonatomic) NSFileManager *fileMgr;
@end

@implementation RSStorage
- (instancetype)initWithStore:(RSStoreKit *)kit name:(NSString *)name {
    assert(kit);
    assert([name length]);
    if (self = [super init]) {
        _kit = kit;
        _name = name;
        _path = [[_kit rootPath] stringByAppendingPathComponent:name];
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
    [[self kit] commitStoreRequest:^{
        NSString *path = [[self path] stringByAppendingPathComponent:[aKey getInKey]];
        s = [[NSKeyedArchiver archivedDataWithRootObject:object] writeToFile:path atomically:YES];
    }];
    return s;
}

- (id<NSCoding>)objectForKey:(id<RSPrimaryKey>)key {
    __block id<NSCoding> o = nil;
    [[self kit] commitStoreRequest:^{
        NSString *path = [[self path] stringByAppendingPathComponent:[key getInKey]];
        o = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
    }];
    return o;
}
@end

@implementation RSStorage (Bucket)
+ (BOOL)_createBucketIfNoExist:(RSStorage *)storage name:(NSString *)name {
    NSFileManager *fileMgr = [[storage kit] fileMgr];
    NSString *path = [[storage path] stringByAppendingPathComponent:name];
    BOOL isDir = NO;
    BOOL success = [fileMgr fileExistsAtPath:path isDirectory:&isDir];
    if (success && isDir) {
        return YES;
    }
    if (!success) {
        NSError *error = nil;
        success = [fileMgr createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error];
        if (success) {
            return YES;
        }
        NSLog(@"%@", [error localizedDescription]);
    }
    return NO;
}

- (RSBucket *)bucket {
    return [self bucketNamed:[[NSUUID UUID] UUIDString]];
}

- (RSBucket *)bucketNamed:(NSString *)name {
    if ([RSStorage _createBucketIfNoExist:self name:name]) {
        return [[RSBucket alloc] initWithStorage:self name:name];
    }
    return nil;
}

- (void)commitStoreRequest:(void (^)())request {
    return [[self kit] commitStoreRequest:request];
}
@end

@implementation RSStorage (DBConnector)

- (RSDatabaseConnector *)connectorNamed:(NSString *)name {
    return [[RSDatabaseConnector alloc] initWithStorage:self name:[name stringByAppendingPathExtension:@"dat"]];
}

@end
