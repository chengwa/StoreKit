//
//  RSStoreKit.m
//  StoreKit
//
//  Created by closure on 3/20/15.
//  Copyright (c) 2015 closure. All rights reserved.
//

#import "RSStoreKit.h"
#import "RSStorage.h"

static NSString *__StoreKitRootName = @"StoreKit";

@interface RSStoreKit (Initialize)
- (void)_initFileSystemStoreKit;
@end

@interface RSStoreKit ()
@property (strong, nonatomic) NSFileManager *fileMgr;
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
        _storageQueue = dispatch_queue_create("com.RSStoreKit.storageService.requestQueue", 0);
    }
    return self;
}
@end

@implementation RSStoreKit (Bucket)

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
        return [[RSStorage alloc] initWithStore:self name:name];
    }
    return nil;
}

- (void)commitStoreRequest:(void (^)())request {
    dispatch_sync(_storageQueue, request);
}
@end

@implementation RSStoreKit (Initialize)

- (void)_initFileSystemStoreKit {
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSAllDomainsMask, YES) firstObject];
    NSLog(@"%@", path);
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    path = [path stringByDeletingLastPathComponent];
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
}

@end
