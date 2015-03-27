//
//  RSPrimaryKey.h
//  StoreKit
//
//  Created by closure on 3/20/15.
//  Copyright (c) 2015 closure. All rights reserved.
//

#import "RSObject.h"

@protocol RSPrimaryKey <NSObject, NSCoding>
- (NSString *)getInKey;
@end

@interface NSString (PK) <RSPrimaryKey>
@end

@interface NSNumber (PK) <RSPrimaryKey>
@end

typedef int64_t RSIDType;

@interface RSIntPK : RSObject<RSPrimaryKey>
@property (nonatomic, assign) RSIDType ID;
- (instancetype)initWithID:(RSIDType)ID;
- (instancetype)initWithCoder:(NSCoder *)aDecoder;
- (void)encodeWithCoder:(NSCoder *)aCoder;
- (NSUInteger)hash;
- (NSString *)getInKey;
- (BOOL)isEqual:(id)object;
@end

@interface RSStringPK : RSObject<RSPrimaryKey>
@property (nonatomic, assign) NSString *token;
- (instancetype)initWithToken:(NSString *)token;
- (instancetype)initWithCoder:(NSCoder *)aDecoder;
- (void)encodeWithCoder:(NSCoder *)aCoder;
- (NSUInteger)hash;
- (NSString *)getInKey;
- (BOOL)isEqual:(id)object;
@end
