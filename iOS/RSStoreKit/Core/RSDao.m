//
//  RSDao.m
//  StoreKit
//
//  Created by closure on 3/21/15.
//  Copyright (c) 2015 closure. All rights reserved.
//

#import "RSDao.h"
#import "RSVersionDao.h"

@interface RSDao (Helper)
- (NSString *)_primaryKeyName;
- (Class<RSRowMapper, NSObject>)_defaultRowMapper;
- (NSString *)_createDao;
- (NSString *)_dropDao;
- (NSInteger)_daoVersion;
- (NSString *)_daoName;
@end

@implementation RSDao
+ (BOOL)supportDynamic {
    return NO;
}

- (NSString *)_primaryKeyName {
    if ([[self class] supportDynamic]) {
        return [self primaryKeyName];
    }
    return [[self class] primaryKeyName];
}

- (Class<RSRowMapper,NSObject>)_defaultRowMapper {
    if ([[self class] supportDynamic]) {
        return [self defaultRowMapper];
    }
    return [[self class] defaultRowMapper];
}

- (NSString *)_createDao {
    if ([[self class] supportDynamic]) {
        return [self createDao];
    }
    return [[self class] createDao];
}

- (NSString *)_dropDao {
    if ([[self class] supportDynamic]) {
        return [self dropDao];
    }
    return [[self class] dropDao];
}

- (NSString *)_daoName {
    if ([[self class] supportDynamic]) {
        return [self daoName];
    }
    return [[self class] daoName];
}

- (NSInteger)_daoVersion {
    if ([[self class] supportDynamic]) {
        return [self daoVersion];
    }
    return [[self class] daoVersion];
}

- (NSString *)dropDao {
    if ([[self class] supportDynamic]) {
        return [NSString stringWithFormat:@"drop table %@", [self daoName]];
    }
    return [[self class] dropDao];
}

- (instancetype)initWithConnector:(RSDatabaseConnector *)connector {
    if (self = [super init]) {
        [self setConnector:connector];
    }
    return self;
}

- (void)setConnector:(RSDatabaseConnector *)connector {
    [super setConnector:connector];
    RSVersionDao *vd = nil;
    if (![self isKindOfClass:[RSVersionDao class]]) {
        vd = [[RSVersionDao alloc] initWithConnector:connector];
    } else {
        vd = (RSVersionDao *)self;
    }
    RSVersionInfo *vi = [vd get:[self _daoName]];
    if (vi && [vi version] < [self _daoVersion]) {
        [connector executeStatements:[self _dropDao]];
    }
    if (![connector tableIsExist:[self _daoName]]) {
        [connector executeStatements:[self _createDao]];
        [vd add:[RSVersionInfo versionWithTable:[self _daoName] version:[self _daoVersion]]];
    } else if (vi == nil) {
        [vd add:[RSVersionInfo versionWithTable:[self _daoName] version:[self _daoVersion]]];
    }
}

- (BOOL)remove:(id<RSPrimaryKey>)key {
    static NSString *sqlFormat = @"delete from %@ where %@ = ?";
    NSString *sql = [NSString stringWithFormat:sqlFormat, [self _daoName], [self _primaryKeyName] ? : @"id"];
    id pk = nil;
    if ([key isKindOfClass:[RSIntPK class]]) {
        pk = @([[key getInKey] longLongValue]);
    } else if ([key isKindOfClass:[RSStringPK class]]){
        pk = [key getInKey];
    }
    return [[self connector] updateWithSQL:sql, pk, nil];
}

- (id<RSPrimaryKey>)get:(id<RSPrimaryKey>)key {
    if (![self _defaultRowMapper] || ![self _primaryKeyName] || ![self _daoName]) {
        return [super get:key];
    }
    Class<RSRowMapper> rmClass = [self _defaultRowMapper];
    id <RSRowMapper> rm = [[rmClass alloc] init];
    static NSString *sqlFormat = @"select * from %@ where %@ = ?";
    NSString *sql = [NSString stringWithFormat:sqlFormat, [self _daoName], [self _primaryKeyName]];
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
    if (![self _defaultRowMapper] || ![self _primaryKeyName] || ![self _daoName]) {
        return [super multiGet:keys];
    }
    Class<RSRowMapper> rmClass = [self _defaultRowMapper];
    id <RSRowMapper> rm = [[rmClass alloc] init];
    static NSString *sqlFormat = @"select * from %@ where %@ in (%@)";
    RSBaseDaoInStmt *stmt = nil;
    if ([[keys firstObject] isKindOfClass:[RSIntPK class]]) {
        stmt = [RSBaseDaoInStmt stmtWithIntPKs:keys];
    } else if ([[keys firstObject] isKindOfClass:[RSStringPK class]]) {
        stmt = [RSBaseDaoInStmt stmtWithStringPKs:keys];
    }
    
    NSString *sql = [NSString stringWithFormat:sqlFormat, [self _daoName], [self _primaryKeyName], [stmt qs]];
    return [[self connector] queryObjectsWithRowMapper:rm SQL:sql ids:[stmt ks]];
}
@end
