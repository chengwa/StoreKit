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
#import "CSVParser.h"

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

- (NSString *)description {
    return [NSString stringWithFormat:@"%lld[%@], avatar[<%@>%p]", [self ID], [self name], [[self imageData] class], [self imageData]];
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
        return [key stringByDeletingPathExtension];
    });
}
@end

@interface NEUCSVMapper : RSObject
@property (strong, nonatomic, readonly) NSString *path;
@property (strong, nonatomic, readonly) NSArray *students;
- (instancetype)initWithCSVFileInPath:(NSString *)path photoSet:(NEUPhotoSet *)photoSet;
@end

@implementation NEUCSVMapper
- (instancetype)initWithCSVFileInPath:(NSString *)path photoSet:(NEUPhotoSet *)photoSet {
    if (self = [super init]) {
        _path = path;
        NSArray *info = [CSVParser parseCSVIntoArrayOfDictionariesFromFile:_path withSeparatedCharacterString:@"," quoteCharacterString:nil];
        [info writeToFile:[[path stringByDeletingPathExtension] stringByAppendingPathExtension:@"plist"] atomically:YES];
        _students = [Underscore arrayMap](info, ^NEUStudent *(NSDictionary *info) {
            RSIDType ID = [info[@"学号"] longLongValue];
            NEUStudent *stu = [[NEUStudent alloc] initWithID:ID name:info[@"姓名"] imageData:[photoSet photoDataForKey:@(ID)]];
            return stu;
        });
    }
    return self;
}
@end

@protocol RSCommandAction <NSObject>
@required
- (void)action:(id)context;
@end

@interface NEUImporter : RSObject
- (void)actoin:(id)context;
@end

@interface NEUCSVImporter : NEUImporter
- (void)actoin:(id)context;
@end

@interface ObjectDao : RSDao {
    @private
    Class _cls;
    NSMutableDictionary *_map;
}
- (instancetype)initWithConnector:(RSDatabaseConnector *)connector class:(Class)cls;
@end

#include <objc/runtime.h>

@implementation ObjectDao

- (instancetype)initWithConnector:(RSDatabaseConnector *)connector class:(Class)cls {
    if (self = [self initWithConnector:connector]) {
        _cls = cls;
        unsigned int varCount;
        
        Ivar *vars = class_copyIvarList(_cls, &varCount);
        _map = [[NSMutableDictionary alloc] init];
        
        for (int i = 0; i < varCount; i++) {
            Ivar var = vars[i];
            
            const char* name = ivar_getName(var);
            const char* typeEncoding = ivar_getTypeEncoding(var);
            _map[@(name)] = @(typeEncoding);
        }
        
        free(vars);
        
        NSInteger version = [cls version];
        NSString *className = NSStringFromClass(cls);
        NSKeyedArchiver * archiver = [[NSKeyedArchiver alloc] init];
    }
    return self;
}

@end

int main(int argc, const char * argv[]) {
    RSStoreKit *kit = [RSStoreKit kit];
    RSStorage *neuStorage = [kit storageNamed:@"NEU"];
    RSDatabaseConnector *connector = [neuStorage connectorNamed:@"neu"];
    NEUStudentDao *dao = [[NEUStudentDao alloc] initWithConnector:connector];
    NEUPhotoSet *ps = [[NEUPhotoSet alloc] initWithPath:[[NSString stringWithFormat:@"%s", argv[1]] stringByStandardizingPath]];
    NSLog(@"%@", [ps photoKeysInSet]);
    NEUCSVMapper *mapper = [[NEUCSVMapper alloc] initWithCSVFileInPath:[[NSString stringWithFormat:@"%s", argv[2]] stringByStandardizingPath] photoSet:ps];
    for (NEUStudent *stu in [mapper students]) {
        [dao add:stu];
    }
    return 0;
}