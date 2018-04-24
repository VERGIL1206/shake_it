//
//  NSString+URLDecode.m
//  LightKey
//
//  Created by Musick on 2017/11/17.
//  Copyright © 2017年 Musick. All rights reserved.
//

#import "NSString+URLDecode.h"

@implementation NSString (URLDecode)

- (NSMutableDictionary *)paramsFromEncodedQuery
{
    NSArray *param = [self componentsSeparatedByString:@"&"];
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    for (NSString *p in param) {
        NSArray *kv = [p componentsSeparatedByString:@"="];
        if ([kv count] == 2) {
//            dic[kv[0]] = [kv[1] URLDecode];
            dic[kv[0]] = kv[1];
        }
    }
    
    return dic;
}

- (NSString *)URLDecode {
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED < __IPHONE_9_0
    NSString *decodedString =
    (__bridge_transfer NSString *)CFURLCreateStringByReplacingPercentEscapesUsingEncoding(NULL,
                                                                                          (__bridge CFStringRef)self,
                                                                                          CFSTR(""),
                                                                                          CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));
#else
    NSString *decodedString = (__bridge NSString *)CFURLCreateStringByReplacingPercentEscapes(nil, (__bridge CFStringRef)self, CFSTR(""));
#endif
    
    return decodedString;
}

@end
