//
//  RSDao.m
//  StoreKit
//
//  Created by closure on 3/21/15.
//  Copyright (c) 2015 closure. All rights reserved.
//

#import "RSDao.h"
#import "RSVersionDao.h"

@implementation RSDao
- (instancetype)initWithConnector:(RSDatabaseConnector *)connector {
    if (self = [super initWithConnector:connector]) {
        RSVersionDao *vd = nil;
        if (![self isKindOfClass:[RSVersionDao class]]) {
            vd = [[RSVersionDao alloc] initWithConnector:connector];
        }
        RSVersionInfo *vi = [vd get:[[self class] daoName]];
        if ([vi version] < [[self class] daoVersion]) {
            [connector executeStatements:[[self class] dropDao]];
        }
        if (![connector tableIsExist:[[self class] daoName]]) {
            [connector executeStatements:[[self class] createDao]];
            [vd add:[RSVersionInfo versionWithTable:[[self class] daoName] version:[[self class] daoVersion]]];
        } else if (vi == nil) {
            [vd add:[RSVersionInfo versionWithTable:[[self class] daoName] version:[[self class] daoVersion]]];
        }
    }
    return self;
}

- (BOOL)remove:(id<RSPrimaryKey>)key {
    static NSString *sqlFormat = @"delete from %@ where %@ = ?";
    NSString *sql = [NSString stringWithFormat:sqlFormat, [[self class] daoName], [[self class] primaryKeyName] ? : @"id"];
    id pk = nil;
    if ([key isKindOfClass:[RSIntPK class]]) {
        pk = @([[key getInKey] longLongValue]);
    } else if ([key isKindOfClass:[RSStringPK class]]){
        pk = [key getInKey];
    }
    return [[self connector] updateWithSQL:sql, pk, nil];
}

- (id<RSPrimaryKey>)get:(id<RSPrimaryKey>)key {
    if (![[self class] defaultRowMapper] || ![[self class] primaryKeyName] || ![[self class] daoName]) {
        return [super get:key];
    }
    Class<RSRowMapper> rmClass = [[self class] defaultRowMapper];
    id <RSRowMapper> rm = [[rmClass alloc] init];
    static NSString *sqlFormat = @"select * from %@ where %@ = ?";
    NSString *sql = [NSString stringWithFormat:sqlFormat, [[self class] daoName], [[self class] primaryKeyName]];
    id pk = nil;
    if ([key isKindOfClass:[RSIntPK class]]) {
        pk = @([[key getInKey] longLongValue]);
    } else if ([key isKindOfClass:[RSStringPK class]]){
        pk = [key getInKey];
    }
    return [[self connector] queryObjectWithRowMapper:rm SQL:sql, pk, nil];
}

- (NSArray *)multiGet:(NSArray *)keys {
    if (![keys count]) {
        return @[];
    }
    if (![[self class] defaultRowMapper] || ![[self class] primaryKeyName] || ![[self class] daoName]) {
        return [super multiGet:keys];
    }
    Class<RSRowMapper> rmClass = [[self class] defaultRowMapper];
    id <RSRowMapper> rm = [[rmClass alloc] init];
    static NSString *sqlFormat = @"select * from %@ where %@ in (%@)";
    RSBaseDaoInStmt *stmt = nil;
    if ([[keys firstObject] isKindOfClass:[RSIntPK class]]) {
        stmt = [RSBaseDaoInStmt stmtWithIntPKs:keys];
    } else if ([[keys firstObject] isKindOfClass:[RSStringPK class]]) {
        stmt = [RSBaseDaoInStmt stmtWithStringPKs:keys];
    }

    
    NSString *sql = [NSString stringWithFormat:sqlFormat, [[self class] daoName], [[self class] primaryKeyName], [stmt qs]];
    return [[self connector] queryObjectsWithRowMapper:rm SQL:sql ids:[stmt ks]];
}
@end
