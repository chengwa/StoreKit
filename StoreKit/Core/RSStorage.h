//
//  RSBucket.h
//  StoreKit
//
//  Created by closure on 3/20/15.
//  Copyright (c) 2015 closure. All rights reserved.
//

#import "RSPrimaryKey.h"

@class RSStoreKit, RSBucket, RSDatabaseConnector;

@interface RSStorage : RSObject
@property (strong, nonatomic, readonly) NSString *path;
@property (strong, nonatomic, readonly) NSString *name;
- (instancetype)initWithStore:(RSStoreKit *)kit name:(NSString *)name;

- (BOOL)setObject:(id <NSCoding>)object forKey:(id<RSPrimaryKey>)aKey;
- (id <NSCoding>)objectForKey:(id <RSPrimaryKey>)key;
@end

@interface RSStorage (Bucket)
- (RSBucket *)bucket;
- (RSBucket *)bucketNamed:(NSString *)name;
- (void)commitStoreRequest:(void(^)())request;
@end

@interface RSStorage (DBConnector)
- (RSDatabaseConnector *)connectorNamed:(NSString *)name;
@end