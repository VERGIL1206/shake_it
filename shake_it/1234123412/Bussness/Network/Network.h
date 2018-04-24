//
//  Network.h
//  LightKey
//
//  Created by Musick on 2017/11/15.
//  Copyright © 2017年 Musick. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LKRespose.h"

typedef void(^apiRespose)(NSURLRequest *request, LKRespose *respose);

@interface Network : NSObject

@property (nonatomic, strong) NSString *host;

+ (instancetype)shared;

/**
 异步get请求
 */

- (void)AsyncGETWithHost:(NSString *)host
                    path:(NSString *)path
                  params:(NSDictionary *)params
                  header:(NSDictionary *)header
                    sign:(BOOL )sign
                   block:(apiRespose)block;

/**
 异步post请求
 */

- (void)AsyncPOSTWithHost:(NSString *)host
                    path:(NSString *)path
                  body:(NSDictionary *)body
                   header:(NSDictionary *)header
                    sign:(BOOL )sign
                   block:(apiRespose)block;



@end
