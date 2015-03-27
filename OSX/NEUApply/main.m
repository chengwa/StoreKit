//
//  main.cpp
//  NEUApply
//
//  Created by closure on 3/27/15.
//  Copyright (c) 2015 closure. All rights reserved.
//

#import "RSStoreKit.h" 
#import "RSStorage.h"
#import "RSBucket.h"
#import "RSDao.h"
#import "RSDatabaseConnector.h"
#import "FMDB.h"
#import <Underscore.m/Underscore.h>

@interface NEUStudent : RSIntPK
@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSData *imageData;
- (instancetype)initWithID:(RSIDType)ID name:(NSString *)name imageData:(NSData *)imageData;
@end

@interface NEUStudentDao : RSDao
- (BOOL)add:(NEUStudent *)obj;
- (NEUStudent *)get:(id<RSPrimaryKey>)key;
@end

@interface NEUStorage : RSStorage
- (instancetype)init;
@end

@implementation NEUStudent

- (instancetype)initWithID:(RSIDType)ID name:(NSString *)name imageData:(NSData *)imageData {
    if (self = [super initWithID:ID]) {
        _name = name;
        _imageData = imageData;
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:_name forKey:@"name"];
    [aCoder encodeObject:_imageData forKey:@"imageData"];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        _name = [aDecoder decodeObjectForKey:@"name"];
        _imageData = [aDecoder decodeObjectForKey:@"imageData"];
    }
    return self;
}
@end

@interface NEUStudentRowMapper : RSObject<RSRowMapper>
- (NEUStudent *)rowMapperWithResultSet:(FMResultSet *)resultSet;
@end

@implementation NEUStudentRowMapper

- (NEUStudent *)rowMapperWithResultSet:(FMResultSet *)resultSet {
    RSIDType ID = [resultSet longLongIntForColumnIndex:0];
    NSString *name = [resultSet stringForColumnIndex:1];
    NSData *imageData = [resultSet dataForColumnIndex:2];
    return [[NEUStudent alloc] initWithID:ID name:name imageData:imageData];
}

@end

@implementation NEUStudentDao
+ (NSString *)primaryKeyName {
    return @"id";
}

+ (NSString *)createDao {
    return [NSString stringWithFormat:@"create table %@ (id integer primary key, name text not null, imageData blob)", [self daoName]];
}

+ (NSInteger)daoVersion {
    return 1;
}

+ (NSString *)daoName {
    return @"neu_student";
}

- (BOOL)add:(NEUStudent *)obj {
    static NSString *sqlFormat = @"replace into %@ (id, name, imageData) values (?, ?, ?)";
    NSString *sql = [NSString stringWithFormat:sqlFormat, [[self class] daoName]];
    return [[self connector] updateWithSQL:sql, @([obj ID]), [obj name], [obj imageData], nil];
}

- (NEUStudent *)get:(id<RSPrimaryKey>)key {
    static NSString *sqlFormat = @"select id, name, imageData from %@ where id = ?";
    NSString *sql = [NSString stringWithFormat:sqlFormat, [[self class] daoName]];
    return [[self connector] queryObjectWithRowMapper:[NEUStudentRowMapper new] SQL:sql, @([[key getInKey] longLongValue]), nil];
}
@end

@interface NEUPhotoSet : RSObject
@property (strong, nonatomic, readonly) NSString *path;
- (instancetype)initWithPath:(NSString *)path;
- (NSData *)photoDataForKey:(id<RSPrimaryKey>)key;
@end

@implementation NEUPhotoSet
- (instancetype)initWithPath:(NSString *)path {
    if (self = [super init]) {
        _path = path;
    }
    return self;
}

- (NSData *)photoDataForKey:(id<RSPrimaryKey>)key {
    NSString *filePath = [[_path stringByAppendingPathComponent:[key getInKey]] stringByAppendingPathExtension:@"jpg"];
    return [NSData dataWithContentsOfFile:filePath];
}

- (NSArray *)photoKeysInSet {
    NSFileManager *fileMgr = [[NSFileManager alloc] init];
    NSError *error = nil;
    NSArray *keys = [fileMgr contentsOfDirectoryAtPath:_path error:&error];
    return [Underscore arrayMap](keys, ^NSString *(NSString *key){
        return [_path stringByAppendingPathComponent:[key stringByAppendingPathExtension:@"jpg"]];
    });
}
@end

@interface NEUCSVMapper : RSObject

@end

@implementation NEUCSVMapper

@end

int main(int argc, const char * argv[]) {
    RSStoreKit *kit = [RSStoreKit kit];
    RSStorage *neuStorage = [kit storageNamed:@"NEU"];
    RSDatabaseConnector *connector = [neuStorage connectorNamed:@"neu"];
    NEUStudentDao *dao = [[NEUStudentDao alloc] initWithConnector:connector];
    NEUPhotoSet *ps = [[NEUPhotoSet alloc] initWithPath:[NSString stringWithFormat:@"%s", argv[1]]];
    
    return 0;
}