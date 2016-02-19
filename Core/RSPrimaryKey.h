//
//  RSPrimaryKey.h
//  StoreKit
//
//  Created by closure on 3/20/15.
//  Copyright (c) 2015 closure. All rights reserved.
//

#import "RSObject.h"

typedef int64_t RSIDType;

@protocol RSPrimaryKey <NSObject, NSCoding>
- (NSString *)getInKey;
- (RSIDType)numbericIDKey;
@end

@interface NSString (PK) <RSPrimaryKey>
@end

@interface NSNumber (PK) <RSPrimaryKey>
@end

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

@interface NSArray (PrimaryIDs)
- (NSString *)ids;
@end

@protocol RSJSONModel <NSObject>
@optional
- (id)jsonObject;
@end

@interface NSNumber (RSJSONModel) <RSJSONModel>
- (id)jsonObject;
@end

@interface NSString (RSJSONModel) <RSJSONModel>
- (id)jsonObject;
@end

@interface NSArray (RSJSONModel)<RSJSONModel>
- (id)jsonObject;
@end

@interface NSDictionary (RSJSONModel)<RSJSONModel>
- (id)jsonObject;
@end
