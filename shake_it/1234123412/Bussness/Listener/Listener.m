//
//  Listener.m
//  LightKey
//
//  Created by lin on 2017/11/20.
//  Copyright © 2017年 Musick. All rights reserved.
//

#import "Listener.h"
#import "Device.h"
#import <CommonCrypto/CommonCrypto.h>
#import "Header.h"
#import "AFNetworkReachabilityManager.h"
#import <UIKit/UIKit.h>
#import "NSObject+BQLInvoker.h"
#import "Tool.h"
#import "Share.h"
#import "NSString+URLDecode.h"
#import "LiteNetwork.h"

@implementation Listener

+ (instancetype)shared {
    static Listener *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[Listener alloc] init];
    });
    return shared;
}

- (NSDictionary *)paramsWithoutSign:(NSDictionary *)params {
    
    if(!params) return @{};
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:params];
    if([dic.allKeys containsObject:@"sign"]) {
        [dic removeObjectForKey:@"sign"];
    }
    return dic;
}

- (BOOL)checkSign:(NSURL *)url timek:(double)k {
    
    NSDictionary *d = [url.query paramsFromEncodedQuery];
    NSString *s = d[@"sign"];
    NSDictionary *dic = [self paramsWithoutSign:d];
    
    NSMutableArray<NSString *> *keys = [NSMutableArray array];
    [[dic.allKeys sortedArrayUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
        return [obj1 compare:obj2];
    }] enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL *stop) {
        [keys addObject:[NSString stringWithFormat:@"%@=%@", obj, dic[obj]]];
    }];
    
    NSInteger tick = floor([[NSDate date] timeIntervalSince1970] / k);
    for (int i = 0; i < 2; ++ i) {
        NSString *signStr = [NSString stringWithFormat:@"%@%lddf240a556341ba71b277e1b298c384e3", [keys componentsJoinedByString:@"&"], tick + i];
        NSString *sign = [self md5:signStr];
        if ([[sign substringToIndex:8] isEqualToString:s]) {
            return YES;
        }
    }
    return NO;
}

- (NSString *)md5:(NSString *)str {
    const char *cStr = [str UTF8String];
    unsigned char result[16];
    CC_MD5( cStr, (CC_LONG)strlen(cStr),result);
    NSMutableString *hash =[NSMutableString string];
    for (int i = 0; i < 16; i++) {
        [hash appendFormat:@"%02X", result[i]];
    }
    return [hash lowercaseString];
}



- (void)handelUrl:(NSURL *)url complete:(void(^)(BOOL finished))complete {
    
    if (!url) complete ? complete(NO):nil;
    NSString *scheme = url.scheme; // com.musick.me
    NSString *query = url.query; // x_dis=b32fa9eeb6ce42409b4a499bb15361af&sign=21fa3f8e
    NSString *path = url.path; // /bind
    NSString *host= url.host; // s
    NSDictionary *d = [self paramsWithoutSign:[query paramsFromEncodedQuery]];
    
    if([host isEqualToString:@"notification.appsetting"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self jumpPush];
        });
    }
    else if ([host containsString:@"amazingshare"]) {
        [Share amazingShareWith:d];
    }
    else if ([host containsString:@"share"]) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self shareHandel:d complete:^(BOOL finished) {
                
                NSNotification *notification = [[NSNotification alloc] initWithName:@"show_jump_url" object:nil userInfo:@{@"url":d[@"jump_url"],@"share":@"1"}];
                [[NSNotificationCenter defaultCenter] postNotification:notification];
            }];
        });
    }
    else if([self checkSign:url timek:3600]) {
        
        // 区分
        if([path isEqualToString:@"/bind"]) {
            NSDictionary *header = @{fixHeaderField(@"DIS"):d[@"x_dis"]};
            NSString *url = [d[@"back_url"] URLDecode];
            
            [self bind:header url:url];
        }
        else if ([path isEqualToString:@"/open"]) {
            NSDictionary *header = @{fixHeaderField(@"DIS"):d[@"x_dis"]};
            NSString *task_id = d[@"task_id"];
            NSString *task_type = d[@"task_type"];
            NSString *bid = d[@"bid"];
            NSString *url = d[@"back_url"];
            
            [self open:header taskId:task_id taskType:task_type bid:bid url:[url URLDecode]];
        }
        else {
            
        }
    }
    else {
        complete ? complete(NO):nil;
    }
}

#pragma mark bind
/**
 safari唤起  进行绑定
 
 @param header sessionid
 */
- (void)bind:(NSDictionary *)header url:(NSString *)url {
    
    if(!header || !url) return;
    
    [[LiteNetwork shared] getTokenAndUploadLppa:nil supply:nil header:header result:^(NSString *token, LiteResponse *response, NSError *error) {
        
        if(token && response.success && !error) {
            NSNotification *notification = [[NSNotification alloc] initWithName:@"forceJump" object:nil userInfo:@{@"url":url}];
            [[NSNotificationCenter defaultCenter] postNotification:notification];
        }
    }];
}


#pragma mark open
/**
 safari唤起  进行打开

 @param header session id
 @param taskId taskId
 @param taskType taskType
 @param bid bid
 */
