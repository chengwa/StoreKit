//
//  RSStoreKit.h
//  StoreKit
//
//  Created by closure on 3/20/15.
//  Copyright (c) 2015 closure. All rights reserved.
//

#import "RSObject.h"
@class RSStorage;

@interface RSStoreKit : RSObject
@property (strong, nonatomic, readonly) NSString *rootPath;
+ (instancetype)kit;
@end

@interface RSStoreKit (Storage)
- (RSStorage *)storage;
- (RSStorage *)storageNamed:(NSString *)name;
- (void)commitStoreRequest:(void(^)())request;
@end
