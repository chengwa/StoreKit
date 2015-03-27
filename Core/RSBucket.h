//
//  RSBucket.h
//  StoreKit
//
//  Created by closure on 3/21/15.
//  Copyright (c) 2015 closure. All rights reserved.
//

#import "RSPrimaryKey.h"

@class RSStorage;


typedef NS_ENUM(NSInteger, RSBucketCacheType) {
    RSBucketCacheTypeNone,
    RSBucketCacheTypeDisk,
    RSBucketCacheTypeMemory
};

typedef void(^RSBucketNoParamsBlock)();

typedef void(^RSBucketQueryCompletedBlock)(NSData *data, RSBucketCacheType cacheType);

typedef void(^RSBucketCheckCacheCompletionBlock)(BOOL isInCache);

typedef void(^RSBucketCalculateSizeBlock)(NSUInteger fileCount, NSUInteger totalSize);

typedef NSString *(^RSBucketCacheKeyFilterBlock)(NSURL *url);

@interface RSBucket : RSObject
@property (strong, nonatomic, readonly) NSString *path;
@property (strong, nonatomic, readonly) NSString *name;
- (instancetype)initWithStorage:(RSStorage *)storage name:(NSString *)name;
- (instancetype)initWithStorage:(RSStorage *)storage name:(NSString *)name enableCache:(BOOL)enabled;
- (void)setUseMemoryCache:(BOOL)useMemoryCache;
@end

@interface RSBucket (Cache)
- (void)addReadOnlyCachePath:(NSString *)path;
- (void)storeData:(NSData *)data forKey:(NSString *)key;
- (void)storeData:(NSData *)data forKey:(NSString *)key toDisk:(BOOL)toDisk;
- (NSOperation *)queryDiskCacheForKey:(NSString *)key done:(RSBucketQueryCompletedBlock)doneBlock;
- (NSData *)dataFromMemoryCacheForKey:(NSString *)key;
- (NSData *)dataFromDiskCacheForKey:(NSString *)key;
- (void)removeDataForKey:(NSString *)key;
- (void)removeDataForKey:(NSString *)key withCompletion:(RSBucketNoParamsBlock)completion;
- (void)removeDataForKey:(NSString *)key fromDisk:(BOOL)fromDisk;
- (void)removeDataForKey:(NSString *)key fromDisk:(BOOL)fromDisk withCompletion:(RSBucketNoParamsBlock)completion;
- (void)clearMemory;
- (void)clearDiskOnCompletion:(RSBucketNoParamsBlock)completion;
- (void)clearDisk;
- (void)cleanDiskWithCompletionBlock:(RSBucketNoParamsBlock)completionBlock;
- (void)cleanDisk;
- (NSUInteger)getSize;
- (NSUInteger)getDiskCount;
- (void)calculateSizeWithCompletionBlock:(RSBucketCalculateSizeBlock)completionBlock;
- (void)diskDataExistsWithKey:(NSString *)key completion:(RSBucketCheckCacheCompletionBlock)completionBlock;
- (BOOL)diskDataExistsWithKey:(NSString *)key;
- (NSString *)cachePathForKey:(NSString *)key inPath:(NSString *)path;
- (NSString *)defaultCachePathForKey:(NSString *)key;
@end


