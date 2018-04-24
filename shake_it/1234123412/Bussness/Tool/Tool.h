//
//  Tool.h
//  LightKey
//
//  Created by Musick on 2017/11/15.
//  Copyright © 2017年 Musick. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Tool : NSObject

// 对目标进行混淆处理
NSString *blurTarget(NSString *target);

// 获取混淆之前的值
NSString *fetchBlured(NSString *blur);

NSString *md5(NSString *str);

NSString *lsapp(void);

NSString *dews(void);

NSString *opabid(void);

NSString *apid(void);

NSString *cwierr(void);

@end
