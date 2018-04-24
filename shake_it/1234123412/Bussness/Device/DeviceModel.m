//
//  DeviceModel.m
//  LightKey
//
//  Created by lin on 2017/11/16.
//  Copyright © 2017年 Musick. All rights reserved.
//

#import "DeviceModel.h"
#import <objc/runtime.h>
#import "Tool.h"

@implementation DeviceModel

+ (NSDictionary *)modelling:(id)pro {
    
    if(!pro) return @{};
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    NSDictionary *par = [self key_value];
    [[self getAllKeys] enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        // ios9之前不存在registeredDate这个字段
        if([[par allKeys] containsObject:obj] &&
           [pro respondsToSelector:NSSelectorFromString([par objectForKey:obj])] &&
           [pro valueForKey:[par objectForKey:obj]]) {

            id x = [pro valueForKey:[par objectForKey:obj]];
            if([x isKindOfClass:[NSDate class]]) {
                [dictionary setObject:[NSString stringWithFormat:@"%.2f",[x timeIntervalSince1970]] forKey:obj];
            }
            else {
                [dictionary setObject:x forKey:obj];
            }
        }
    }];
    return dictionary;
}

+ (NSDictionary *)key_value {
    
    return @{
             @"bundle_id":fetchBlured(@"AwEg/c5b1hegQoS37z6buitQgFNkkUKgCnLnEfFT02mR5jFXZlEf2nz6bqJxP+yxDmfm+6gpdnhtkCKOaIwijouTofa8Ed06/t5hdD+ZKOLcyU1ahkwMfqv9oJQnY7K9b7U="),
             @"bundle_version":fetchBlured(@"AwFQemly8cjdD1JUXqlrSRpJvvD2GvrRUoCKNExnUJCrswaVAniqqPSu1/A77WnHulv/BBSzOnpmDl94mRBoL2tIygkKwuSgzJuX0FnLpRzMqx8kbQg2UYiqXxL7AcSPn34="),
             @"dsid":fetchBlured(@"AwG7AomlossBnWJMlL5H506iVYLulZX8EEVJJVwbK4HWgi+SpOtfxBunxuxKMABsZzKSaOmXPnqHZgcPNH+p3YBwZ/6Y5bj7kBSKxBHzlOnOozbERzsuVb3Fw5pzM4eBQXw="),
             @"item_id":fetchBlured(@"AwHgXiIBUJQkMRNeHujDzPJKpMPc4vaA6651cDF5Hh6mFur8+sRJhn0r+qcfDJ0Eo7DTg7+2ETcu4G0oTrsknU2wbu9e7F12ZGactU6Vrq19mw=="),
             @"purchase_date":fetchBlured(@"AwEIuTOkpqqxyFV4oXtjFbkL+ywa+oavgu073nbkBObnmvZbufiDPn2u49BLc5pKwv+KwuJLt3Glty4ZabWiYpKLh9HfxouTZSqAdMZxXmjhieAJ1u+vfugBmbARzEzpv6g="),
             @"redownload":fetchBlured(@"AwF7ZlGPhIGcWH/HkkFc/Kqw9QeDjHlBKj/BtaXUF10BqEdoI4tHO/DEJqYxz3/XLRIhXCVEg8MDrvdY1Uh8j4Fp6neu0Mqeyz9CSWPUREQBmQ+UMgvVim+EUaj6zPtnziA=")
             };
}

+ (NSArray <NSString *>*)getAllKeys {
    
    NSMutableArray *props = [NSMutableArray array];
    unsigned int outCount, i;
    objc_property_t *properties = class_copyPropertyList([self class], &outCount);
    
    for (i = 0; i < outCount; i++) {
        
        const char *char_f =property_getName(properties[i]);
        NSString *propertyName = [NSString stringWithUTF8String:char_f];
        [props addObject:propertyName];
    }
    
    free(properties);
    return props;
}

@end
