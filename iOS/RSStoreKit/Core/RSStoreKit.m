//
//  RSStoreKit.m
//  StoreKit
//
//  Created by closure on 3/20/15.
//  Copyright (c) 2015 closure. All rights reserved.
//

#import "RSStoreKit.h"
#import "RSStorage.h"
#import <CommonCrypto/CommonCrypto.h>

static NSString *__StoreKitRootName = @"StoreKit";

NSString *RSStoreKitStorageShowNameKey = @"RSStoreKitStorageShowName";

@interface RSStorage (Private)
- (id)parent;
@end

@interface RSStoreKit (Initialize)
- (void)_initFileSystemStoreKit;
@end

@interface RSStoreKit ()
@property (strong, nonatomic) NSFileManager *fileMgr;
@property (strong, nonatomic) NSMutableArray *storages; // level 1
@property (strong, nonatomic) dispatch_queue_t storageQueue;
@end

@implementation RSStoreKit
+ (void)load {
    [self kit];
}

+ (instancetype)kit {
    static dispatch_once_t onceToken;
    static RSStoreKit *__kit = nil;
    dispatch_once(&onceToken, ^{
        __kit = [[self alloc] init];
    });
    return __kit;
}

- (instancetype)init {
    if (self = [super init]) {
        [self _initFileSystemStoreKit];
        _storageQueue = dispatch_queue_create("com.RSStoreKit.storageService.requestQueue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}
@end

@implementation RSStoreKit (Storage)

+ (BOOL)_createStorageIfNoExist:(RSStoreKit *)kit name:(NSString *)name {
    NSFileManager *fileMgr = [kit fileMgr];
    NSString *path = [[kit rootPath] stringByAppendingPathComponent:name];
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
    if ([RSStoreKit _createStorageIfNoExist:self name:name]) {
        RSStorage *storage = [[RSStorage alloc] initWithStore:self name:name];
        [self commitStoreRequest:^{
            [_storages addObject:storage];
        }];
        return storage;
    }
    return nil;
}

- (void)_removeStorageImpl:(RSStorage *)storage {
    NSError *error = nil;
    BOOL success = [_fileMgr removeItemAtPath:[storage path] error:&error];
    if (!success) {
        NSLog(@"%@", error);
    }
}

- (void)removeStorage:(RSStorage *)storage {
    if ([storage level] == 1) {
        [self commitStoreRequest:^{
            [self _removeStorageImpl:storage];
        }];
    } else {
        return [[storage parent] removeStorage:storage];
    }
}

- (void)removeAllStorages {
    [self commitStoreRequest:^{
        for (RSStorage *storage in _storages) {
            [self _removeStorageImpl:storage];
        }
        [_storages removeAllObjects];
    }];
}

- (void)cleanup {
    [self commitStoreRequest:^{
        [_fileMgr removeItemAtPath:[self rootPath] error:nil];
        [self _initFileSystemStoreKit];
    }];
}

- (void)commitStoreRequest:(void (^)())request {
    dispatch_sync(_storageQueue, request);
}
@end

@implementation RSStoreKit (Name)

+ (NSString *)nameForKey:(NSString *)key {
    if (key == nil) {
        key = @"";
    }
    if ([[[NSBundle mainBundle] infoDictionary][RSStoreKitStorageShowNameKey] boolValue]) {
        return key;
    }
    return [self nameForKeyImpl:key];
}

+ (NSString *)nameForKeyImpl:(NSString *)key {
    const char *str = [key UTF8String];
    if (str == NULL) {
        str = "";
    }
    unsigned char r[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, (CC_LONG)strlen(str), r);
    NSString *filename = [NSString stringWithFormat:@"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
                          r[0], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9], r[10], r[11], r[12], r[13], r[14], r[15]];
    
    return filename;
}

@end

@implementation RSStoreKit (Initialize)

- (void)_initFileSystemStoreKit {
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSAllDomainsMask, YES) firstObject];
    NSLog(@"%@", path);
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    NSString *rootPath = [path stringByAppendingPathComponent:__StoreKitRootName];
    NSError *fileError = nil;
    BOOL success = [fileMgr createDirectoryAtPath:rootPath withIntermediateDirectories:YES attributes:nil error:&fileError];
    if (!success) {
        NSLog(@"%@", [fileError localizedDescription]);
        return;
    }
    NSLog(@"create %@ success", rootPath);
    _rootPath = rootPath;
    _fileMgr = fileMgr;
    _storages = [[NSMutableArray alloc] initWithCapacity:8];
}

@end
