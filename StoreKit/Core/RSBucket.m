//
//  RSBucket.m
//  StoreKit
//
//  Created by closure on 3/21/15.
//  Copyright (c) 2015 closure. All rights reserved.
//

#import "RSBucket.h"
#import "RSStorage.h"

#import <UIKit/UIKit.h>

static const NSInteger kDefaultCacheMaxCacheAge = 60 * 60 * 24 * 7 * 8; // 1 week

@interface RSBucket () {
    NSFileManager *_fileManager;
}

@property (weak, nonatomic) RSStorage *storage;

@property (assign, nonatomic) NSUInteger maxMemoryCost;
@property (assign, nonatomic) NSInteger maxCacheAge;
@property (assign, nonatomic) NSUInteger maxCacheSize;
@property (assign, nonatomic, getter=isUseMemoryCache) BOOL useMemoryCache;

@property (strong, nonatomic) NSCache *memCache;
@property (strong, nonatomic) NSString *diskCachePath;
@property (strong, nonatomic) NSMutableArray *customPaths;
@property (strong, nonatomic) dispatch_queue_t ioQueue;

- (void)__commonInitialize:(NSString *)fullNamespace useMemoryCache:(BOOL)enabled;
@end

@interface RSBucket (Path)
+ (NSString *)storagePathWithName:(NSString *)name;
@end

@implementation RSBucket
- (void)__commonInitialize:(NSString *)fullNamespace useMemoryCache:(BOOL)enabled {
    _ioQueue = dispatch_queue_create([fullNamespace UTF8String], DISPATCH_QUEUE_SERIAL);
    
    // Init default values
    _maxCacheAge = kDefaultCacheMaxCacheAge;
    
    // Init the memory cache
    [self setUseMemoryCache:enabled];
    
    // Init the disk cache
    _diskCachePath = [_path stringByAppendingPathComponent:fullNamespace];
    
    dispatch_sync(_ioQueue, ^{
        _fileManager = [[NSFileManager alloc] init];
    });
    
#if TARGET_OS_IPHONE
    // Subscribe to app events
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(clearMemory)
                                                 name:UIApplicationDidReceiveMemoryWarningNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(cleanDisk)
                                                 name:UIApplicationWillTerminateNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(backgroundCleanDisk)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
#endif
}


- (void)backgroundCleanDisk {
    UIApplication *application = [UIApplication sharedApplication];
    __block UIBackgroundTaskIdentifier bgTask = [application beginBackgroundTaskWithExpirationHandler:^{
        // Clean up any unfinished task business by marking where you
        // stopped or ending the task outright.
        [application endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }];
    
    // Start the long-running task and return immediately.
    [self cleanDiskWithCompletionBlock:^{
        [application endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }];
}

- (instancetype)initWithStorage:(RSStorage *)storage name:(NSString *)name {
    return [self initWithStorage:storage name:name enableCache:NO];
}

- (instancetype)initWithStorage:(RSStorage *)storage name:(NSString *)name enableCache:(BOOL)enabled {
    if (!storage || [name length] == 0) {
        return nil;
    }
    if (self = [super init]) {
        _storage = storage;
        _name = name;
        _path = [[storage path] stringByAppendingPathComponent:name];
        [self __commonInitialize:_name useMemoryCache:enabled];
    }
    return self;
}

- (NSUInteger)hash {
    return [[self path] hash];
}

- (BOOL)isEqual:(id)object {
    return [object isKindOfClass:[self class]] && [_path isEqualToString:[(RSBucket*)object path]];
}

@end

#include <CommonCrypto/CommonCrypto.h>

@implementation RSBucket (Cache)

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setUseMemoryCache:(BOOL)useMemoryCache {
    dispatch_async(_ioQueue, ^{
        _useMemoryCache = useMemoryCache;
        if (!_useMemoryCache) {
            _memCache = nil;
            return;
        }
        _memCache = [[NSCache alloc] init];
        _memCache.name = @(dispatch_queue_get_label(_ioQueue));
    });
}

- (void)addReadOnlyCachePath:(NSString *)path {
    if (!self.customPaths) {
        self.customPaths = [NSMutableArray new];
    }
    
    if (![self.customPaths containsObject:path]) {
        [self.customPaths addObject:path];
    }
}

- (NSString *)cachePathForKey:(NSString *)key inPath:(NSString *)path {
    NSString *filename = [self cachedFileNameForKey:key];
    return [path stringByAppendingPathComponent:filename];
}

- (NSString *)defaultCachePathForKey:(NSString *)key {
    return [self cachePathForKey:key inPath:self.diskCachePath];
}

#pragma mark SDImageCache (private)

- (NSString *)cachedFileNameForKey:(NSString *)key {
    const char *str = [key UTF8String];
    if (str == NULL) {
        str = "";
    }
    unsigned char r[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, (CC_LONG)strlen(str), r);
    NSString *filename = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
                          r[0], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9], r[10], r[11], r[12], r[13], r[14], r[15]];
    
    return filename;
}

