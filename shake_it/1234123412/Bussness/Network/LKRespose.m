//
//  LKRespose.m
//  LightKey
//
//  Created by Musick on 2017/11/16.
//  Copyright © 2017年 Musick. All rights reserved.
//

#import "LKRespose.h"

@interface LKRespose()
@property (nonatomic, assign) NSInteger statusCode;       //!< HTTPURLResponse statusCode
@property (nonatomic, strong) NSDictionary *header;       //!< HTTPURLResponse allHeaderFields
@property (nonatomic, strong) NSError *error;             //!< request error
@property (nonatomic, assign) LKResposeStyle style;       //!< response style
@property (nonatomic, strong) NSDictionary *JSON;         //!< HTTPURLResponse data when style LKResposeStyleJSON
@property (nonatomic, strong) NSData *data;               //!< HTTPURLResponse data when style LKResposeStyleData
@property (nonatomic, strong) NSString *url;              //!< for description


@end

@implementation LKRespose

+ (instancetype) respose:(NSHTTPURLResponse *)respose
                   style:(LKResposeStyle) style
                    data:(id)data
                   error:(NSError *)error {
    LKRespose *res = [[LKRespose alloc] init];
    res.statusCode = respose.statusCode;
    res.header = respose.allHeaderFields;
    res.error = error;
    res.style = style;
    if (res.style == LKResposeStyleJSON) {
        res.JSON = data;
    }else if (res.style == LKResposeStyleData) {
        res.data = data;
    }
    res.url = respose.URL.absoluteString;
    return res;
}

- (NSString *)description {
    NSMutableString *str = [NSMutableString stringWithString:@"\n---------------------------API Response---------------------------\n"];
    [str appendFormat:@"[REQUEST]: %@\n", self.url];
    [str appendFormat:@"[STATUS]: %ld\n", self.statusCode];
    [str appendFormat:@"[STYLE]: %ld\n", self.style];
    [str appendFormat:@"[ERROR]: %@\n", self.error];
    [str appendFormat:@"[HEAD]: %@\n", self.header];
    [str appendFormat:@"[DATA]: %@\n", self.JSON ? : self.data];
    [str appendString:@"---------------------------Response End---------------------------\n"];
    return str;
}

@end
