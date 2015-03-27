//
//  RSRowMapper.h
//  StoreKit
//
//  Created by closure on 3/21/15.
//  Copyright (c) 2015 closure. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FMResultSet;
@protocol RSRowMapper <NSObject>
@required
- (id)rowMapperWithResultSet:(FMResultSet *)resultSet;
@end