#pragma mark ImageCache

- (void)storeData:(NSData *)data forKey:(NSString *)key toDisk:(BOOL)toDisk {
    if (!data || !key) {
        return;
    }
    if (_useMemoryCache) {
        [_memCache setObject:data forKey:key cost:[data length]];
    }
    
    if (toDisk) {
        dispatch_async(self.ioQueue, ^{
            if (data) {
                if (![_fileManager fileExistsAtPath:_diskCachePath]) {
                    [_fileManager createDirectoryAtPath:_diskCachePath withIntermediateDirectories:YES attributes:nil error:NULL];
                }
                
                [_fileManager createFileAtPath:[self defaultCachePathForKey:key] contents:data attributes:nil];
            }
        });
    }
}

- (void)storeData:(NSData *)data forKey:(NSString *)key {
    [self storeData:data forKey:key toDisk:YES];
}

- (BOOL)diskDataExistsWithKey:(NSString *)key {
    BOOL exists = NO;
    
    // this is an exception to access the filemanager on another queue than ioQueue, but we are using the shared instance
    // from apple docs on NSFileManager: The methods of the shared NSFileManager object can be called from multiple threads safely.
    exists = [[NSFileManager defaultManager] fileExistsAtPath:[self defaultCachePathForKey:key]];
    
    return exists;
}

- (void)diskDataExistsWithKey:(NSString *)key completion:(RSBucketCheckCacheCompletionBlock)completionBlock {
    dispatch_async(_ioQueue, ^{
        BOOL exists = [_fileManager fileExistsAtPath:[self defaultCachePathForKey:key]];
        if (completionBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock(exists);
            });
        }
    });
}

- (NSData *)dataFromMemoryCacheForKey:(NSString *)key {
    if (!_useMemoryCache) {
        return nil;
    }
    return [_memCache objectForKey:key];
}

- (NSData *)dataFromDiskCacheForKey:(NSString *)key {
    // First check the in-memory cache...
    NSData *data = [self dataFromMemoryCacheForKey:key];
    if (data) {
        return data;
    }
    
    // Second check the disk cache...
    NSData *diskImage = [self diskDataForKey:key];
    if (diskImage) {
        if (_useMemoryCache) {
            CGFloat cost = [diskImage length];
            [_memCache setObject:diskImage forKey:key cost:cost];
        }
    }
    
    return diskImage;
}

- (NSData *)diskDataBySearchingAllPathsForKey:(NSString *)key {
    NSString *defaultPath = [self defaultCachePathForKey:key];
    NSData *data = [NSData dataWithContentsOfFile:defaultPath];
    if (data) {
        return data;
    }
    
    for (NSString *path in self.customPaths) {
        NSString *filePath = [self cachePathForKey:key inPath:path];
        data = [NSData dataWithContentsOfFile:filePath];
        if (data) {
            return data;
        }
    }
    
    return nil;
}

- (NSData *)diskDataForKey:(NSString *)key {
    NSData *data = [self diskDataBySearchingAllPathsForKey:key];
    if (data) {
        return data;
    }
    else {
        return nil;
    }
}

