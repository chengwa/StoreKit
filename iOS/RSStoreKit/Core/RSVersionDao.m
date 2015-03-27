//
//  RSVersionDao.m
//  StoreKit
//
//  Created by closure on 3/21/15.
//  Copyright (c) 2015 closure. All rights reserved.
//

#import "RSVersionDao.h"
#import <FMDB/FMDB.h>

@implementation RSVersionInfo
+ (instancetype)versionWithTable:(NSString *)tableName version:(NSInteger)version {
    return [self versionWithTable:tableName version:version meta:nil];
}

+ (instancetype)versionWithTable:(NSString *)tableName version:(NSInteger)version meta:(id)meta {
    return [[self alloc] initWithTable:tableName version:version meta:meta];
}

- (instancetype)initWithTable:(NSString *)token version:(NSInteger)version {
    if (self = [super initWithToken:token]) {
        _version = version;
        _meta = nil;
        _timestamp = [NSDate date];
    }
    return self;
}

- (instancetype)initWithTable:(NSString *)token version:(NSInteger)version meta:(id)meta {
    if (self = [super initWithToken:token]) {
        _version = version;
        _meta = meta;
        _timestamp = [NSDate date];
    }
    return self;
}
@end

@interface RSVersionInfoRowMapper : RSObject<RSRowMapper>
- (RSVersionInfo *)rowMapperWithResultSet:(FMResultSet *)resultSet;
@end

@implementation RSVersionInfoRowMapper
- (RSVersionInfo *)rowMapperWithResultSet:(FMResultSet *)resultSet {
    RSVersionInfo *info = [[RSVersionInfo alloc] initWithTable:[resultSet stringForColumnIndex:0] version:[resultSet longForColumnIndex:1] meta:[resultSet stringForColumnIndex:3]];
    [info setTimestamp:[resultSet dateForColumnIndex:2]];
    return info;
}
@end

@implementation RSVersionDao

- (BOOL)add:(RSVersionInfo *)obj {
    static NSString *sql = @"replace into version_info (table_name, version, timestamp, meta) values (?, ?, ?, ?)";
    return [[self connector] updateWithSQL:sql, [obj getInKey], @([obj version]), [obj timestamp], [[obj meta] description]? : @""];
}

- (BOOL)update:(RSVersionInfo *)obj {
    static NSString *sql = @"update version_info set version = ?, meta = ? where table_name = ?";
    return [[self connector] updateWithSQL:sql, @([obj version]), [[obj meta] description], [obj getInKey]];
}

- (BOOL)remove:(id<RSPrimaryKey>)key {
    static NSString * sql = @"delete from version_info where table_name = ?";
    return [[self connector] updateWithSQL:sql, key];
}

- (RSVersionInfo *)get:(NSString *)tableName {
    return [[self connector] queryObjectWithRowMapper:[RSVersionInfoRowMapper new] SQL:@"select * from version_info where table_name = ?", tableName];;
}

+ (NSString *)createDao {
    return @"CREATE TABLE \"version_info\" ("
    "\"table_name\" TEXT primary key,"
    "\"version\" integer,"
    "\"timestamp\" timestamp not null default current_timestamp,"
    "\"meta\" TEXT"
    ");"
    "CREATE INDEX version_info_table_name_index on version_info (table_name);";
}

+ (NSString *)daoName {
    return @"version_info";
}
@end

