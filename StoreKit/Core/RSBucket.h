//
//  RSBucket.h
//  StoreKit
//
//  Created by closure on 3/21/15.
//  Copyright (c) 2015 closure. All rights reserved.
//

#import "RSPrimaryKey.h"

@class RSStorage;

@interface RSBucket : RSObject
@property (strong, nonatomic, readonly) NSString *path;
@property (strong, nonatomic, readonly) NSString *name;
- (instancetype)initWithStorage:(RSStorage *)storage name:(NSString *)name;

- (BOOL)setObject:(id <NSCoding>)object forKey:(id<RSPrimaryKey>)aKey;
- (id <NSCoding>)objectForKey:(id <RSPrimaryKey>)key;
@end
