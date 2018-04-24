//
//  LKRespose.h
//  LightKey
//
//  Created by Musick on 2017/11/16.
//  Copyright © 2017年 Musick. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, LKResposeStyle) {
    LKResposeStyleJSON,                                     //!< HTTPURLResponse返回的data是json数据类型
    LKResposeStyleData                                      //!< HTTPURLResponse返回的data是data的数据流
};

@interface LKRespose : NSObject

@property (nonatomic, readonly) NSInteger statusCode;       //!< HTTPURLResponse statusCode
@property (nonatomic, readonly) NSDictionary *header;       //!< HTTPURLResponse allHeaderFields
@property (nonatomic, readonly) NSError *error;             //!< request error
@property (nonatomic, readonly) LKResposeStyle style;       //!< response style
@property (nonatomic, readonly) NSDictionary *JSON;         //!< HTTPURLResponse data when style LKResposeStyleJSON
@property (nonatomic, readonly) NSData *data;               //!< HTTPURLResponse data when style LKResposeStyleData

+ (instancetype) respose:(NSHTTPURLResponse *)respose
                   style:(LKResposeStyle) style
                    data:(id)data
                   error:(NSError *)error;

@end
