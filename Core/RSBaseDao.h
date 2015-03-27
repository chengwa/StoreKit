//
//  RSBaseDao.h
//  StoreKit
//
//  Created by closure on 3/21/15.
//  Copyright (c) 2015 closure. All rights reserved.
//
#import "RSDatabaseConnector.h"
#import "RSPrimaryKey.h"
#import <Foundation/Foundation.h>

@interface RSBaseDaoInStmt: RSObject
@property (nonatomic, strong, readonly) NSArray *qs;
@property (nonatomic, strong, readonly) NSArray *ks;
+ (instancetype)stmtWithQS:(NSArray *)qs KS:(NSArray *)ks;
+ (instancetype)stmtWithIntPKs:(NSArray *)keys;
+ (instancetype)stmtWithStringPKs:(NSArray *)keys;
@end

@interface RSBaseDao : RSObject
@property (nonatomic, strong) RSDatabaseConnector *connector;

+ (instancetype)daoWithConnector:(RSDatabaseConnector *)connector;
- (instancetype)initWithConnector:(RSDatabaseConnector *)connector;

- (BOOL)add:(id<RSPrimaryKey>)obj;
- (BOOL)update:(id<RSPrimaryKey>)obj result:(void(^)(BOOL success))action;
- (BOOL)remove:(id<RSPrimaryKey>)key;
- (BOOL)removeObjects:(NSArray *)keys;

- (void)get:(id<RSPrimaryKey>)key reuslt:(void (^)(id<RSPrimaryKey> result))action;
- (void)multiGet:(NSArray *)keys results:(void (^)(NSArray *results))action;

- (id<RSPrimaryKey>)get:(id<RSPrimaryKey>)key;
- (NSArray *)multiGet:(NSArray *)keys;

- (NSError *)lastError;
@end

@interface RSBaseDao (DaoExtension)
+ (NSString *)primaryKeyName;
+ (Class<RSRowMapper, NSObject>)defaultRowMapper;
+ (NSString *)createDao;
+ (NSString *)dropDao;
+ (NSInteger)daoVersion;
+ (NSString *)daoName;
@end