- (NSOperation *)queryDiskCacheForKey:(NSString *)key done:(RSBucketQueryCompletedBlock)doneBlock {
    if (!doneBlock) {
        return nil;
    }
    
    if (!key) {
        doneBlock(nil, RSBucketCacheTypeNone);
        return nil;
    }
    
    // First check the in-memory cache...
    NSData *data = [self dataFromMemoryCacheForKey:key];
    if (data) {
        doneBlock(data, RSBucketCacheTypeMemory);
        return nil;
    }
    
    NSOperation *operation = [NSOperation new];
    dispatch_async(self.ioQueue, ^{
        if (operation.isCancelled) {
            return;
        }
        
        @autoreleasepool {
            NSData *diskData = [self diskDataForKey:key];
            if (diskData) {
                if (_useMemoryCache) {
                    CGFloat cost = [diskData length];
                    [_memCache setObject:diskData forKey:key cost:cost];
                }
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                doneBlock(diskData, RSBucketCacheTypeDisk);
            });
        }
    });
    
    return operation;
}

- (void)removeDataForKey:(NSString *)key {
    [self removeDataForKey:key withCompletion:nil];
}

- (void)removeDataForKey:(NSString *)key withCompletion:(RSBucketNoParamsBlock)completion {
    [self removeDataForKey:key fromDisk:YES withCompletion:completion];
}

- (void)removeDataForKey:(NSString *)key fromDisk:(BOOL)fromDisk {
    [self removeDataForKey:key fromDisk:fromDisk withCompletion:nil];
}

- (void)removeDataForKey:(NSString *)key fromDisk:(BOOL)fromDisk withCompletion:(RSBucketNoParamsBlock)completion {
    
    if (key == nil) {
        return;
    }
    if (_useMemoryCache) {
        [_memCache removeObjectForKey:key];
    }
    
    if (fromDisk) {
        dispatch_async(self.ioQueue, ^{
            [_fileManager removeItemAtPath:[self defaultCachePathForKey:key] error:nil];
            
            if (completion) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion();
                });
            }
        });
    } else if (completion){
        completion();
    }
    
}

- (void)setMaxMemoryCost:(NSUInteger)maxMemoryCost {
    if (!_useMemoryCache) {
        return;
    }
    _memCache.totalCostLimit = maxMemoryCost;
}

- (NSUInteger)maxMemoryCost {
    if (!_useMemoryCache) {
        return 0;
    }
    return _memCache.totalCostLimit;
}

- (void)clearMemory {
    [_memCache removeAllObjects];
}

- (void)clearDisk {
    [self clearDiskOnCompletion:nil];
}

- (void)clearDiskOnCompletion:(RSBucketNoParamsBlock)completion
{
    dispatch_async(self.ioQueue, ^{
        [_fileManager removeItemAtPath:self.diskCachePath error:nil];
        [_fileManager createDirectoryAtPath:self.diskCachePath
                withIntermediateDirectories:YES
                                 attributes:nil
                                      error:NULL];
        
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion();
            });
        }
    });
}

- (void)cleanDisk {
    [self cleanDiskWithCompletionBlock:nil];
}

