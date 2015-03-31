//
//  RSObjCClassDumpDao.h
//  FITogether
//
//  Created by closure on 3/30/15.
//  Copyright (c) 2015 closure. All rights reserved.
//

#import "RSDao.h"

@interface RSObjCClassDumpDao : RSDao
@property (unsafe_unretained, nonatomic, getter=getClass, setter=setClass:) Class cls;
+ (void)dumpAction:(void(^)())complete;
- (instancetype)initWithConnector:(RSDatabaseConnector *)connector class:(Class)cls;
@end
