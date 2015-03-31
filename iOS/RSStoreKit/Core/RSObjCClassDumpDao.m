//
//  RSObjCClassDumpDao.m
//  FITogether
//
//  Created by closure on 3/30/15.
//  Copyright (c) 2015 closure. All rights reserved.
//

#import "RSObjCClassDumpDao.h"
#import <FMDB/FMDB.h>
#import <objc/runtime.h> 
#import "RSStoreKit.h"
#import "RSStorage.h"

@interface __RSObjcClassDumpImpl : RSObject
+ (NSDictionary *)dictWithClass:(Class)cls;
@end

@implementation __RSObjcClassDumpImpl

+ (NSDictionary *)dictWithClass:(Class)cls {
    if (!cls) {
        return @{};
    }
    unsigned int count = 0;
    Method *methods = class_copyMethodList(cls, &count);
    NSMutableDictionary *rst = [[NSMutableDictionary alloc] initWithCapacity:count];
    if (methods) {
        for (unsigned int i = 0; i < count; ++i) {
            Method method = methods[i];
            SEL sel = method_getName(method);
            const char *type = method_getTypeEncoding(method);
            rst[NSStringFromSelector(sel)] = @(type);
        }
        free(methods);
    }
    return rst;
}

@end

@interface RSObjCClassDumpDao () {
    @private
    NSString *_daoName;
}
@end

@interface RSObjCClassDumpRowMapper : RSObject<RSRowMapper>
- (NSDictionary *)rowMapperWithResultSet:(FMResultSet *)resultSet;
@end

@implementation RSObjCClassDumpRowMapper

- (NSDictionary *)rowMapperWithResultSet:(FMResultSet *)resultSet {
    return [resultSet resultDictionary];
}

@end

@implementation RSObjCClassDumpDao
+ (void)dumpAction:(void(^)())complete {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"------------------------------ iOS.RuntimeClass start -----------------------------------");
        RSStorage *storage = [[RSStoreKit kit] storageNamed:@"iOS.RuntimeClass"];
        RSDatabaseConnector *dbc = [storage connectorNamed:@"iOS.RuntimeClass"];
        unsigned int cc = 0;
        Class *classes = objc_copyClassList(&cc);
        for (unsigned int i = 0; i < cc; ++i) {
            @autoreleasepool {
                RSObjCClassDumpDao *d __unused = [[RSObjCClassDumpDao alloc] initWithConnector:dbc class:classes[i]];
            }
        }
        free(classes);
        NSLog(@"----------------------------- iOS.RuntimeClass finished ---------------------------------");
    });
}

- (instancetype)initWithConnector:(RSDatabaseConnector *)connector class:(Class)cls {
    if (self = [super init]) {
        [self setClass:cls];
        [self setConnector:connector];
        id dict = [__RSObjcClassDumpImpl dictWithClass:_cls];
        [self add:dict];
    }
    return self;
}

- (BOOL)add:(NSDictionary *)obj {
    static NSString *sqlFormat = @"replace into %@ (key, value) values(?, ?)";
    NSString *sql = [NSString stringWithFormat:sqlFormat, [self daoName]];
    for (NSString *key in obj) {
        [[self connector] updateWithSQL:sql, key, obj[key], nil];
    }
    return YES;
}

- (void)setClass:(Class)cls {
    _cls = cls;
    _daoName = NSStringFromClass(_cls);
}

+ (BOOL)supportDynamic {
    return YES;
}

- (NSString *)daoName {
    assert(_daoName && "should setClass: first");
    return _daoName;
}

- (NSString *)createDao {
    return [NSString stringWithFormat:@"create table %@ (%@ integer primary key autoincrement, key TEXT not null, value TEXT not null)", [self daoName], [self primaryKeyName]];
}

- (NSInteger)daoVersion {
    return 1;
}

@end