- (void)cleanDiskWithCompletionBlock:(RSBucketNoParamsBlock)completionBlock {
    dispatch_async(self.ioQueue, ^{
        NSURL *diskCacheURL = [NSURL fileURLWithPath:self.diskCachePath isDirectory:YES];
        NSArray *resourceKeys = @[NSURLIsDirectoryKey, NSURLContentModificationDateKey, NSURLTotalFileAllocatedSizeKey];
        
        // This enumerator prefetches useful properties for our cache files.
        NSDirectoryEnumerator *fileEnumerator = [_fileManager enumeratorAtURL:diskCacheURL
                                                   includingPropertiesForKeys:resourceKeys
                                                                      options:NSDirectoryEnumerationSkipsHiddenFiles
                                                                 errorHandler:NULL];
        
        NSDate *expirationDate = [NSDate dateWithTimeIntervalSinceNow:-self.maxCacheAge];
        NSMutableDictionary *cacheFiles = [NSMutableDictionary dictionary];
        NSUInteger currentCacheSize = 0;
        
        // Enumerate all of the files in the cache directory.  This loop has two purposes:
        //
        //  1. Removing files that are older than the expiration date.
        //  2. Storing file attributes for the size-based cleanup pass.
        NSMutableArray *urlsToDelete = [[NSMutableArray alloc] init];
        for (NSURL *fileURL in fileEnumerator) {
            NSDictionary *resourceValues = [fileURL resourceValuesForKeys:resourceKeys error:NULL];
            
            // Skip directories.
            if ([resourceValues[NSURLIsDirectoryKey] boolValue]) {
                continue;
            }
            
            // Remove files that are older than the expiration date;
            NSDate *modificationDate = resourceValues[NSURLContentModificationDateKey];
            if ([[modificationDate laterDate:expirationDate] isEqualToDate:expirationDate]) {
                [urlsToDelete addObject:fileURL];
                continue;
            }
            
            // Store a reference to this file and account for its total size.
            NSNumber *totalAllocatedSize = resourceValues[NSURLTotalFileAllocatedSizeKey];
            currentCacheSize += [totalAllocatedSize unsignedIntegerValue];
            cacheFiles[fileURL] = resourceValues;
        }
        
        for (NSURL *fileURL in urlsToDelete) {
            [_fileManager removeItemAtURL:fileURL error:nil];
        }
        
        // If our remaining disk cache exceeds a configured maximum size, perform a second
        // size-based cleanup pass.  We delete the oldest files first.
        if (self.maxCacheSize > 0 && currentCacheSize > self.maxCacheSize) {
            // Target half of our maximum cache size for this cleanup pass.
            const NSUInteger desiredCacheSize = self.maxCacheSize / 2;
            
            // Sort the remaining cache files by their last modification time (oldest first).
            NSArray *sortedFiles = [cacheFiles keysSortedByValueWithOptions:NSSortConcurrent
                                                            usingComparator:^NSComparisonResult(id obj1, id obj2) {
                                                                return [obj1[NSURLContentModificationDateKey] compare:obj2[NSURLContentModificationDateKey]];
                                                            }];
            
            // Delete files until we fall below our desired cache size.
            for (NSURL *fileURL in sortedFiles) {
                if ([_fileManager removeItemAtURL:fileURL error:nil]) {
                    NSDictionary *resourceValues = cacheFiles[fileURL];
                    NSNumber *totalAllocatedSize = resourceValues[NSURLTotalFileAllocatedSizeKey];
                    currentCacheSize -= [totalAllocatedSize unsignedIntegerValue];
                    
                    if (currentCacheSize < desiredCacheSize) {
                        break;
                    }
                }
            }
        }
        if (completionBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock();
            });
        }
    });
}

- (NSUInteger)getSize {
    __block NSUInteger size = 0;
    dispatch_sync(self.ioQueue, ^{
        NSDirectoryEnumerator *fileEnumerator = [_fileManager enumeratorAtPath:self.diskCachePath];
        for (NSString *fileName in fileEnumerator) {
            NSString *filePath = [self.diskCachePath stringByAppendingPathComponent:fileName];
            NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
            size += [attrs fileSize];
        }
    });
    return size;
}

- (NSUInteger)getDiskCount {
    __block NSUInteger count = 0;
    dispatch_sync(self.ioQueue, ^{
        NSDirectoryEnumerator *fileEnumerator = [_fileManager enumeratorAtPath:self.diskCachePath];
        count = [[fileEnumerator allObjects] count];
    });
    return count;
}

- (void)calculateSizeWithCompletionBlock:(RSBucketCalculateSizeBlock)completionBlock {
    NSURL *diskCacheURL = [NSURL fileURLWithPath:self.diskCachePath isDirectory:YES];
    
    dispatch_async(self.ioQueue, ^{
        NSUInteger fileCount = 0;
        NSUInteger totalSize = 0;
        
        NSDirectoryEnumerator *fileEnumerator = [_fileManager enumeratorAtURL:diskCacheURL
                                                   includingPropertiesForKeys:@[NSFileSize]
                                                                      options:NSDirectoryEnumerationSkipsHiddenFiles
                                                                 errorHandler:NULL];
        
        for (NSURL *fileURL in fileEnumerator) {
            NSNumber *fileSize;
            [fileURL getResourceValue:&fileSize forKey:NSURLFileSizeKey error:NULL];
            totalSize += [fileSize unsignedIntegerValue];
            fileCount += 1;
        }
        
        if (completionBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock(fileCount, totalSize);
            });
        }
    });
}

@end
