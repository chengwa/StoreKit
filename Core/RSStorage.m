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
@property (assign, nonatomic) id parent;
@property (strong, nonatomic) NSMutableArray *buckets;
@property (strong, nonatomic) dispatch_queue_t ioQueue;
@end

@interface RSStoreKit ()
@property (strong, nonatomic) NSFileManager *fileMgr;
@end

@implementation RSStorage
- (instancetype)initWithStore:(RSStoreKit *)kit name:(NSString *)name {
    assert(kit);
    assert([name length]);
    if (self = [super init]) {
        _parent = kit;
        _name = name;
        _path = [[kit rootPath] stringByAppendingPathComponent:name];
        _ioQueue = dispatch_queue_create([_name UTF8String], DISPATCH_QUEUE_SERIAL);
        _level = 1;
    }
    return self;
}

- (instancetype)initWithStorage:(RSStorage *)storage name:(NSString *)name {
    assert(storage);
    assert([name length]);
    if (self = [super init]) {
        _parent = storage;
        _name = name;
        _path = [[storage path] stringByAppendingPathComponent:name];
        _ioQueue = dispatch_queue_create([_name UTF8String], DISPATCH_QUEUE_SERIAL);
        _level = [storage level] + 1;
    }
    return self;
}

- (NSUInteger)hash {
    return [[self path] hash];
}

- (BOOL)isEqual:(id)object {
    return [object isKindOfClass:[self class]] && [_path isEqualToString:[(RSStorage *)object path]];
}

- (void)setObject:(id<NSCoding>)object forKey:(id<RSPrimaryKey>)aKey {
    dispatch_async(_ioQueue, ^{
        NSString *path = [[self path] stringByAppendingPathComponent:[aKey getInKey]];
        if (![[NSKeyedArchiver archivedDataWithRootObject:object] writeToFile:path atomically:YES]) {
            NSLog(@"%@", @(__FUNCTION__));
        }
    });
}

- (void)objectForKey:(id<RSPrimaryKey>)key withCompletion:(RSBucketQueryCompletedBlock)block {
    dispatch_async(_ioQueue, ^{
        NSString *path = [[self path] stringByAppendingPathComponent:[key getInKey]];
        return block([NSData dataWithContentsOfFile:path], RSBucketCacheTypeDisk);
    });
}

- (id <NSCoding>)objectForKey:(id<RSPrimaryKey>)key {
    __block id <NSCoding> obj = nil;
    dispatch_sync(_ioQueue, ^{
        NSString *path = [[self path] stringByAppendingPathComponent:[key getInKey]];
        obj = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
    });
    return obj;
}

- (RSStoreKit *)kit {
    return _level == 1 ? _parent : [_parent kit];
}
@end

@implementation RSStorage (Storage)

+ (BOOL)_createStorageIfNoExist:(RSStorage *)storage name:(NSString *)name {
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

- (RSStorage *)storage {
    return [self storageNamed:[[NSUUID UUID] UUIDString]];
}

- (RSStorage *)storageNamed:(NSString *)name {
    name = [RSStoreKit nameForKey:name];
    if ([[self class] _createStorageIfNoExist:self name:name]) {
        RSStorage *storage = [[RSStorage alloc] initWithStorage:self name:name];
        
        return storage;
    }
    return nil;
}

- (void)removeStorage:(RSStorage *)storage {
    if ([storage level] != [self level] + 1) {
        return [[storage parent] removeStorage:storage];
    } else {
        dispatch_sync(_ioQueue, ^{
            NSString *str = [storage path];
            NSError *error = nil;
            BOOL success = [[[self kit] fileMgr] removeItemAtPath:str error:&error];
            if (!success) {
                NSLog(@"%@", [error localizedDescription]);
            }
        });
    }
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
            NSURL *url = [NSURL fileURLWithPath:path];
            BOOL success = [url setResourceValue:@(YES) forKey:NSURLIsExcludedFromBackupKey error:&error];
            if (!success || error) {
                NSLog(@"%@", [error localizedDescription]);
            }
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
    return [self bucketNamed:name forClassImpl:[RSBucket class]];
}

- (RSBucket *)bucketNamed:(NSString *)name forClassImpl:(id)class {
    if ([RSStorage _createBucketIfNoExist:self name:name]) {
        return [[class ?: [RSBucket class] alloc] initWithStorage:self name:name];
    }
    return nil;
}
@end

@implementation RSStorage (DBConnector)

- (RSDatabaseConnector *)connectorNamed:(NSString *)name {
    return [[RSDatabaseConnector alloc] initWithStorage:self name:[name stringByAppendingPathExtension:@"dat"]];
}

@end
