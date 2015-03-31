//
//  RSBaseDao.m
//  StoreKit
//
//  Created by closure on 3/21/15.
//  Copyright (c) 2015 closure. All rights reserved.
//

#import "RSBaseDao.h"

@implementation RSBaseDaoInStmt

+ (NSArray *)qsWithKS:(NSArray *)ks {
    NSMutableArray *qs = [[NSMutableArray alloc] initWithCapacity:[ks count]];
    for (NSInteger idx = 0; idx < [ks count]; ++idx) {
        [qs addObject:@"?"];
    }
    return qs;
}

+ (instancetype)stmtWithQS:(NSArray *)qs KS:(NSArray *)ks {
    return [[self alloc] initWithQS:qs KS:ks];
}

- (instancetype)initWithQS:(NSArray *)qs KS:(NSArray *)ks {
    if (self = [super init]) {
        _qs = qs;
        _ks = ks;
    }
    return self;
}

+ (instancetype)stmtWithIntPKs:(NSArray *)keys {
    return [[self alloc] initWithIntPKs:keys];
}

+ (instancetype)stmtWithStringPKs:(NSArray *)keys {
    return [[self alloc] initWithStringPKs:keys];
}

- (instancetype)initWithIntPKs:(NSArray *)keys {
    if (self = [super init]) {
        NSMutableArray *ks = [[NSMutableArray alloc] initWithCapacity:[keys count]];
        for (id<RSPrimaryKey> k in keys) {
            [ks addObject:@([[k getInKey] longLongValue])];
        }
        _ks = ks;
        _qs = [RSBaseDaoInStmt qsWithKS:_ks];
    }
    return self;
}

- (instancetype)initWithStringPKs:(NSArray *)keys {
    if (self = [super init]) {
        NSMutableArray *ks = [[NSMutableArray alloc] initWithCapacity:[keys count]];
        for (id<RSPrimaryKey> k in keys) {
            [ks addObject:[k getInKey]];
        }
        _ks = ks;
        _qs = [RSBaseDaoInStmt qsWithKS:_ks];
    }
    return self;
    
}
@end

@interface RSBaseDao ()

@end

@implementation RSBaseDao

+ (instancetype)daoWithConnector:(RSDatabaseConnector *)connector {
    return [[self alloc] initWithConnector:connector];
}

- (instancetype)initWithConnector:(RSDatabaseConnector *)connector {
    if (self = [super init]) {
        _connector = connector;
    }
    return self;
}

- (BOOL)add:(id<RSPrimaryKey>)obj {
    [NSException raise:NSInternalInconsistencyException
                format:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)];
    return NO;
}

- (BOOL)update:(id<RSPrimaryKey>)obj result:(void (^)(BOOL))action {
    [NSException raise:NSInternalInconsistencyException
                format:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)];
    return NO;
}

- (BOOL)remove:(id<RSPrimaryKey>)key {
    [NSException raise:NSInternalInconsistencyException
                format:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)];
    return NO;
}

- (BOOL)removeObjects:(NSArray *)keys {
    [NSException raise:NSInternalInconsistencyException
                format:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)];
    return NO;
}

- (void)get:(id<RSPrimaryKey>)key reuslt:(void (^)(id<RSPrimaryKey>))action {
    [NSException raise:NSInternalInconsistencyException
                format:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)];
    return;
}

- (void)multiGet:(NSArray *)keys results:(void (^)(NSArray *))action {
    [NSException raise:NSInternalInconsistencyException
                format:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)];
    return;
}

- (id<RSPrimaryKey>)get:(id<RSPrimaryKey>)key {
    [NSException raise:NSInternalInconsistencyException
                format:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)];
    return nil;
}

- (NSArray *)multiGet:(NSArray *)keys {
    [NSException raise:NSInternalInconsistencyException
                format:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)];
    return nil;
}

- (NSError *)lastError {
    return [[self connector] lastError];
}

+ (BOOL)supportDynamic {
    return NO;
}

+ (NSString *)dropDao {
    if ([[self daoName] length] == 0) {
        return nil;
    }
    return [NSString stringWithFormat:@"drop table %@", [self daoName]];
}

+ (NSInteger)daoVersion {
    return 1;
}

+ (NSString *)createDao {
    return nil;
}

+ (NSString *)daoName {
    return nil;
}

+ (NSString *)primaryKeyName {
    return @"id";
}

+ (Class<RSRowMapper,NSObject>)defaultRowMapper {
    return nil;
}

- (Class<RSRowMapper,NSObject>)defaultRowMapper {
    return [[self class] defaultRowMapper];
}

- (NSString *)primaryKeyName {
    return [[self class] primaryKeyName];
}

- (NSString *)daoName {
    return [[self class] daoName];
}

- (NSString *)createDao {
    return [[self class] createDao];
}

- (NSString *)dropDao {
    return [[self class] dropDao];
}

- (NSInteger)daoVersion {
    return [[self class] daoVersion];
}

@end
