//
//  RSBucket.h
//  StoreKit
//
//  Created by closure on 3/20/15.
//  Copyright (c) 2015 closure. All rights reserved.
//

#import "RSPrimaryKey.h"
#import "RSBucket.h"

@class RSStoreKit, RSDatabaseConnector;

@interface RSStorage : RSObject
@property (strong, nonatomic, readonly) NSString *path;
@property (strong, nonatomic, readonly) NSString *name;
@property (assign, nonatomic, readonly) NSInteger level;
- (instancetype)initWithStore:(RSStoreKit *)kit name:(NSString *)name;
- (instancetype)initWithStorage:(RSStorage *)storage name:(NSString *)name;

- (void)setObject:(id <NSCoding>)object forKey:(id<RSPrimaryKey>)aKey ;
- (void)objectForKey:(id <RSPrimaryKey>)key withCompletion:(RSBucketQueryCompletedBlock)block;
- (id <NSCoding>)objectForKey:(id<RSPrimaryKey>)key;
@end

@interface RSStorage (Storage)
- (RSStorage *)storageNamed:(NSString *)name;
- (void)removeStorage:(RSStorage *)storage;
@end

@interface RSStorage (Bucket)
- (RSBucket *)bucket;
- (RSBucket *)bucketNamed:(NSString *)name;
- (RSBucket *)bucketNamed:(NSString *)name forClassImpl:(id)cls;
@end

@interface RSStorage (DBConnector)
- (RSDatabaseConnector *)connectorNamed:(NSString *)name;
@end