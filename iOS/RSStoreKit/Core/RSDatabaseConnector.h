//
//  RSDatabaseConnector.h
//  StoreKit
//
//  Created by closure on 3/21/15.
//  Copyright (c) 2015 closure. All rights reserved.
//

#import "RSRowMapper.h"
#import "RSObject.h"

@class FMDatabaseQueue, RSStorage;

@interface RSDatabaseConnector : RSObject
+ (NSString *)pathForName:(NSString *)name;
- (instancetype)init;
- (instancetype)initWithName:(NSString *)name;
- (instancetype)initWithPath:(NSString *)path name:(NSString *)name;
- (instancetype)initWithStorage:(RSStorage *)storage name:(NSString *)name;

- (void)executeStatements:(NSString *)sql;

- (void)updateWithAction:(void (^)(BOOL success))action SQL:(NSString *)sql,... NS_REQUIRES_NIL_TERMINATION;
- (void)queryObjectWithActon:(void(^)(id obj))action rowMapper:(id<RSRowMapper>)rowMapper SQL:(NSString *)sql, ... NS_REQUIRES_NIL_TERMINATION;
- (void)queryObjectsWithActon:(void(^)(NSArray *objs))action rowMapper:(id<RSRowMapper>)rowMapper SQL:(NSString *)sql, ... NS_REQUIRES_NIL_TERMINATION;
- (BOOL)updateWithSQL:(NSString *)sql,... NS_REQUIRES_NIL_TERMINATION;
- (id)queryObjectWithRowMapper:(id<RSRowMapper>)rowMapper SQL:(NSString *)sql, ... NS_REQUIRES_NIL_TERMINATION;
- (NSMutableArray *)queryObjectsWithRowMapper:(id<RSRowMapper>)rowMapper SQL:(NSString *)sql, ... NS_REQUIRES_NIL_TERMINATION;
- (NSMutableArray *)queryObjectsWithRowMapper:(id<RSRowMapper>)rowMapper SQL:(NSString *)sql ids:(NSArray *)keys;

- (long long)countOfTable:(NSString *)tableName;
- (BOOL)dropTable:(NSString *)table;
- (NSMutableArray *)allTableNames;

- (BOOL)tableIsExist:(NSString *)tableName;

- (FMDatabaseQueue *)dbQueue;

- (NSError *)lastError;
@end