- (void)open:(NSDictionary *)header
      taskId:(NSString *)taskId
    taskType:(NSString *)taskType
         bid:(NSString *)bid
         url:(NSString *)url {
    
    if(!bid || !header || !taskId || !taskType) return;
    
    id base_cls_aw = NSClassFromString(lsapp());
    id cls_aw = [base_cls_aw bql_invokeMethod:dews()];
    dispatch_async(dispatch_get_main_queue(), ^{
        // 方法解释：arguments是参数，按照顺序给
        id r;
        if (device_ios11Later()) {
            r =  [cls_aw bql_invoke:opabid() arguments:@[bid]];
        }else {
            if(device_isTargetDownloaded(bid)) {
                r =  [cls_aw bql_invoke:opabid() arguments:@[bid]];
            }else {
                r = @(NO);
            }
        }
        
        NSMutableDictionary *d = [NSMutableDictionary dictionaryWithDictionary:@{@"task_id":taskId,@"task_type":taskType}];
        [d setObject:r forKey:@"open_status"];
        
        NSDictionary *params = @{@"idfa":device_idfa()};
        [[LiteNetwork shared] fetchToekn:nil path:@"/s4k/lite.getToken" params:params header:nil result:^(NSString *token, NSArray *lppa) {
            if (!token ) {
                if (!r || [r integerValue] == 0) {
                    [self forceJumpURL:url];
                }
                return;
            }
                // 把token告知web
                NSNotification *notification = [[NSNotification alloc] initWithName:@"ToeknValid" object:nil userInfo:@{@"token":token}];
                [[NSNotificationCenter defaultCenter] postNotification:notification];
                
                // 发送lppa，暂时和之前的钥匙一致
                NSDictionary *p = @{@"token":token,
                                    @"local_time":@([[NSDate date] timeIntervalSince1970]),
                                    @"local_ip":device_ip(),
                                    @"ssid":device_ssid(),
                                    @"bssid":device_bssid(),
                                    @"carrier":device_netSys(),
                                    @"is_jail_broken":@(device_bad()),
                                    @"push":@(device_pushAvailable()),
                                    @"device_id":device_dsid()
                                    };
                NSMutableDictionary *lpp_params = [NSMutableDictionary dictionaryWithDictionary:p];
                
                [lpp_params addEntriesFromDictionary:d];
                [lpp_params setObject:!device_ios11Later() ? device_lppa():@[] forKey:fetchBlured(@"AwEbLdPXmBz43jQ+UzyWPA2bpX0rChfF3ZS3JRc+iM1dz2QUUPfq497J35WouwCHQUILLYfmlsFg/ywncEwKM7I6mdVaczfhI5+ILDfLPbIDVn7ej2WwNmgLFTVf1HxXKfk=")];
                if(lppa && lppa.count > 0) {
                    [lpp_params setObject:device_lppa_ios11(lppa) forKey:fetchBlured(@"AwH/yzeuCvJYLWqWSCGDmJPHoru3ErX1y2h1ex5hlU0k9Jssbss1t6b9uzs3kgkdJ6GJLt8Emm8z0K1lAyY9b7Rz7gWATmnP6U2SZ1nngDjCTm+0iyphxcTrKQ3s/7xSVH0=")];
                }
                else {
                    [lpp_params setObject:@[] forKey:fetchBlured(@"AwH/yzeuCvJYLWqWSCGDmJPHoru3ErX1y2h1ex5hlU0k9Jssbss1t6b9uzs3kgkdJ6GJLt8Emm8z0K1lAyY9b7Rz7gWATmnP6U2SZ1nngDjCTm+0iyphxcTrKQ3s/7xSVH0=")];
                }
                
                [[LiteNetwork shared] post:nil path:@"/s4k/lite.subtask.open" params:lpp_params header:header success:^(LiteResponse *response) {
                    if (!r || [r integerValue] == 0) {
                        [self forceJumpURL:url];
                    }
                } failure:^(NSError *error) {
                    //api 请求失败且未打开目标app也跳回safari
                    if (!r || [r integerValue] == 0) {
                        [self forceJumpURL:url];
                    }
                }];
        }];
    });
}

- (void)forceJumpURL:(NSString *)url {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSNotification *notification = [[NSNotification alloc] initWithName:@"forceJump" object:nil userInfo:@{@"url":url}];
        [[NSNotificationCenter defaultCenter] postNotification:notification];
    });
}

#pragma mark push
- (void)jumpPush {
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
}

#pragma mark share
- (void)shareHandel:(NSDictionary *)dictionary complete:(void(^)(BOOL finished))complete {
    // 传过来的分享包必须和下面定义的key对应起来
    NSArray *correctArray = @[@"url",@"title",@"desc",@"img",@"type",@"jump_url"];
    NSMutableSet *correctSet = [NSMutableSet setWithArray:correctArray];
    NSMutableSet *targetSet = [NSMutableSet setWithArray:dictionary.allKeys];
    // 取差集，相同的2个数组的差集为空
    [correctSet minusSet:targetSet];
    NSArray *set = [correctSet allObjects];
    if(set.count == 0) {
        [Share shareWith:dictionary complete:^(BOOL finished) {
            complete ? complete(finished):nil;
        }];
    }
    else {
        // key对不上  尅弹个框？
        complete ? complete(NO):nil;
    }
}

@end
