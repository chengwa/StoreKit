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
@end
