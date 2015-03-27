//
//  RSVersionDao.h
//  StoreKit
//
//  Created by closure on 3/21/15.
//  Copyright (c) 2015 closure. All rights reserved.
//

#import "RSDao.h"

@interface RSVersionInfo : RSStringPK
@property (assign, nonatomic) NSInteger version;
@property (strong, nonatomic) NSDate *timestamp;
@property (strong, nonatomic) id meta;
+ (instancetype)versionWithTable:(NSString *)tableName version:(NSInteger)version;
+ (instancetype)versionWithTable:(NSString *)tableName version:(NSInteger)version meta:(id)meta;
- (instancetype)initWithTable:(NSString *)token version:(NSInteger)version;
- (instancetype)initWithTable:(NSString *)token version:(NSInteger)version meta:(id)meta;
@end

@interface RSVersionDao : RSDao
- (BOOL)add:(RSVersionInfo *)obj;
- (RSVersionInfo *)get:(NSString *)tableName;
- (BOOL)update:(RSVersionInfo *)obj;
- (BOOL)remove:(id<RSPrimaryKey>)key;
@end
