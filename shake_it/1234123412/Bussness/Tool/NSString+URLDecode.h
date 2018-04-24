//
//  NSString+URLDecode.h
//  LightKey
//
//  Created by Musick on 2017/11/17.
//  Copyright © 2017年 Musick. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (URLDecode)

- (NSMutableDictionary *)paramsFromEncodedQuery;
- (NSString *)URLDecode;

@end
